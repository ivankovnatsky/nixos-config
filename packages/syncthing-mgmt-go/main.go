package main

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"
)

const userAgent = "syncthing-mgmt-go/1.0.0"

// Config structs for parsing config.xml
type SyncthingConfig struct {
	GUI struct {
		APIKey string `xml:"apikey"`
	} `xml:"gui"`
}

// API response structs
type SystemStatus struct {
	MyID                    string            `json:"myID"`
	Version                 string            `json:"version"`
	OS                      string            `json:"os"`
	Arch                    string            `json:"arch"`
	Uptime                  int64             `json:"uptime"`
	ConnectionServiceStatus map[string]struct {
		Error *string `json:"error"`
	} `json:"connectionServiceStatus"`
	DiscoveryStatus map[string]struct {
		Error *string `json:"error"`
	} `json:"discoveryStatus"`
}

type Device struct {
	DeviceID string `json:"deviceID"`
	Name     string `json:"name"`
}

type Folder struct {
	ID      string `json:"id"`
	Label   string `json:"label"`
	Path    string `json:"path"`
	Devices []struct {
		DeviceID string `json:"deviceID"`
	} `json:"devices"`
}

type Connections struct {
	Total struct {
		InBytesTotal  int64 `json:"inBytesTotal"`
		OutBytesTotal int64 `json:"outBytesTotal"`
	} `json:"total"`
	Connections map[string]struct {
		Connected bool `json:"connected"`
		Paused    bool `json:"paused"`
	} `json:"connections"`
}

type Completion struct {
	Completion float64 `json:"completion"`
	NeedBytes  int64   `json:"needBytes"`
	NeedItems  int     `json:"needItems"`
}

// SyncthingClient handles API communication
type SyncthingClient struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

func NewClient(baseURL, apiKey string) *SyncthingClient {
	return &SyncthingClient{
		baseURL: strings.TrimRight(baseURL, "/"),
		apiKey:  apiKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (c *SyncthingClient) get(endpoint string) ([]byte, error) {
	url := c.baseURL + endpoint
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("X-API-Key", c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error: status %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

func (c *SyncthingClient) GetSystemStatus() (*SystemStatus, error) {
	data, err := c.get("/rest/system/status")
	if err != nil {
		return nil, err
	}
	var status SystemStatus
	if err := json.Unmarshal(data, &status); err != nil {
		return nil, err
	}
	return &status, nil
}

func (c *SyncthingClient) GetDevices() ([]Device, error) {
	data, err := c.get("/rest/config/devices")
	if err != nil {
		return nil, err
	}
	var devices []Device
	if err := json.Unmarshal(data, &devices); err != nil {
		return nil, err
	}
	return devices, nil
}

func (c *SyncthingClient) GetFolders() ([]Folder, error) {
	data, err := c.get("/rest/config/folders")
	if err != nil {
		return nil, err
	}
	var folders []Folder
	if err := json.Unmarshal(data, &folders); err != nil {
		return nil, err
	}
	return folders, nil
}

func (c *SyncthingClient) GetConnections() (*Connections, error) {
	data, err := c.get("/rest/system/connections")
	if err != nil {
		return nil, err
	}
	var conns Connections
	if err := json.Unmarshal(data, &conns); err != nil {
		return nil, err
	}
	return &conns, nil
}

func (c *SyncthingClient) GetCompletion(deviceID, folderID string) (*Completion, error) {
	endpoint := fmt.Sprintf("/rest/db/completion?device=%s", deviceID)
	if folderID != "" {
		endpoint += "&folder=" + folderID
	}
	data, err := c.get(endpoint)
	if err != nil {
		return nil, err
	}
	var comp Completion
	if err := json.Unmarshal(data, &comp); err != nil {
		return nil, err
	}
	return &comp, nil
}

// Utility functions

func getAPIKeyFromConfig(configPath string) (string, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return "", err
	}
	var config SyncthingConfig
	if err := xml.Unmarshal(data, &config); err != nil {
		return "", err
	}
	if config.GUI.APIKey == "" {
		return "", fmt.Errorf("API key not found in config.xml")
	}
	return config.GUI.APIKey, nil
}

func findListeningAddress(port int) string {
	if runtime.GOOS == "darwin" {
		// macOS: use lsof
		cmd := exec.Command("lsof", "-i", fmt.Sprintf(":%d", port), "-sTCP:LISTEN", "-n", "-P")
		output, err := cmd.Output()
		if err == nil && len(output) > 0 {
			lines := strings.Split(string(output), "\n")
			for _, line := range lines[1:] { // Skip header
				parts := strings.Fields(line)
				if len(parts) >= 9 {
					for i := len(parts) - 1; i >= 0; i-- {
						part := parts[i]
						if strings.Contains(part, ":") && !strings.HasPrefix(part, "(") {
							addr := strings.Split(part, ":")[0]
							if addr == "*" {
								return "0.0.0.0"
							}
							return addr
						}
					}
				}
			}
		}
	} else {
		// Linux: use ss
		cmd := exec.Command("ss", "-tlnH", "sport", "=", fmt.Sprintf(":%d", port))
		output, err := cmd.Output()
		if err == nil && len(output) > 0 {
			lines := strings.Split(string(output), "\n")
			for _, line := range lines {
				parts := strings.Fields(line)
				if len(parts) >= 4 {
					localAddr := parts[3]
					if idx := strings.LastIndex(localAddr, ":"); idx != -1 {
						addr := localAddr[:idx]
						if addr == "*" || addr == "0.0.0.0" || addr == "::" {
							return "0.0.0.0"
						}
						return addr
					}
				}
			}
		}
	}
	return ""
}

func findConfigXML() string {
	home, _ := os.UserHomeDir()
	paths := []string{
		filepath.Join(home, ".local/state/syncthing/config.xml"),
		filepath.Join(home, ".config/syncthing/config.xml"),
		"/var/lib/syncthing/.config/syncthing/config.xml",
		filepath.Join(home, "Library/Application Support/Syncthing/config.xml"),
	}
	for _, path := range paths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return ""
}

func formatBytes(bytes int64) string {
	if bytes == 0 {
		return "0 B"
	}
	units := []string{"B", "KB", "MB", "GB", "TB"}
	size := float64(bytes)
	unitIdx := 0
	for size >= 1024 && unitIdx < len(units)-1 {
		size /= 1024
		unitIdx++
	}
	if size < 10 {
		return fmt.Sprintf("%.2f %s", size, units[unitIdx])
	}
	return fmt.Sprintf("%.1f %s", size, units[unitIdx])
}

func formatUptime(seconds int64) string {
	days := seconds / 86400
	hours := (seconds % 86400) / 3600
	minutes := (seconds % 3600) / 60
	return fmt.Sprintf("%dd %dh %dm", days, hours, minutes)
}

// Display functions

func displayFolders(folders []Folder, devices []Device, localDeviceID string, client *SyncthingClient) {
	fmt.Println("\033[1;36mFolders\033[0m")

	if len(folders) == 0 {
		fmt.Println("  (none)")
		return
	}

	// Build device map
	deviceMap := make(map[string]string)
	for _, d := range devices {
		deviceMap[d.DeviceID] = d.Name
	}

	// Collect completion tasks
	type task struct {
		deviceID string
		folderID string
	}
	var tasks []task
	for _, folder := range folders {
		for _, d := range folder.Devices {
			if d.DeviceID != localDeviceID {
				tasks = append(tasks, task{d.DeviceID, folder.ID})
			}
		}
	}

	// Fetch completions in parallel
	completions := make(map[string]*Completion)
	var mu sync.Mutex
	var wg sync.WaitGroup
	sem := make(chan struct{}, 5) // limit concurrency

	for _, t := range tasks {
		wg.Add(1)
		go func(t task) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			comp, err := client.GetCompletion(t.deviceID, t.folderID)
			if err == nil {
				mu.Lock()
				completions[t.deviceID+":"+t.folderID] = comp
				mu.Unlock()
			}
		}(t)
	}
	wg.Wait()

	// Display folders
	for i, folder := range folders {
		if i > 0 {
			fmt.Println()
		}
		label := folder.Label
		if label == "" {
			label = folder.ID
		}
		fmt.Printf("  \033[1m%s\033[0m\n", label)
		fmt.Printf("  \033[2m%s\033[0m\n", folder.Path)

		for _, d := range folder.Devices {
			if d.DeviceID == localDeviceID {
				continue
			}
			name := deviceMap[d.DeviceID]
			if name == "" {
				name = d.DeviceID[:7] + "..."
			}

			status := ""
			key := d.DeviceID + ":" + folder.ID
			if comp, ok := completions[key]; ok {
				if comp.NeedItems > 0 {
					status = fmt.Sprintf("\033[31mOut of Sync:\033[0m %d items, ~%s",
						comp.NeedItems, formatBytes(comp.NeedBytes))
				} else {
					status = "\033[32mUp to Date\033[0m"
				}
			}
			fmt.Printf("    \033[33m%s\033[0m  %s\n", name, status)
		}
	}
}

func displayThisDevice(status *SystemStatus, conns *Connections) {
	fmt.Println()
	fmt.Println("\033[1;36mThis Device\033[0m")

	if conns != nil {
		fmt.Printf("  Download: %s total\n", formatBytes(conns.Total.InBytesTotal))
		fmt.Printf("  Upload: %s total\n", formatBytes(conns.Total.OutBytesTotal))
	}

	if status.ConnectionServiceStatus != nil {
		active := 0
		for _, s := range status.ConnectionServiceStatus {
			if s.Error == nil {
				active++
			}
		}
		fmt.Printf("  Listeners: %d/%d\n", active, len(status.ConnectionServiceStatus))
	}

	if status.DiscoveryStatus != nil {
		active := 0
		for _, s := range status.DiscoveryStatus {
			if s.Error == nil {
				active++
			}
		}
		fmt.Printf("  Discovery: %d/%d\n", active, len(status.DiscoveryStatus))
	}

	fmt.Printf("  Uptime: %s\n", formatUptime(status.Uptime))
	fmt.Printf("  ID: %s\n", status.MyID[:7])
	fmt.Printf("  Version: %s, %s (%s)\n", status.Version, status.OS, status.Arch)
}

func displayDevices(devices []Device, localDeviceID string, conns *Connections, client *SyncthingClient) {
	fmt.Println()
	fmt.Println("\033[1;36mRemote Devices\033[0m")

	// Filter out local device
	var remoteDevices []Device
	for _, d := range devices {
		if d.DeviceID != localDeviceID {
			remoteDevices = append(remoteDevices, d)
		}
	}

	if len(remoteDevices) == 0 {
		fmt.Println("  (none)")
		return
	}

	// Fetch completions for connected devices in parallel
	completions := make(map[string]*Completion)
	var mu sync.Mutex
	var wg sync.WaitGroup

	for _, d := range remoteDevices {
		if conns != nil {
			if conn, ok := conns.Connections[d.DeviceID]; ok && conn.Connected {
				wg.Add(1)
				go func(deviceID string) {
					defer wg.Done()
					comp, err := client.GetCompletion(deviceID, "")
					if err == nil {
						mu.Lock()
						completions[deviceID] = comp
						mu.Unlock()
					}
				}(d.DeviceID)
			}
		}
	}
	wg.Wait()

	// Display devices
	for _, d := range remoteDevices {
		connStatus := "\033[2mUnknown\033[0m"
		syncStatus := ""

		if conns != nil {
			if conn, ok := conns.Connections[d.DeviceID]; ok {
				if conn.Paused {
					connStatus = "\033[33mPaused\033[0m"
				} else if conn.Connected {
					connStatus = "\033[32mConnected\033[0m"
					if comp, ok := completions[d.DeviceID]; ok {
						if comp.Completion < 100 {
							syncStatus = fmt.Sprintf("Syncing %.0f%%, %s", comp.Completion, formatBytes(comp.NeedBytes))
						} else {
							syncStatus = "\033[32mUp to Date\033[0m"
						}
					}
				} else {
					connStatus = "\033[31mDisconnected\033[0m"
				}
			}
		}

		fmt.Printf("  \033[1;33m%s\033[0m (%s...)  %s  %s\n",
			d.Name, d.DeviceID[:7], connStatus, syncStatus)
	}
}

func main() {
	// Find config.xml
	configPath := findConfigXML()
	if configPath == "" {
		fmt.Fprintln(os.Stderr, "Error: Could not find Syncthing config.xml")
		os.Exit(1)
	}

	// Get API key
	apiKey, err := getAPIKeyFromConfig(configPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading API key: %v\n", err)
		os.Exit(1)
	}

	// Detect listening address
	baseURL := "http://127.0.0.1:8384"
	if addr := findListeningAddress(8384); addr != "" {
		if addr == "0.0.0.0" {
			addr = "127.0.0.1"
		}
		baseURL = fmt.Sprintf("http://%s:8384", addr)
	}

	client := NewClient(baseURL, apiKey)

	// Fetch initial data in parallel
	var status *SystemStatus
	var devices []Device
	var folders []Folder
	var conns *Connections
	var wg sync.WaitGroup
	var errStatus, errDevices, errFolders, errConns error

	wg.Add(4)
	go func() {
		defer wg.Done()
		status, errStatus = client.GetSystemStatus()
	}()
	go func() {
		defer wg.Done()
		devices, errDevices = client.GetDevices()
	}()
	go func() {
		defer wg.Done()
		folders, errFolders = client.GetFolders()
	}()
	go func() {
		defer wg.Done()
		conns, errConns = client.GetConnections()
	}()
	wg.Wait()

	// Check errors
	if errStatus != nil {
		fmt.Fprintf(os.Stderr, "Error getting status: %v\n", errStatus)
		os.Exit(1)
	}
	if errDevices != nil {
		fmt.Fprintf(os.Stderr, "Error getting devices: %v\n", errDevices)
		os.Exit(1)
	}
	if errFolders != nil {
		fmt.Fprintf(os.Stderr, "Error getting folders: %v\n", errFolders)
		os.Exit(1)
	}
	if errConns != nil {
		fmt.Fprintf(os.Stderr, "Warning: Could not get connections: %v\n", errConns)
	}

	localDeviceID := status.MyID

	// Display
	displayFolders(folders, devices, localDeviceID, client)
	displayThisDevice(status, conns)
	displayDevices(devices, localDeviceID, conns, client)
}
