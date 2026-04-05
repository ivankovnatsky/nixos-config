"""Rich table display functions for devices, folders, and system status."""

from rich.console import Console
from rich.table import Table
from rich import box

from utils import format_bytes


def display_this_device(system_status, connections_data=None):
    """Display information about this device."""
    if not system_status:
        return

    console = Console()
    console.print()  # Add blank line
    console.print("[bold cyan]This Device[/bold cyan]")

    # Create table
    table = Table(show_header=False, show_lines=False, box=box.ROUNDED, padding=(0, 1))
    table.add_column("Property", style="dim", width=25)
    table.add_column("Value", style="bold")

    # Download/Upload Rate
    if connections_data:
        total_in_rate = connections_data.get("total", {}).get("inBytesTotal", 0)
        total_out_rate = connections_data.get("total", {}).get("outBytesTotal", 0)
        total_in_str = format_bytes(total_in_rate)
        total_out_str = format_bytes(total_out_rate)
        table.add_row("Download Rate", f"0 B/s ({total_in_str})")
        table.add_row("Upload Rate", f"0 B/s ({total_out_str})")

    # Listeners
    num_listeners = system_status.get("connectionServiceStatus", {})
    if num_listeners:
        active = sum(
            1 for svc, status in num_listeners.items() if status.get("error") is None
        )
        total = len(num_listeners)
        table.add_row("Listeners", f"{active}/{total}")

    # Discovery
    discovery_status = system_status.get("discoveryStatus", {})
    if discovery_status:
        active = sum(
            1 for svc, status in discovery_status.items() if status.get("error") is None
        )
        total = len(discovery_status)
        table.add_row("Discovery", f"{active}/{total}")

    # Uptime
    uptime_sec = system_status.get("uptime", 0)
    if uptime_sec:
        days = uptime_sec // 86400
        hours = (uptime_sec % 86400) // 3600
        minutes = (uptime_sec % 3600) // 60
        uptime_str = f"{days}d {hours}h {minutes}m"
        table.add_row("Uptime", uptime_str)

    # Identification (short device ID)
    device_id = system_status.get("myID", "")
    if device_id:
        short_id = device_id[:7]
        table.add_row("Identification", short_id)

    # Version
    version = system_status.get("version", "")
    os_info = system_status.get("os", "")
    arch = system_status.get("arch", "")
    if version:
        version_str = f"{version}"
        if os_info or arch:
            version_str += f", {os_info}"
            if arch:
                version_str += f" ({arch})"
        table.add_row("Version", version_str)

    console.print(table)


def display_devices(devices, detailed=False, connections=None, completions=None):
    """Display devices in a formatted table."""
    console = Console()
    console.print()  # Add blank line
    console.print("[bold cyan]Remote Devices[/bold cyan]")

    if not devices:
        print("  (none)")
        return

    # Create table
    table = Table(
        show_header=True, header_style="bold cyan", show_lines=False, box=box.ROUNDED
    )
    table.add_column("Devices", style="bold yellow")
    table.add_column("Device ID", style="dim")
    table.add_column("Connection Status", justify="center")
    table.add_column("Sync Status")

    for device in devices:
        if not device or not isinstance(device, dict):
            continue
        name = device.get("name", "Unknown")
        device_id = device.get("deviceID", "")
        device_id_short = device_id[:7] + "..." if device_id else ""

        # Get connection status
        conn_status = ""
        sync_status = ""
        if connections and device_id in connections:
            conn = connections[device_id]
            if conn.get("paused"):
                conn_status = "[yellow]Paused[/yellow]"
            elif conn.get("connected"):
                conn_status = "[green]Connected[/green]"
                # Check if syncing
                if completions and device_id in completions:
                    comp = completions[device_id]
                    completion_pct = comp.get("completion", 100)
                    if completion_pct < 100:
                        # Show syncing progress
                        need_bytes = comp.get("needBytes", 0)
                        need_size = format_bytes(need_bytes)
                        sync_status = (
                            f"[cyan]Syncing {completion_pct:.0f}%[/cyan], {need_size}"
                        )
                    else:
                        sync_status = "[green]Up to Date[/green]"
            else:
                conn_status = "[red]Disconnected[/red]"
        else:
            conn_status = "[dim]Unknown[/dim]"

        table.add_row(name, device_id_short, conn_status, sync_status)

    # Print the table
    console.print(table)


def display_folders(
    folders,
    detailed=False,
    device_map=None,
    folder_statuses=None,
    local_device_id=None,
    device_completions=None,
):
    """
    Display folders in a formatted table.

    Args:
        folders: List of folder configs
        detailed: Show detailed info including folder IDs
        device_map: Dict mapping device IDs to device names (for resolving shared devices)
        folder_statuses: Dict mapping folder IDs to status info
        local_device_id: Local device ID to filter out from shared devices
        device_completions: Dict mapping (device_id, folder_id) tuples to completion info
    """
    console = Console()
    console.print("[bold cyan]Folders[/bold cyan]")

    if not folders:
        print("  (none)")
        return

    # Create table
    table = Table(
        show_header=True, header_style="bold cyan", show_lines=False, box=box.ROUNDED
    )
    table.add_column("Folders", style="bold")
    table.add_column("Devices", style="yellow")
    table.add_column("Sync Status", style="green")

    first_folder = True
    for folder in folders:
        if not folder or not isinstance(folder, dict):
            continue

        # Add section divider between folders
        if not first_folder:
            table.add_section()
        first_folder = False

        folder_id = folder.get("id", "")
        label = folder.get("label", folder_id)
        path = folder.get("path", "")
        devices = folder.get("devices", [])

        # Get devices to display (excluding local device)
        devices_to_show = []
        for d in devices:
            if d and isinstance(d, dict):
                dev_id = d.get("deviceID", "")
                if local_device_id and dev_id == local_device_id:
                    continue
                devices_to_show.append(d)

        # Build device info list
        device_rows = []
        for d in devices_to_show:
            dev_id = d.get("deviceID", "")

            # Get device name
            if device_map and dev_id in device_map:
                dev_name = device_map[dev_id]
            else:
                dev_name = dev_id[:7] + "..."

            # Get sync status
            sync_status = ""
            if device_completions and (dev_id, folder_id) in device_completions:
                comp = device_completions[(dev_id, folder_id)]
                need_items = comp.get("needItems", 0)
                need_bytes = comp.get("needBytes", 0)

                if need_items > 0:
                    items_str = f"{need_items:,} item{'s' if need_items != 1 else ''}"
                    bytes_str = format_bytes(need_bytes)
                    sync_status = f"[red]Out of Sync:[/red] {items_str}, ~{bytes_str}"
                else:
                    sync_status = "[green]Up to Date[/green]"

            device_rows.append((dev_name, sync_status))

        # Add rows: first row has label, second row has path, rest are empty
        if device_rows:
            # First row: folder label + first device
            table.add_row(label, device_rows[0][0], device_rows[0][1])
            # Second row: path + second device (or just path if only one device)
            if len(device_rows) > 1:
                table.add_row(
                    f"[dim]{path}[/dim]", device_rows[1][0], device_rows[1][1]
                )
            else:
                table.add_row(f"[dim]{path}[/dim]", "", "")
            # Remaining devices
            for idx in range(2, len(device_rows)):
                table.add_row("", device_rows[idx][0], device_rows[idx][1])
        else:
            # No devices to show
            table.add_row(label, "(none)", "")
            table.add_row(f"[dim]{path}[/dim]", "", "")

    # Print the table
    console.print(table)
