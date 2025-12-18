const std = @import("std");
const builtin = @import("builtin");

const State = struct {
    allocator: std.mem.Allocator,

    fn getStateDir(self: State) ![]const u8 {
        const home = std.posix.getenv("HOME") orelse "/tmp";
        return try std.fmt.allocPrint(self.allocator, "{s}/.local/state/switch-appearance", .{home});
    }

    fn getStateFile(self: State) ![]const u8 {
        const dir = try self.getStateDir();
        defer self.allocator.free(dir);
        return try std.fmt.allocPrint(self.allocator, "{s}/last-run", .{dir});
    }

    fn writeState(self: State) !void {
        const dir = try self.getStateDir();
        defer self.allocator.free(dir);

        std.fs.makeDirAbsolute(dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const file_path = try self.getStateFile();
        defer self.allocator.free(file_path);

        // Get today's date
        const result = try runCommand(self.allocator, &.{ "date", "+%Y-%m-%d" });
        defer self.allocator.free(result);

        const trimmed = std.mem.trim(u8, result, &std.ascii.whitespace);

        const file = try std.fs.createFileAbsolute(file_path, .{});
        defer file.close();
        try file.writeAll(trimmed);
    }

    fn removeState(self: State) void {
        const file_path = self.getStateFile() catch return;
        defer self.allocator.free(file_path);
        std.fs.deleteFileAbsolute(file_path) catch {};
    }
};

fn isMacOS() bool {
    return builtin.os.tag == .macos;
}

fn isKDE() bool {
    if (std.posix.getenv("XDG_CURRENT_DESKTOP")) |desktop| {
        if (std.mem.indexOf(u8, desktop, "KDE") != null or
            std.mem.indexOf(u8, desktop, "Plasma") != null)
        {
            return true;
        }
    }

    // Fallback: check if plasmashell is running
    var child = std.process.Child.init(&.{ "pgrep", "plasmashell" }, std.heap.page_allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    const term = child.spawnAndWait() catch return false;
    return term == .Exited and term.Exited == 0;
}

fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    });
    defer allocator.free(result.stderr);
    return result.stdout;
}

fn runCommandNoOutput(argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, std.heap.page_allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    _ = try child.spawnAndWait();
}

fn runCommandDetached(argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, std.heap.page_allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    try child.spawn();
    // Don't wait - let it run in background
}

// macOS Functions

fn getCurrentThemeMacOS(allocator: std.mem.Allocator) !bool {
    const output = try runCommand(allocator, &.{
        "osascript",
        "-e",
        "tell application \"System Events\" to tell appearance preferences to get dark mode",
    });
    defer allocator.free(output);
    const trimmed = std.mem.trim(u8, output, &std.ascii.whitespace);
    return std.mem.eql(u8, trimmed, "true");
}

fn setDarkModeMacOS(dark: bool) !void {
    const mode = if (dark) "true" else "false";
    const script = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "tell application \"System Events\" to tell appearance preferences to set dark mode to {s}",
        .{mode},
    );
    defer std.heap.page_allocator.free(script);
    try runCommandNoOutput(&.{ "osascript", "-e", script });
}

fn setWallpaperMacOS(color: []const u8) !void {
    const script = try std.fmt.allocPrint(
        std.heap.page_allocator,
        \\tell application "System Events"
        \\    tell every desktop
        \\        set picture to "/System/Library/Desktop Pictures/Solid Colors/{s}.png"
        \\    end tell
        \\end tell
    ,
        .{color},
    );
    defer std.heap.page_allocator.free(script);
    try runCommandNoOutput(&.{ "osascript", "-e", script });
}

fn openSettingsMacOS() !void {
    const script =
        \\tell application "System Settings"
        \\    activate
        \\    delay 0.5
        \\    tell application "System Events"
        \\        tell process "System Settings"
        \\            click menu item "Wallpaper" of menu "View" of menu bar 1
        \\        end tell
        \\    end tell
        \\end tell
    ;
    try runCommandNoOutput(&.{ "osascript", "-e", script });
}

// KDE Plasma Functions

fn getCurrentThemeKDE(allocator: std.mem.Allocator) !bool {
    const output = try runCommand(allocator, &.{ "plasma-apply-colorscheme", "--list-schemes" });
    defer allocator.free(output);

    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "(current color scheme)") != null) {
            return std.mem.indexOf(u8, line, "Dark") != null;
        }
    }
    return false;
}

fn setThemeKDE(dark: bool) !void {
    const scheme = if (dark) "BreezeDark" else "BreezeLight";
    try runCommandNoOutput(&.{ "plasma-apply-colorscheme", scheme });
}

fn setWallpaperKDE(allocator: std.mem.Allocator, color: []const u8) !void {
    const rgb = if (std.mem.eql(u8, color, "Black")) "0,0,0" else "192,192,192";

    const list_script =
        \\var allDesktops = desktops();
        \\var output = [];
        \\for (var i = 0; i < allDesktops.length; i++) {
        \\    var d = allDesktops[i];
        \\    output.push(d.id);
        \\}
        \\output.join(',');
    ;

    const output = try runCommand(allocator, &.{
        "qdbus",
        "org.kde.plasmashell",
        "/PlasmaShell",
        "org.kde.PlasmaShell.evaluateScript",
        list_script,
    });
    defer allocator.free(output);

    const trimmed = std.mem.trim(u8, output, &std.ascii.whitespace);
    var screens = std.mem.splitScalar(u8, trimmed, ',');

    while (screens.next()) |screen| {
        if (screen.len == 0) continue;

        const set_script = try std.fmt.allocPrint(allocator,
            \\var d = desktopById({s});
            \\d.wallpaperPlugin = 'org.kde.color';
            \\d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General'];
            \\d.writeConfig('Color', '{s}');
        , .{ screen, rgb });
        defer allocator.free(set_script);

        runCommandNoOutput(&.{
            "qdbus",
            "org.kde.plasmashell",
            "/PlasmaShell",
            "org.kde.PlasmaShell.evaluateScript",
            set_script,
        }) catch {};
    }
}

fn openSettingsKDE() !void {
    try runCommandDetached(&.{ "systemsettings", "appearance" });
}

// Platform-agnostic helpers

fn setDarkMode(allocator: std.mem.Allocator, dark: bool) !void {
    const color = if (dark) "Black" else "Silver";

    if (isMacOS()) {
        try setDarkModeMacOS(dark);
        try setWallpaperMacOS(color);
    } else if (isKDE()) {
        try setThemeKDE(dark);
        try setWallpaperKDE(allocator, color);
    } else {
        return error.UnsupportedPlatform;
    }
}

fn getCurrentTheme(allocator: std.mem.Allocator) !bool {
    if (isMacOS()) {
        return getCurrentThemeMacOS(allocator);
    } else if (isKDE()) {
        return getCurrentThemeKDE(allocator);
    } else {
        return error.UnsupportedPlatform;
    }
}

fn openSettings() void {
    if (isMacOS()) {
        openSettingsMacOS() catch {};
    } else if (isKDE()) {
        openSettingsKDE() catch {};
    }
}

fn handleInit(allocator: std.mem.Allocator) !void {
    if (!isMacOS() and !isKDE()) {
        return error.UnsupportedPlatform;
    }

    try setDarkMode(allocator, true);

    std.debug.print("Set dark mode and wallpaper (init)\n", .{});

    const state = State{ .allocator = allocator };
    state.removeState();
}

fn handleToggle(allocator: std.mem.Allocator) !void {
    if (!isMacOS() and !isKDE()) {
        return error.UnsupportedPlatform;
    }

    const is_dark = try getCurrentTheme(allocator);
    const new_dark = !is_dark;
    try setDarkMode(allocator, new_dark);

    if (new_dark) {
        std.debug.print("Switched to Dark appearance\n", .{});
    } else {
        std.debug.print("Switched to Light appearance\n", .{});
    }

    const state = State{ .allocator = allocator };
    state.writeState() catch |err| {
        std.debug.print("Warning: could not write state: {}\n", .{err});
    };

    openSettings();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1 and std.mem.eql(u8, args[1], "init")) {
        handleInit(allocator) catch |err| {
            std.debug.print("{}\n", .{err});
            std.process.exit(1);
        };
    } else {
        handleToggle(allocator) catch |err| {
            std.debug.print("{}\n", .{err});
            std.process.exit(1);
        };
    }
}
