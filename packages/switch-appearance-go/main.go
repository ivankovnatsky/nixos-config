package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

func isMacOS() bool {
	return runtime.GOOS == "darwin"
}

func isKDE() bool {
	// Check environment variables first
	desktop := os.Getenv("XDG_CURRENT_DESKTOP")
	if strings.Contains(desktop, "KDE") || strings.Contains(desktop, "Plasma") {
		return true
	}

	// Fallback: check if plasmashell is running
	err := exec.Command("pgrep", "plasmashell").Run()
	return err == nil
}

// macOS Functions

func getCurrentThemeMacOS() (bool, error) {
	cmd := exec.Command("osascript", "-e",
		`tell application "System Events" to tell appearance preferences to get dark mode`)
	output, err := cmd.Output()
	if err != nil {
		return false, err
	}
	return strings.TrimSpace(string(output)) == "true", nil
}

func setDarkModeMacOS(dark bool) error {
	mode := "false"
	if dark {
		mode = "true"
	}
	cmd := exec.Command("osascript", "-e",
		fmt.Sprintf(`tell application "System Events" to tell appearance preferences to set dark mode to %s`, mode))
	return cmd.Run()
}

func setWallpaperMacOS(color string) error {
	filePath := fmt.Sprintf("/System/Library/Desktop Pictures/Solid Colors/%s.png", color)
	script := fmt.Sprintf(`
tell application "System Events"
    tell every desktop
        set picture to "%s"
    end tell
end tell
`, filePath)
	cmd := exec.Command("osascript", "-e", script)
	return cmd.Run()
}

func openSettingsMacOS() error {
	script := `
tell application "System Settings"
    activate
    delay 0.5
    tell application "System Events"
        tell process "System Settings"
            click menu item "Wallpaper" of menu "View" of menu bar 1
        end tell
    end tell
end tell
`
	cmd := exec.Command("osascript", "-e", script)
	cmd.Stdout = nil // suppress output
	return cmd.Run()
}

// KDE Plasma Functions

func getCurrentThemeKDE() (bool, error) {
	cmd := exec.Command("plasma-apply-colorscheme", "--list-schemes")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return false, err
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "(current color scheme)") {
			return strings.Contains(line, "Dark"), nil
		}
	}
	return false, nil
}

func setThemeKDE(dark bool) error {
	scheme := "BreezeLight"
	if dark {
		scheme = "BreezeDark"
	}
	cmd := exec.Command("plasma-apply-colorscheme", scheme)
	return cmd.Run()
}

func setWallpaperKDE(color string) error {
	rgb := "192,192,192" // Silver
	if color == "Black" {
		rgb = "0,0,0"
	}

	// Get all desktop IDs
	listScript := `
var allDesktops = desktops();
var output = [];
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    output.push(d.id);
}
output.join(',');
`
	cmd := exec.Command("qdbus", "org.kde.plasmashell", "/PlasmaShell",
		"org.kde.PlasmaShell.evaluateScript", listScript)
	output, err := cmd.Output()
	if err != nil {
		return err
	}

	screens := strings.Split(strings.TrimSpace(string(output)), ",")
	for _, screen := range screens {
		if screen == "" {
			continue
		}
		setScript := fmt.Sprintf(`
var d = desktopById(%s);
d.wallpaperPlugin = 'org.kde.color';
d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];
d.writeConfig('Color', '%s');
`, screen, rgb)
		cmd := exec.Command("qdbus", "org.kde.plasmashell", "/PlasmaShell",
			"org.kde.PlasmaShell.evaluateScript", setScript)
		cmd.Run() // ignore errors for individual screens
	}
	return nil
}

func openSettingsKDE() error {
	cmd := exec.Command("systemsettings", "appearance")
	return cmd.Start() // don't wait
}

// State management

func getStateDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".local", "state", "switch-appearance")
}

func getStateFile() string {
	return filepath.Join(getStateDir(), "last-run")
}

func writeState() error {
	dir := getStateDir()
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	today := time.Now().Format("2006-01-02")
	return os.WriteFile(getStateFile(), []byte(today), 0644)
}

func removeState() error {
	return os.Remove(getStateFile())
}

// Platform-agnostic helpers

func setDarkMode(dark bool) error {
	if isMacOS() {
		if err := setDarkModeMacOS(dark); err != nil {
			return err
		}
		color := "Silver"
		if dark {
			color = "Black"
		}
		return setWallpaperMacOS(color)
	} else if isKDE() {
		if err := setThemeKDE(dark); err != nil {
			return err
		}
		color := "Silver"
		if dark {
			color = "Black"
		}
		return setWallpaperKDE(color)
	}
	return fmt.Errorf("unsupported platform")
}

func getCurrentTheme() (bool, error) {
	if isMacOS() {
		return getCurrentThemeMacOS()
	} else if isKDE() {
		return getCurrentThemeKDE()
	}
	return false, fmt.Errorf("unsupported platform")
}

func openSettings() error {
	if isMacOS() {
		return openSettingsMacOS()
	} else if isKDE() {
		return openSettingsKDE()
	}
	return nil
}

func handleInit() error {
	if !isMacOS() && !isKDE() {
		return fmt.Errorf("unsupported platform")
	}

	if err := setDarkMode(true); err != nil {
		return err
	}
	fmt.Println("Set dark mode and wallpaper (init)")
	removeState() // ignore error
	return nil
}

func handleToggle() error {
	if !isMacOS() && !isKDE() {
		return fmt.Errorf("unsupported platform or desktop environment")
	}

	isDark, err := getCurrentTheme()
	if err != nil {
		return err
	}

	// Toggle to opposite
	newDark := !isDark
	if err := setDarkMode(newDark); err != nil {
		return err
	}

	if newDark {
		fmt.Println("Switched to Dark appearance")
	} else {
		fmt.Println("Switched to Light appearance")
	}

	if err := writeState(); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not write state: %v\n", err)
	}

	if err := openSettings(); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: could not open settings: %v\n", err)
	}

	return nil
}

func main() {
	var err error

	if len(os.Args) > 1 && os.Args[1] == "init" {
		err = handleInit()
	} else {
		err = handleToggle()
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
