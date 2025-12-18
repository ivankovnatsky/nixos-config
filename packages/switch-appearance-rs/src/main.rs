use std::env;
use std::fs;
use std::io;
use std::path::PathBuf;
use std::process::{Command, Stdio};

fn is_macos() -> bool {
    cfg!(target_os = "macos")
}

fn is_kde() -> bool {
    // Check environment variables first
    if let Ok(desktop) = env::var("XDG_CURRENT_DESKTOP") {
        if desktop.contains("KDE") || desktop.contains("Plasma") {
            return true;
        }
    }

    // Fallback: check if plasmashell is running
    Command::new("pgrep")
        .arg("plasmashell")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

// macOS Functions

fn get_current_theme_macos() -> io::Result<bool> {
    let output = Command::new("osascript")
        .arg("-e")
        .arg("tell application \"System Events\" to tell appearance preferences to get dark mode")
        .output()?;
    Ok(String::from_utf8_lossy(&output.stdout).trim() == "true")
}

fn set_dark_mode_macos(dark: bool) -> io::Result<()> {
    let mode = if dark { "true" } else { "false" };
    Command::new("osascript")
        .arg("-e")
        .arg(format!(
            "tell application \"System Events\" to tell appearance preferences to set dark mode to {}",
            mode
        ))
        .status()?;
    Ok(())
}

fn set_wallpaper_macos(color: &str) -> io::Result<()> {
    let file_path = format!("/System/Library/Desktop Pictures/Solid Colors/{}.png", color);
    let script = format!(
        r#"
tell application "System Events"
    tell every desktop
        set picture to "{}"
    end tell
end tell
"#,
        file_path
    );
    Command::new("osascript").arg("-e").arg(&script).status()?;
    Ok(())
}

fn open_settings_macos() -> io::Result<()> {
    let script = r#"
tell application "System Settings"
    activate
    delay 0.5
    tell application "System Events"
        tell process "System Settings"
            click menu item "Wallpaper" of menu "View" of menu bar 1
        end tell
    end tell
end tell
"#;
    Command::new("osascript")
        .arg("-e")
        .arg(script)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()?;
    Ok(())
}

// KDE Plasma Functions

fn get_current_theme_kde() -> io::Result<bool> {
    let output = Command::new("plasma-apply-colorscheme")
        .arg("--list-schemes")
        .output()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        if line.contains("(current color scheme)") {
            return Ok(line.contains("Dark"));
        }
    }
    Ok(false)
}

fn set_theme_kde(dark: bool) -> io::Result<()> {
    let scheme = if dark { "BreezeDark" } else { "BreezeLight" };
    Command::new("plasma-apply-colorscheme").arg(scheme).status()?;
    Ok(())
}

fn set_wallpaper_kde(color: &str) -> io::Result<()> {
    let rgb = if color == "Black" { "0,0,0" } else { "192,192,192" };

    let list_script = r#"
var allDesktops = desktops();
var output = [];
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    output.push(d.id);
}
output.join(',');
"#;

    let output = Command::new("qdbus")
        .args([
            "org.kde.plasmashell",
            "/PlasmaShell",
            "org.kde.PlasmaShell.evaluateScript",
            list_script,
        ])
        .output()?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    for screen in stdout.trim().split(',') {
        if screen.is_empty() {
            continue;
        }
        let set_script = format!(
            r#"
var d = desktopById({});
d.wallpaperPlugin = 'org.kde.color';
d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];
d.writeConfig('Color', '{}');
"#,
            screen, rgb
        );
        let _ = Command::new("qdbus")
            .args([
                "org.kde.plasmashell",
                "/PlasmaShell",
                "org.kde.PlasmaShell.evaluateScript",
                &set_script,
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
    Ok(())
}

fn open_settings_kde() -> io::Result<()> {
    Command::new("systemsettings")
        .arg("appearance")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;
    Ok(())
}

// State management

fn get_state_dir() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| String::from("/tmp"));
    PathBuf::from(home)
        .join(".local")
        .join("state")
        .join("switch-appearance")
}

fn get_state_file() -> PathBuf {
    get_state_dir().join("last-run")
}

fn write_state() -> io::Result<()> {
    let dir = get_state_dir();
    fs::create_dir_all(&dir)?;
    let today = chrono_lite_today();
    fs::write(get_state_file(), today)?;
    Ok(())
}

fn remove_state() {
    let _ = fs::remove_file(get_state_file());
}

// Simple date function (no chrono dependency)
fn chrono_lite_today() -> String {
    let output = Command::new("date")
        .arg("+%Y-%m-%d")
        .output()
        .expect("failed to get date");
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

// Platform-agnostic helpers

fn set_dark_mode(dark: bool) -> io::Result<()> {
    if is_macos() {
        set_dark_mode_macos(dark)?;
        let color = if dark { "Black" } else { "Silver" };
        set_wallpaper_macos(color)?;
    } else if is_kde() {
        set_theme_kde(dark)?;
        let color = if dark { "Black" } else { "Silver" };
        set_wallpaper_kde(color)?;
    } else {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Unsupported platform",
        ));
    }
    Ok(())
}

fn get_current_theme() -> io::Result<bool> {
    if is_macos() {
        get_current_theme_macos()
    } else if is_kde() {
        get_current_theme_kde()
    } else {
        Err(io::Error::new(
            io::ErrorKind::Other,
            "Unsupported platform",
        ))
    }
}

fn open_settings() {
    if is_macos() {
        let _ = open_settings_macos();
    } else if is_kde() {
        let _ = open_settings_kde();
    }
}

fn handle_init() -> io::Result<()> {
    if !is_macos() && !is_kde() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Unsupported platform",
        ));
    }

    set_dark_mode(true)?;
    println!("Set dark mode and wallpaper (init)");
    remove_state();
    Ok(())
}

fn handle_toggle() -> io::Result<()> {
    if !is_macos() && !is_kde() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Unsupported platform or desktop environment",
        ));
    }

    let is_dark = get_current_theme()?;
    let new_dark = !is_dark;
    set_dark_mode(new_dark)?;

    if new_dark {
        println!("Switched to Dark appearance");
    } else {
        println!("Switched to Light appearance");
    }

    if let Err(e) = write_state() {
        eprintln!("Warning: could not write state: {}", e);
    }

    open_settings();
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();

    let result = if args.len() > 1 && args[1] == "init" {
        handle_init()
    } else {
        handle_toggle()
    };

    if let Err(e) = result {
        eprintln!("{}", e);
        std::process::exit(1);
    }
}
