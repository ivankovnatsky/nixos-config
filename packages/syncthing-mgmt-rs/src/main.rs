use reqwest::blocking::Client;
use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::error::Error;
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const USER_AGENT: &str = "syncthing-mgmt-rs/1.0.0";

type Result<T> = std::result::Result<T, Box<dyn Error + Send + Sync>>;

#[derive(Debug, Deserialize)]
struct SystemStatus {
    #[serde(rename = "myID")]
    my_id: String,
    version: Option<String>,
    os: Option<String>,
    arch: Option<String>,
    uptime: Option<i64>,
    #[serde(rename = "connectionServiceStatus")]
    connection_service_status: Option<HashMap<String, ServiceStatus>>,
    #[serde(rename = "discoveryStatus")]
    discovery_status: Option<HashMap<String, ServiceStatus>>,
}

#[derive(Debug, Deserialize)]
struct ServiceStatus {
    error: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Device {
    #[serde(rename = "deviceID")]
    device_id: String,
    name: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Folder {
    id: String,
    label: Option<String>,
    path: Option<String>,
    devices: Option<Vec<FolderDevice>>,
}

#[derive(Debug, Deserialize)]
struct FolderDevice {
    #[serde(rename = "deviceID")]
    device_id: String,
}

#[derive(Debug, Deserialize)]
struct Connections {
    total: Option<ConnectionTotal>,
    connections: Option<HashMap<String, ConnectionInfo>>,
}

#[derive(Debug, Deserialize)]
struct ConnectionTotal {
    #[serde(rename = "inBytesTotal")]
    in_bytes_total: Option<i64>,
    #[serde(rename = "outBytesTotal")]
    out_bytes_total: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct ConnectionInfo {
    connected: Option<bool>,
    paused: Option<bool>,
}

#[derive(Debug, Deserialize)]
struct Completion {
    completion: Option<f64>,
    #[serde(rename = "needBytes")]
    need_bytes: Option<i64>,
    #[serde(rename = "needItems")]
    need_items: Option<i32>,
}

struct SyncthingClient {
    base_url: String,
    api_key: String,
    client: Client,
}

impl SyncthingClient {
    fn new(base_url: &str, api_key: &str) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            api_key: api_key.to_string(),
            client: Client::builder()
                .timeout(Duration::from_secs(30))
                .build()
                .unwrap(),
        }
    }

    fn get<T: for<'de> Deserialize<'de>>(&self, endpoint: &str) -> Result<T> {
        let url = format!("{}{}", self.base_url, endpoint);
        let resp = self
            .client
            .get(&url)
            .header("User-Agent", USER_AGENT)
            .header("X-API-Key", &self.api_key)
            .send()?;

        if !resp.status().is_success() {
            return Err(format!("API error: status {}", resp.status()).into());
        }

        Ok(resp.json()?)
    }

    fn get_system_status(&self) -> Result<SystemStatus> {
        self.get("/rest/system/status")
    }

    fn get_devices(&self) -> Result<Vec<Device>> {
        self.get("/rest/config/devices")
    }

    fn get_folders(&self) -> Result<Vec<Folder>> {
        self.get("/rest/config/folders")
    }

    fn get_connections(&self) -> Result<Connections> {
        self.get("/rest/system/connections")
    }

    fn get_completion(&self, device_id: &str, folder_id: Option<&str>) -> Result<Completion> {
        let mut endpoint = format!("/rest/db/completion?device={}", device_id);
        if let Some(fid) = folder_id {
            endpoint.push_str(&format!("&folder={}", fid));
        }
        self.get(&endpoint)
    }
}

fn get_api_key_from_config(config_path: &str) -> Result<String> {
    let content = fs::read_to_string(config_path)?;
    // Simple XML parsing - find <apikey>...</apikey>
    if let Some(start) = content.find("<apikey>") {
        if let Some(end) = content[start..].find("</apikey>") {
            let key = &content[start + 8..start + end];
            return Ok(key.to_string());
        }
    }
    Err("API key not found in config.xml".into())
}

fn find_listening_address(port: u16) -> Option<String> {
    if cfg!(target_os = "macos") {
        let output = Command::new("lsof")
            .args(["-i", &format!(":{}", port), "-sTCP:LISTEN", "-n", "-P"])
            .output()
            .ok()?;

        if output.status.success() {
            let stdout = String::from_utf8_lossy(&output.stdout);
            for line in stdout.lines().skip(1) {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 9 {
                    for part in parts.iter().rev() {
                        if part.contains(':') && !part.starts_with('(') {
                            let addr = part.split(':').next()?;
                            return Some(if addr == "*" { "0.0.0.0" } else { addr }.to_string());
                        }
                    }
                }
            }
        }
    } else {
        let output = Command::new("ss")
            .args(["-tlnH", "sport", "=", &format!(":{}", port)])
            .output()
            .ok()?;

        if output.status.success() {
            let stdout = String::from_utf8_lossy(&output.stdout);
            for line in stdout.lines() {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 4 {
                    if let Some(idx) = parts[3].rfind(':') {
                        let addr = &parts[3][..idx];
                        return Some(
                            if addr == "*" || addr == "0.0.0.0" || addr == "::" {
                                "0.0.0.0"
                            } else {
                                addr
                            }
                            .to_string(),
                        );
                    }
                }
            }
        }
    }
    None
}

fn find_config_xml() -> Option<String> {
    let home = env::var("HOME").ok()?;
    let paths = [
        format!("{}/.local/state/syncthing/config.xml", home),
        format!("{}/.config/syncthing/config.xml", home),
        "/var/lib/syncthing/.config/syncthing/config.xml".to_string(),
        format!("{}/Library/Application Support/Syncthing/config.xml", home),
    ];

    for path in paths {
        if PathBuf::from(&path).exists() {
            return Some(path);
        }
    }
    None
}

fn format_bytes(bytes: i64) -> String {
    if bytes == 0 {
        return "0 B".to_string();
    }

    let units = ["B", "KB", "MB", "GB", "TB"];
    let mut size = bytes as f64;
    let mut unit_idx = 0;

    while size >= 1024.0 && unit_idx < units.len() - 1 {
        size /= 1024.0;
        unit_idx += 1;
    }

    if size < 10.0 {
        format!("{:.2} {}", size, units[unit_idx])
    } else {
        format!("{:.1} {}", size, units[unit_idx])
    }
}

fn format_uptime(seconds: i64) -> String {
    let days = seconds / 86400;
    let hours = (seconds % 86400) / 3600;
    let minutes = (seconds % 3600) / 60;
    format!("{}d {}h {}m", days, hours, minutes)
}

fn display_folders(
    folders: &[Folder],
    devices: &[Device],
    local_device_id: &str,
    client: &Arc<SyncthingClient>,
) {
    println!("\x1b[1;36mFolders\x1b[0m");

    if folders.is_empty() {
        println!("  (none)");
        return;
    }

    // Build device map
    let device_map: HashMap<&str, &str> = devices
        .iter()
        .map(|d| (d.device_id.as_str(), d.name.as_deref().unwrap_or("Unknown")))
        .collect();

    // Collect completion tasks
    let mut tasks: Vec<(String, String)> = Vec::new();
    for folder in folders {
        if let Some(devs) = &folder.devices {
            for d in devs {
                if d.device_id != local_device_id {
                    tasks.push((d.device_id.clone(), folder.id.clone()));
                }
            }
        }
    }

    // Fetch completions in parallel
    let completions: Arc<Mutex<HashMap<String, Completion>>> = Arc::new(Mutex::new(HashMap::new()));
    let mut handles = vec![];

    for (device_id, folder_id) in tasks {
        let client = Arc::clone(client);
        let completions = Arc::clone(&completions);
        let key = format!("{}:{}", device_id, folder_id);

        handles.push(thread::spawn(move || {
            if let Ok(comp) = client.get_completion(&device_id, Some(&folder_id)) {
                completions.lock().unwrap().insert(key, comp);
            }
        }));
    }

    for handle in handles {
        let _ = handle.join();
    }

    let completions = completions.lock().unwrap();

    // Display folders
    for (i, folder) in folders.iter().enumerate() {
        if i > 0 {
            println!();
        }
        let label = folder.label.as_deref().unwrap_or(&folder.id);
        println!("  \x1b[1m{}\x1b[0m", label);
        println!("  \x1b[2m{}\x1b[0m", folder.path.as_deref().unwrap_or(""));

        if let Some(devs) = &folder.devices {
            for d in devs {
                if d.device_id == local_device_id {
                    continue;
                }
                let name = device_map
                    .get(d.device_id.as_str())
                    .unwrap_or(&"Unknown");

                let key = format!("{}:{}", d.device_id, folder.id);
                let status = if let Some(comp) = completions.get(&key) {
                    let need_items = comp.need_items.unwrap_or(0);
                    if need_items > 0 {
                        format!(
                            "\x1b[31mOut of Sync:\x1b[0m {} items, ~{}",
                            need_items,
                            format_bytes(comp.need_bytes.unwrap_or(0))
                        )
                    } else {
                        "\x1b[32mUp to Date\x1b[0m".to_string()
                    }
                } else {
                    String::new()
                };

                println!("    \x1b[33m{}\x1b[0m  {}", name, status);
            }
        }
    }
}

fn display_this_device(status: &SystemStatus, conns: Option<&Connections>) {
    println!();
    println!("\x1b[1;36mThis Device\x1b[0m");

    if let Some(c) = conns {
        if let Some(total) = &c.total {
            println!("  Download: {} total", format_bytes(total.in_bytes_total.unwrap_or(0)));
            println!("  Upload: {} total", format_bytes(total.out_bytes_total.unwrap_or(0)));
        }
    }

    if let Some(css) = &status.connection_service_status {
        let active = css.values().filter(|s| s.error.is_none()).count();
        println!("  Listeners: {}/{}", active, css.len());
    }

    if let Some(ds) = &status.discovery_status {
        let active = ds.values().filter(|s| s.error.is_none()).count();
        println!("  Discovery: {}/{}", active, ds.len());
    }

    if let Some(uptime) = status.uptime {
        println!("  Uptime: {}", format_uptime(uptime));
    }

    println!("  ID: {}", &status.my_id[..7.min(status.my_id.len())]);

    if let (Some(ver), Some(os), Some(arch)) = (&status.version, &status.os, &status.arch) {
        println!("  Version: {}, {} ({})", ver, os, arch);
    }
}

fn display_devices(
    devices: &[Device],
    local_device_id: &str,
    conns: Option<&Connections>,
    client: &Arc<SyncthingClient>,
) {
    println!();
    println!("\x1b[1;36mRemote Devices\x1b[0m");

    let remote_devices: Vec<&Device> = devices
        .iter()
        .filter(|d| d.device_id != local_device_id)
        .collect();

    if remote_devices.is_empty() {
        println!("  (none)");
        return;
    }

    // Fetch completions for connected devices
    let completions: Arc<Mutex<HashMap<String, Completion>>> = Arc::new(Mutex::new(HashMap::new()));
    let mut handles = vec![];

    if let Some(c) = conns {
        if let Some(conn_map) = &c.connections {
            for device in &remote_devices {
                if let Some(conn) = conn_map.get(&device.device_id) {
                    if conn.connected.unwrap_or(false) {
                        let client = Arc::clone(client);
                        let completions = Arc::clone(&completions);
                        let device_id = device.device_id.clone();

                        handles.push(thread::spawn(move || {
                            if let Ok(comp) = client.get_completion(&device_id, None) {
                                completions.lock().unwrap().insert(device_id, comp);
                            }
                        }));
                    }
                }
            }
        }
    }

    for handle in handles {
        let _ = handle.join();
    }

    let completions = completions.lock().unwrap();

    // Display devices
    for device in remote_devices {
        let name = device.name.as_deref().unwrap_or("Unknown");
        let short_id = &device.device_id[..7.min(device.device_id.len())];

        let (conn_status, sync_status) = if let Some(c) = conns {
            if let Some(conn_map) = &c.connections {
                if let Some(conn) = conn_map.get(&device.device_id) {
                    if conn.paused.unwrap_or(false) {
                        ("\x1b[33mPaused\x1b[0m", String::new())
                    } else if conn.connected.unwrap_or(false) {
                        let sync = if let Some(comp) = completions.get(&device.device_id) {
                            let completion = comp.completion.unwrap_or(100.0);
                            if completion < 100.0 {
                                format!(
                                    "Syncing {:.0}%, {}",
                                    completion,
                                    format_bytes(comp.need_bytes.unwrap_or(0))
                                )
                            } else {
                                "\x1b[32mUp to Date\x1b[0m".to_string()
                            }
                        } else {
                            String::new()
                        };
                        ("\x1b[32mConnected\x1b[0m", sync)
                    } else {
                        ("\x1b[31mDisconnected\x1b[0m", String::new())
                    }
                } else {
                    ("\x1b[2mUnknown\x1b[0m", String::new())
                }
            } else {
                ("\x1b[2mUnknown\x1b[0m", String::new())
            }
        } else {
            ("\x1b[2mUnknown\x1b[0m", String::new())
        };

        println!(
            "  \x1b[1;33m{}\x1b[0m ({}...)  {}  {}",
            name, short_id, conn_status, sync_status
        );
    }
}

fn main() {
    // Find config.xml
    let config_path = match find_config_xml() {
        Some(p) => p,
        None => {
            eprintln!("Error: Could not find Syncthing config.xml");
            std::process::exit(1);
        }
    };

    // Get API key
    let api_key = match get_api_key_from_config(&config_path) {
        Ok(k) => k,
        Err(e) => {
            eprintln!("Error reading API key: {}", e);
            std::process::exit(1);
        }
    };

    // Detect listening address
    let base_url = if let Some(addr) = find_listening_address(8384) {
        let addr = if addr == "0.0.0.0" { "127.0.0.1" } else { &addr };
        format!("http://{}:8384", addr)
    } else {
        "http://127.0.0.1:8384".to_string()
    };

    let client = Arc::new(SyncthingClient::new(&base_url, &api_key));

    // Fetch initial data in parallel
    let client1 = Arc::clone(&client);
    let client2 = Arc::clone(&client);
    let client3 = Arc::clone(&client);
    let client4 = Arc::clone(&client);

    let status_handle = thread::spawn(move || client1.get_system_status());
    let devices_handle = thread::spawn(move || client2.get_devices());
    let folders_handle = thread::spawn(move || client3.get_folders());
    let conns_handle = thread::spawn(move || client4.get_connections());

    let status = match status_handle.join().unwrap() {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Error getting status: {}", e);
            std::process::exit(1);
        }
    };

    let devices = match devices_handle.join().unwrap() {
        Ok(d) => d,
        Err(e) => {
            eprintln!("Error getting devices: {}", e);
            std::process::exit(1);
        }
    };

    let folders = match folders_handle.join().unwrap() {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Error getting folders: {}", e);
            std::process::exit(1);
        }
    };

    let conns = conns_handle.join().unwrap().ok();

    let local_device_id = &status.my_id;

    // Display
    display_folders(&folders, &devices, local_device_id, &client);
    display_this_device(&status, conns.as_ref());
    display_devices(&devices, local_device_id, conns.as_ref(), &client);
}
