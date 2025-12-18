const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;

// JSON parsing helpers
fn findJsonString(json: []const u8, key: []const u8) ?[]const u8 {
    const pattern = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\":\"", .{key}) catch return null;
    defer std.heap.page_allocator.free(pattern);

    if (std.mem.indexOf(u8, json, pattern)) |start| {
        const value_start = start + pattern.len;
        if (std.mem.indexOfScalarPos(u8, json, value_start, '"')) |end| {
            return json[value_start..end];
        }
    }
    return null;
}

fn findJsonNumber(json: []const u8, key: []const u8) ?i64 {
    const pattern = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\":", .{key}) catch return null;
    defer std.heap.page_allocator.free(pattern);

    if (std.mem.indexOf(u8, json, pattern)) |start| {
        var value_start = start + pattern.len;
        // Skip whitespace
        while (value_start < json.len and (json[value_start] == ' ' or json[value_start] == '\t')) {
            value_start += 1;
        }
        // Find end of number
        var value_end = value_start;
        while (value_end < json.len and (json[value_end] >= '0' and json[value_end] <= '9' or json[value_end] == '-')) {
            value_end += 1;
        }
        if (value_end > value_start) {
            return std.fmt.parseInt(i64, json[value_start..value_end], 10) catch null;
        }
    }
    return null;
}

fn findJsonBool(json: []const u8, key: []const u8) ?bool {
    const pattern = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\":", .{key}) catch return null;
    defer std.heap.page_allocator.free(pattern);

    if (std.mem.indexOf(u8, json, pattern)) |start| {
        var value_start = start + pattern.len;
        while (value_start < json.len and json[value_start] == ' ') {
            value_start += 1;
        }
        if (value_start + 4 <= json.len and std.mem.eql(u8, json[value_start .. value_start + 4], "true")) {
            return true;
        }
        if (value_start + 5 <= json.len and std.mem.eql(u8, json[value_start .. value_start + 5], "false")) {
            return false;
        }
    }
    return null;
}

fn findJsonFloat(json: []const u8, key: []const u8) ?f64 {
    const pattern = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\":", .{key}) catch return null;
    defer std.heap.page_allocator.free(pattern);

    if (std.mem.indexOf(u8, json, pattern)) |start| {
        var value_start = start + pattern.len;
        while (value_start < json.len and json[value_start] == ' ') {
            value_start += 1;
        }
        var value_end = value_start;
        while (value_end < json.len and (json[value_end] >= '0' and json[value_end] <= '9' or json[value_end] == '.' or json[value_end] == '-')) {
            value_end += 1;
        }
        if (value_end > value_start) {
            return std.fmt.parseFloat(f64, json[value_start..value_end]) catch null;
        }
    }
    return null;
}

fn runCommand(allocator: Allocator, argv: []const []const u8) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    });
    defer allocator.free(result.stderr);
    return result.stdout;
}

fn getApiKeyFromConfig(allocator: Allocator, config_path: []const u8) ![]const u8 {
    const content = try std.fs.cwd().readFileAlloc(allocator, config_path, 1024 * 1024);
    defer allocator.free(content);

    // Find <apikey>...</apikey>
    const start_tag = "<apikey>";
    const end_tag = "</apikey>";

    if (std.mem.indexOf(u8, content, start_tag)) |start| {
        const value_start = start + start_tag.len;
        if (std.mem.indexOfPos(u8, content, value_start, end_tag)) |end| {
            return try allocator.dupe(u8, content[value_start..end]);
        }
    }
    return error.ApiKeyNotFound;
}

fn findListeningAddress(allocator: Allocator, port: u16) !?[]const u8 {
    if (builtin.os.tag == .macos) {
        const port_str = try std.fmt.allocPrint(allocator, ":{d}", .{port});
        defer allocator.free(port_str);

        const result = std.process.Child.run(.{
            .allocator = allocator,
            .argv = &.{ "lsof", "-i", port_str, "-sTCP:LISTEN", "-n", "-P" },
        }) catch return null;
        defer allocator.free(result.stderr);
        defer allocator.free(result.stdout);

        if (result.stdout.len == 0) return null;

        var lines = std.mem.splitScalar(u8, result.stdout, '\n');
        _ = lines.next(); // Skip header
        while (lines.next()) |line| {
            var parts = std.mem.splitAny(u8, line, " \t");
            var last_addr: ?[]const u8 = null;
            while (parts.next()) |part| {
                if (part.len > 0 and std.mem.indexOf(u8, part, ":") != null and part[0] != '(') {
                    if (std.mem.indexOf(u8, part, ":")) |colon| {
                        last_addr = part[0..colon];
                    }
                }
            }
            if (last_addr) |addr| {
                if (std.mem.eql(u8, addr, "*")) {
                    return try allocator.dupe(u8, "0.0.0.0");
                }
                return try allocator.dupe(u8, addr);
            }
        }
    } else {
        const port_str = try std.fmt.allocPrint(allocator, ":{d}", .{port});
        defer allocator.free(port_str);

        const result = std.process.Child.run(.{
            .allocator = allocator,
            .argv = &.{ "ss", "-tlnH", "sport", "=", port_str },
        }) catch return null;
        defer allocator.free(result.stderr);
        defer allocator.free(result.stdout);

        if (result.stdout.len == 0) return null;

        var lines = std.mem.splitScalar(u8, result.stdout, '\n');
        while (lines.next()) |line| {
            var parts = std.mem.splitAny(u8, line, " \t");
            var col: usize = 0;
            while (parts.next()) |part| {
                if (part.len == 0) continue;
                col += 1;
                if (col == 4) { // Local Address:Port
                    if (std.mem.lastIndexOf(u8, part, ":")) |colon| {
                        const addr = part[0..colon];
                        if (std.mem.eql(u8, addr, "*") or std.mem.eql(u8, addr, "0.0.0.0") or std.mem.eql(u8, addr, "::")) {
                            return try allocator.dupe(u8, "0.0.0.0");
                        }
                        return try allocator.dupe(u8, addr);
                    }
                }
            }
        }
    }
    return null;
}

fn findConfigXml(allocator: Allocator) !?[]const u8 {
    const home = std.posix.getenv("HOME") orelse return null;

    const paths = [_][]const u8{
        try std.fmt.allocPrint(allocator, "{s}/.local/state/syncthing/config.xml", .{home}),
        try std.fmt.allocPrint(allocator, "{s}/.config/syncthing/config.xml", .{home}),
        "/var/lib/syncthing/.config/syncthing/config.xml",
        try std.fmt.allocPrint(allocator, "{s}/Library/Application Support/Syncthing/config.xml", .{home}),
    };

    for (paths) |path| {
        if (std.fs.cwd().access(path, .{})) {
            return path;
        } else |_| {
            if (path.len > 0 and path[0] != '/') {
                allocator.free(path);
            }
        }
    }
    return null;
}

fn httpGet(allocator: Allocator, url: []const u8, api_key: []const u8) ![]const u8 {
    const header = try std.fmt.allocPrint(allocator, "X-API-Key: {s}", .{api_key});
    defer allocator.free(header);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "curl", "-s", "-H", header, url },
    });
    defer allocator.free(result.stderr);
    return result.stdout;
}

fn formatBytes(bytes: i64) [32]u8 {
    var buf: [32]u8 = undefined;
    if (bytes == 0) {
        const result = "0 B";
        @memcpy(buf[0..result.len], result);
        buf[result.len] = 0;
        return buf;
    }

    const units = [_][]const u8{ "B", "KB", "MB", "GB", "TB" };
    var size: f64 = @floatFromInt(bytes);
    var unit_idx: usize = 0;

    while (size >= 1024 and unit_idx < units.len - 1) {
        size /= 1024;
        unit_idx += 1;
    }

    const formatted = if (size < 10)
        std.fmt.bufPrint(&buf, "{d:.2} {s}", .{ size, units[unit_idx] }) catch "?"
    else
        std.fmt.bufPrint(&buf, "{d:.1} {s}", .{ size, units[unit_idx] }) catch "?";

    buf[formatted.len] = 0;
    return buf;
}

fn formatUptime(seconds: i64) [32]u8 {
    var buf: [32]u8 = undefined;
    const days = @divFloor(seconds, 86400);
    const hours = @divFloor(@mod(seconds, 86400), 3600);
    const minutes = @divFloor(@mod(seconds, 3600), 60);
    const formatted = std.fmt.bufPrint(&buf, "{d}d {d}h {d}m", .{ days, hours, minutes }) catch "?";
    buf[formatted.len] = 0;
    return buf;
}

const Device = struct {
    device_id: []const u8,
    name: []const u8,
};

const MAX_DEVICES = 32;

const DeviceList = struct {
    items: [MAX_DEVICES]Device,
    len: usize,
    allocator: Allocator,
};

fn parseDevices(allocator: Allocator, json: []const u8) !DeviceList {
    var result = DeviceList{
        .items = undefined,
        .len = 0,
        .allocator = allocator,
    };

    // Simple parser for device array
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, json, pos, "\"deviceID\":\"")) |start| {
        if (result.len >= MAX_DEVICES) break;

        const id_start = start + 12;
        if (std.mem.indexOfScalarPos(u8, json, id_start, '"')) |id_end| {
            const device_id = try allocator.dupe(u8, json[id_start..id_end]);

            // Find name
            var name: []const u8 = "Unknown";
            if (std.mem.indexOfPos(u8, json[id_end..], 0, "\"name\":\"")) |name_offset| {
                const name_start = id_end + name_offset + 8;
                if (std.mem.indexOfScalarPos(u8, json, name_start, '"')) |name_end| {
                    name = try allocator.dupe(u8, json[name_start..name_end]);
                }
            }

            result.items[result.len] = .{ .device_id = device_id, .name = name };
            result.len += 1;
            pos = id_end;
        } else {
            break;
        }
    }
    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Find config.xml
    const config_path = try findConfigXml(allocator) orelse {
        std.debug.print("Error: Could not find Syncthing config.xml\n", .{});
        std.process.exit(1);
    };

    // Get API key
    const api_key = getApiKeyFromConfig(allocator, config_path) catch {
        std.debug.print("Error reading API key\n", .{});
        std.process.exit(1);
    };
    defer allocator.free(api_key);

    // Detect listening address
    var base_url: []const u8 = "http://127.0.0.1:8384";
    if (try findListeningAddress(allocator, 8384)) |addr| {
        defer allocator.free(addr);
        const effective_addr = if (std.mem.eql(u8, addr, "0.0.0.0")) "127.0.0.1" else addr;
        base_url = try std.fmt.allocPrint(allocator, "http://{s}:8384", .{effective_addr});
    }

    // Fetch data
    const status_url = try std.fmt.allocPrint(allocator, "{s}/rest/system/status", .{base_url});
    defer allocator.free(status_url);
    const status_json = try httpGet(allocator, status_url, api_key);
    defer allocator.free(status_json);

    const devices_url = try std.fmt.allocPrint(allocator, "{s}/rest/config/devices", .{base_url});
    defer allocator.free(devices_url);
    const devices_json = try httpGet(allocator, devices_url, api_key);
    defer allocator.free(devices_json);

    const folders_url = try std.fmt.allocPrint(allocator, "{s}/rest/config/folders", .{base_url});
    defer allocator.free(folders_url);
    const folders_json = try httpGet(allocator, folders_url, api_key);
    defer allocator.free(folders_json);

    const conns_url = try std.fmt.allocPrint(allocator, "{s}/rest/system/connections", .{base_url});
    defer allocator.free(conns_url);
    const conns_json = try httpGet(allocator, conns_url, api_key);
    defer allocator.free(conns_json);

    // Parse status
    const my_id = findJsonString(status_json, "myID") orelse "unknown";
    const version = findJsonString(status_json, "version") orelse "unknown";
    const os = findJsonString(status_json, "os") orelse "";
    const arch = findJsonString(status_json, "arch") orelse "";
    const uptime = findJsonNumber(status_json, "uptime") orelse 0;

    // Parse devices
    var devices = try parseDevices(allocator, devices_json);
    defer {
        for (devices.items[0..devices.len]) |d| {
            allocator.free(d.device_id);
            if (!std.mem.eql(u8, d.name, "Unknown")) {
                allocator.free(d.name);
            }
        }
    }

    // Helper to find device name by ID
    const findDeviceName = struct {
        fn find(devs: []const Device, dev_id: []const u8) []const u8 {
            for (devs) |d| {
                if (std.mem.eql(u8, d.device_id, dev_id)) {
                    return d.name;
                }
            }
            return "Unknown";
        }
    }.find;

    // Display Folders
    std.debug.print("\x1b[1;36mFolders\x1b[0m\n", .{});

    // Simple folder display - parse folder IDs and labels
    var folder_pos: usize = 0;
    var first_folder = true;
    while (std.mem.indexOfPos(u8, folders_json, folder_pos, "\"id\":\"")) |start| {
        if (!first_folder) std.debug.print("\n", .{});
        first_folder = false;

        const id_start = start + 6;
        if (std.mem.indexOfScalarPos(u8, folders_json, id_start, '"')) |id_end| {
            const folder_id = folders_json[id_start..id_end];

            // Find label
            var label = folder_id;
            if (std.mem.indexOfPos(u8, folders_json[id_end..], 0, "\"label\":\"")) |label_offset| {
                const label_start = id_end + label_offset + 9;
                if (std.mem.indexOfScalarPos(u8, folders_json, label_start, '"')) |label_end| {
                    if (label_end > label_start) {
                        label = folders_json[label_start..label_end];
                    }
                }
            }

            // Find path
            var path: []const u8 = "";
            if (std.mem.indexOfPos(u8, folders_json[id_end..], 0, "\"path\":\"")) |path_offset| {
                const path_start = id_end + path_offset + 8;
                if (std.mem.indexOfScalarPos(u8, folders_json, path_start, '"')) |path_end| {
                    path = folders_json[path_start..path_end];
                }
            }

            std.debug.print("  \x1b[1m{s}\x1b[0m\n", .{label});
            std.debug.print("  \x1b[2m{s}\x1b[0m\n", .{path});

            // Find devices in this folder
            const search_end = if (std.mem.indexOfPos(u8, folders_json, id_end, "},{")) |next| next else folders_json.len;
            var dev_pos = id_end;
            while (std.mem.indexOfPos(u8, folders_json[dev_pos..search_end], 0, "\"deviceID\":\"")) |dev_offset| {
                const dev_start = dev_pos + dev_offset + 12;
                if (std.mem.indexOfScalarPos(u8, folders_json, dev_start, '"')) |dev_end| {
                    const dev_id = folders_json[dev_start..dev_end];

                    // Skip local device
                    if (!std.mem.eql(u8, dev_id, my_id)) {
                        const name = findDeviceName(devices.items[0..devices.len], dev_id);
                        const short_id = if (dev_id.len >= 7) dev_id[0..7] else dev_id;

                        // Get completion for this device+folder
                        const comp_url = std.fmt.allocPrint(allocator, "{s}/rest/db/completion?device={s}&folder={s}", .{ base_url, dev_id, folder_id }) catch {
                            dev_pos = dev_end;
                            continue;
                        };
                        defer allocator.free(comp_url);

                        if (httpGet(allocator, comp_url, api_key)) |comp_json| {
                            defer allocator.free(comp_json);
                            const need_items = findJsonNumber(comp_json, "needItems") orelse 0;
                            const need_bytes = findJsonNumber(comp_json, "needBytes") orelse 0;

                            if (need_items > 0) {
                                const bytes_str = formatBytes(need_bytes);
                                const bytes_slice = std.mem.sliceTo(&bytes_str, 0);
                                std.debug.print("    \x1b[33m{s}\x1b[0m ({s}...)  \x1b[31mOut of Sync:\x1b[0m {d} items, ~{s}\n", .{ name, short_id, need_items, bytes_slice });
                            } else {
                                std.debug.print("    \x1b[33m{s}\x1b[0m ({s}...)  \x1b[32mUp to Date\x1b[0m\n", .{ name, short_id });
                            }
                        } else |_| {
                            std.debug.print("    \x1b[33m{s}\x1b[0m ({s}...)\n", .{ name, short_id });
                        }
                    }
                    dev_pos = dev_end;
                } else {
                    break;
                }
            }

            folder_pos = id_end;
        } else {
            break;
        }
    }

    // Display This Device
    std.debug.print("\n\x1b[1;36mThis Device\x1b[0m\n", .{});

    const in_bytes = findJsonNumber(conns_json, "inBytesTotal") orelse 0;
    const out_bytes = findJsonNumber(conns_json, "outBytesTotal") orelse 0;
    const in_str = formatBytes(in_bytes);
    const out_str = formatBytes(out_bytes);
    std.debug.print("  Download: {s} total\n", .{std.mem.sliceTo(&in_str, 0)});
    std.debug.print("  Upload: {s} total\n", .{std.mem.sliceTo(&out_str, 0)});

    const uptime_str = formatUptime(uptime);
    std.debug.print("  Uptime: {s}\n", .{std.mem.sliceTo(&uptime_str, 0)});

    const short_id = if (my_id.len >= 7) my_id[0..7] else my_id;
    std.debug.print("  ID: {s}\n", .{short_id});
    std.debug.print("  Version: {s}, {s} ({s})\n", .{ version, os, arch });

    // Display Remote Devices
    std.debug.print("\n\x1b[1;36mRemote Devices\x1b[0m\n", .{});

    for (devices.items[0..devices.len]) |d| {
        if (std.mem.eql(u8, d.device_id, my_id)) continue;

        const short_dev_id = if (d.device_id.len >= 7) d.device_id[0..7] else d.device_id;

        // Check connection status
        const connected_pattern = std.fmt.allocPrint(allocator, "\"{s}\":{{", .{d.device_id}) catch continue;
        defer allocator.free(connected_pattern);

        var conn_status: []const u8 = "\x1b[2mUnknown\x1b[0m";
        var sync_status: []const u8 = "";

        if (std.mem.indexOf(u8, conns_json, connected_pattern)) |conn_start| {
            const conn_end = std.mem.indexOfPos(u8, conns_json, conn_start, "}") orelse conns_json.len;
            const conn_obj = conns_json[conn_start..conn_end];

            const connected = findJsonBool(conn_obj, "connected") orelse false;
            const paused = findJsonBool(conn_obj, "paused") orelse false;

            if (paused) {
                conn_status = "\x1b[33mPaused\x1b[0m";
            } else if (connected) {
                conn_status = "\x1b[32mConnected\x1b[0m";

                // Get completion
                const comp_url = std.fmt.allocPrint(allocator, "{s}/rest/db/completion?device={s}", .{ base_url, d.device_id }) catch {
                    std.debug.print("  \x1b[1;33m{s}\x1b[0m ({s}...)  {s}  {s}\n", .{ d.name, short_dev_id, conn_status, sync_status });
                    continue;
                };
                defer allocator.free(comp_url);

                if (httpGet(allocator, comp_url, api_key)) |comp_json| {
                    defer allocator.free(comp_json);
                    const completion = findJsonFloat(comp_json, "completion") orelse 100.0;
                    if (completion < 100.0) {
                        const need_bytes = findJsonNumber(comp_json, "needBytes") orelse 0;
                        const bytes_str = formatBytes(need_bytes);
                        std.debug.print("  \x1b[1;33m{s}\x1b[0m ({s}...)  {s}  Syncing {d:.0}%, {s}\n", .{ d.name, short_dev_id, conn_status, completion, std.mem.sliceTo(&bytes_str, 0) });
                        continue;
                    } else {
                        sync_status = "\x1b[32mUp to Date\x1b[0m";
                    }
                } else |_| {}
            } else {
                conn_status = "\x1b[31mDisconnected\x1b[0m";
            }
        }

        std.debug.print("  \x1b[1;33m{s}\x1b[0m ({s}...)  {s}  {s}\n", .{ d.name, short_dev_id, conn_status, sync_status });
    }
}
