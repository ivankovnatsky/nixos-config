#!/usr/bin/env python3
"""
ASUS Router management tool.
Supports data export, NVRAM queries, and WAN DNS configuration
using the asusrouter library.
"""

import sys
import json
import argparse
import asyncio
import os
from typing import Any, Optional

try:
    import aiohttp
    from asusrouter import AsusRouter
    from asusrouter.modules.data import AsusData
except ImportError as e:
    print(f"Error: Required module not found: {e}", file=sys.stderr)
    print("This tool requires the 'asusrouter' package.", file=sys.stderr)
    sys.exit(1)

ALL_DATA_TYPES = [member for member in AsusData]

NVRAM_GROUPS = {
    "dhcp": [
        "dhcp_enable_x",
        "dhcp_start",
        "dhcp_end",
        "dhcp_lease",
        "dhcp_gateway_x",
        "dhcp_dns1_x",
        "dhcp_dns2_x",
        "dhcp_wins_x",
        "dhcp_static_x",
        "dhcp_staticlist",
    ],
    "lan": [
        "lan_ipaddr",
        "lan_netmask",
        "lan_gateway",
        "lan_proto",
        "lan_dnsenable_x",
        "lan_dns1_x",
        "lan_dns2_x",
        "lan_domain",
        "lan_stp",
        "lan_hostname",
    ],
    "wan": [
        "wan_enable",
        "wan_unit",
        "wan_proto",
        "wan0_proto",
        "wan0_ipaddr_x",
        "wan0_netmask_x",
        "wan0_gateway_x",
        "wan0_dns1_x",
        "wan0_dns2_x",
        "wan0_dnsenable_x",
        "wan0_pppoe_username",
        "wan0_hwaddr_x",
        "wan1_proto",
        "wan1_ipaddr_x",
        "wan1_netmask_x",
        "wan1_gateway_x",
        "wan1_dns1_x",
        "wan1_dns2_x",
        "wan1_dnsenable_x",
        "wans_dualwan",
        "wans_mode",
    ],
    "wlan_2g": [
        "wl0_ssid",
        "wl0_auth_mode_x",
        "wl0_crypto",
        "wl0_wpa_psk",
        "wl0_channel",
        "wl0_chanspec",
        "wl0_bw",
        "wl0_nmode_x",
        "wl0_closed",
        "wl0_macmode",
        "wl0_maclist_x",
        "wl0_radius_ipaddr",
        "wl0_radius_port",
        "wl0_radius_key",
        "wl0_wep_x",
        "wl0_key",
        "wl0_txpower",
    ],
    "wlan_5g": [
        "wl1_ssid",
        "wl1_auth_mode_x",
        "wl1_crypto",
        "wl1_wpa_psk",
        "wl1_channel",
        "wl1_chanspec",
        "wl1_bw",
        "wl1_nmode_x",
        "wl1_closed",
        "wl1_macmode",
        "wl1_maclist_x",
        "wl1_txpower",
    ],
    "wlan_5g2": [
        "wl2_ssid",
        "wl2_auth_mode_x",
        "wl2_crypto",
        "wl2_wpa_psk",
        "wl2_channel",
        "wl2_chanspec",
        "wl2_bw",
        "wl2_nmode_x",
        "wl2_closed",
        "wl2_txpower",
    ],
    "wlan_6g": [
        "wl3_ssid",
        "wl3_auth_mode_x",
        "wl3_crypto",
        "wl3_wpa_psk",
        "wl3_channel",
        "wl3_chanspec",
        "wl3_bw",
        "wl3_nmode_x",
        "wl3_closed",
        "wl3_txpower",
    ],
    "guest_wlan": [
        "wl0.1_ssid",
        "wl0.1_auth_mode_x",
        "wl0.1_wpa_psk",
        "wl0.1_closed",
        "wl0.1_bss_enabled",
        "wl0.1_expire",
        "wl0.1_lanaccess",
        "wl1.1_ssid",
        "wl1.1_auth_mode_x",
        "wl1.1_wpa_psk",
        "wl1.1_closed",
        "wl1.1_bss_enabled",
        "wl1.1_expire",
        "wl1.1_lanaccess",
    ],
    "firewall": [
        "fw_enable_x",
        "fw_dos_x",
        "fw_log_x",
        "fw_pt_pptp",
        "fw_pt_l2tp",
        "fw_pt_ipsec",
        "fw_pt_rtsp",
        "fw_pt_h323",
        "fw_pt_sip",
        "misc_http_x",
        "misc_httpport_x",
        "misc_httpsport_x",
        "misc_ping_x",
    ],
    "port_forwarding": [
        "vts_enable_x",
        "vts_rulelist",
        "vts_ftpport",
        "autofw_enable_x",
        "autofw_rulelist",
    ],
    "ddns": [
        "ddns_enable_x",
        "ddns_server_x",
        "ddns_hostname_x",
        "ddns_username_x",
        "ddns_passwd_x",
        "ddns_wildcard_x",
        "ddns_ipaddr",
        "ddns_status",
        "ddns_return_code",
        "ddns_updated",
    ],
    "vpn": [
        "vpn_server_unit",
        "vpn_server_enable",
        "VPNServer_enable",
        "vpn_server_mode",
        "vpn_server_proto",
        "vpn_server_port",
        "vpn_server_if",
        "vpn_server_cipher",
        "vpn_server_comp",
        "vpn_server_crypt",
        "vpn_server_hmac",
        "vpn_server_dhcp",
        "vpn_server_sn",
        "vpn_server_nm",
        "vpn_server_local",
        "vpn_server_remote",
        "vpn_server_plan",
        "vpn_server_rgw",
        "vpn_client_unit",
        "vpn_client1_state",
        "vpn_client2_state",
    ],
    "wireguard": [
        "wgs_enable",
        "wgs_addr",
        "wgs_port",
        "wgs_dns",
        "wgs_lanaccess",
        "wgs_nat6",
        "wgs_psk",
        "wgs_alive",
        "wgs_priv",
        "wgs_pub",
    ],
    "usb": [
        "usb_usb3",
        "usb_idle_timeout",
        "usb_idle_exclude",
        "usb_path1_speed",
        "usb_path2_speed",
    ],
    "system": [
        "productid",
        "firmver",
        "buildno",
        "extendno",
        "model",
        "serial_no",
        "label_mac",
        "lan_hwaddr",
        "wan_hwaddr",
        "time_zone",
        "time_zone_dst",
        "ntp_server0",
        "ntp_server1",
        "login_ip",
        "http_enable",
        "https_lanport",
        "http_lanport",
        "telnetd_enable",
        "sshd_enable",
        "sshd_port",
        "preferred_lang",
    ],
    "aimesh": [
        "cfg_master",
        "cfg_group",
        "cfg_sdn_t",
        "amas_wlc0_ssid",
        "amas_wlc1_ssid",
        "amas_wlc2_ssid",
    ],
    "parental_control": [
        "MULTIFILTER_ALL",
        "MULTIFILTER_ENABLE",
        "MULTIFILTER_MAC",
        "MULTIFILTER_DEVICENAME",
        "MULTIFILTER_MACFILTER_DA498",
    ],
    "qos": [
        "qos_enable",
        "qos_type",
        "qos_obw",
        "qos_ibw",
        "qos_orules",
        "qos_rulelist",
        "bwdpi_app_rulelist",
    ],
    "dns_filtering": [
        "dnsfilter_enable_x",
        "dnsfilter_mode",
        "dnsfilter_rulelist",
        "dnsfilter_custom1",
        "dnsfilter_custom2",
        "dnsfilter_custom3",
    ],
    "ipv6": [
        "ipv6_service",
        "ipv6_ifdev",
        "ipv6_prefix",
        "ipv6_prefix_length",
        "ipv6_dhcp_pd",
        "ipv6_rtr_addr",
        "ipv6_prefix_len_wan",
        "ipv6_gateway",
        "ipv6_dns1",
        "ipv6_dns2",
        "ipv6_dns3",
        "ipv6_autoconf_type",
        "ipv6_dhcp_start",
        "ipv6_dhcp_end",
        "ipv6_dhcp_lifetime",
    ],
    "misc": [
        "misc_http_x",
        "misc_httpport_x",
        "misc_httpsport_x",
        "misc_ping_x",
        "log_ipaddr",
        "log_port",
        "url_enable_x",
        "url_rulelist",
        "keyword_enable_x",
        "keyword_rulelist",
    ],
}


class AsusRouterClient:
    def __init__(
        self,
        hostname: str,
        username: str,
        password: str,
        use_ssl: bool = False,
        port: Optional[int] = None,
    ):
        self.hostname = hostname
        self.username = username
        self.password = password
        self.use_ssl = use_ssl
        self.port = port
        self.router: Optional[AsusRouter] = None
        self.session: Optional[aiohttp.ClientSession] = None

    async def connect(self):
        """Connect to the router."""
        self.session = aiohttp.ClientSession()

        self.router = AsusRouter(
            hostname=self.hostname,
            username=self.username,
            password=self.password,
            use_ssl=self.use_ssl,
            port=self.port,
            session=self.session,
        )

        try:
            connected = await self.router.async_connect()
            if not connected:
                raise Exception("Failed to connect to router")
            return True
        except Exception as e:
            await self.cleanup()
            raise Exception(f"Connection failed: {e}")

    async def cleanup(self):
        """Clean up connections."""
        if self.router:
            await self.router.async_disconnect()
        if self.session:
            await self.session.close()

    async def get_data(self, data_type: AsusData) -> dict[str, Any]:
        """Get a specific data type."""
        if not self.router:
            raise Exception("Not connected to router")
        data = await self.router.async_get_data(data_type)
        return data or {}

    async def query_nvram(self, variables: list[str]) -> dict[str, Any]:
        """Query specific NVRAM variables."""
        if not self.router:
            raise Exception("Not connected to router")

        request = ";".join(f"nvram_get({v})" for v in variables)
        return await self.router.async_api_hook(request)

    async def export_all_data(self) -> dict[str, Any]:
        """Export all available router data (AsusData + NVRAM)."""
        if not self.router:
            raise Exception("Not connected to router")

        all_data = {}

        print("Exporting AsusData types...", file=sys.stderr)
        for data_type in ALL_DATA_TYPES:
            try:
                data = await self.router.async_get_data(data_type)
                all_data[data_type.value] = data
                print(f"  ✓ {data_type.value}", file=sys.stderr)
            except Exception as e:
                print(f"  ✗ {data_type.value}: {e}", file=sys.stderr)
                all_data[data_type.value] = {"error": str(e)}

        print("\nExporting NVRAM groups...", file=sys.stderr)
        nvram_data = {}
        for group_name, variables in NVRAM_GROUPS.items():
            try:
                data = await self.query_nvram(variables)
                nvram_data[group_name] = data
                print(f"  ✓ nvram/{group_name}", file=sys.stderr)
            except Exception as e:
                print(f"  ✗ nvram/{group_name}: {e}", file=sys.stderr)
                nvram_data[group_name] = {"error": str(e)}
        all_data["nvram"] = nvram_data

        return all_data

    async def set_wan_dns(
        self, dns_servers: list[str], wan_unit: int = 0
    ) -> dict[str, Any]:
        if not self.router:
            raise Exception("Not connected to router")

        if len(dns_servers) > 2:
            raise ValueError("Maximum 2 DNS servers allowed (primary and secondary)")

        import ipaddress

        for dns in dns_servers:
            try:
                ipaddress.ip_address(dns)
            except ValueError:
                raise ValueError(f"Invalid IP address: {dns}")

        dns1 = dns_servers[0] if len(dns_servers) >= 1 else ""
        dns2 = dns_servers[1] if len(dns_servers) >= 2 else ""

        try:
            from asusrouter.modules.endpoint import EndpointControl

            commands = {
                f"wan{wan_unit}_dns1_x": dns1,
                f"wan{wan_unit}_dns2_x": dns2,
                f"wan{wan_unit}_dnsenable_x": "1",
                "action_mode": "apply",
            }

            response = await self.router.async_api_command(
                commands=commands, endpoint=EndpointControl.COMMAND
            )

            if not response or response.get("modify") != "1":
                restart_commands = {
                    "action_mode": "apply",
                    "rc_service": f"restart_wan_dns {wan_unit}",
                }
                await self.router.async_api_command(
                    commands=restart_commands, endpoint=EndpointControl.COMMAND
                )

            modify_result = response.get("modify")
            if modify_result == "1" or modify_result == 1:
                return {
                    "status": "success",
                    "message": "DNS servers updated successfully",
                    "dns": {"primary": dns1, "secondary": dns2, "wan_unit": wan_unit},
                    "response": response,
                }
            else:
                return {
                    "status": "unknown",
                    "message": "Command sent but modification status unclear",
                    "dns": {"primary": dns1, "secondary": dns2, "wan_unit": wan_unit},
                    "response": response,
                }

        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to update DNS: {str(e)}",
                "dns": {"primary": dns1, "secondary": dns2, "wan_unit": wan_unit},
            }


def make_client(args) -> AsusRouterClient:
    return AsusRouterClient(
        hostname=args.hostname,
        username=args.username,
        password=args.password,
        use_ssl=args.use_ssl,
        port=args.port,
    )


def add_connection_args(parser):
    parser.add_argument(
        "--hostname", required=True, help="Router hostname or IP address"
    )
    parser.add_argument("--username", required=True, help="Router username")
    parser.add_argument("--password", required=True, help="Router password")
    parser.add_argument(
        "--use-ssl", action="store_true", help="Use HTTPS (default: HTTP)"
    )
    parser.add_argument(
        "--port",
        type=int,
        help="Router port (optional, default: 80 for HTTP, 443 for HTTPS)",
    )


def cmd_get(args):
    """Get a specific data type."""
    data_type_name = args.data_type.upper()
    try:
        data_type = AsusData(data_type_name.lower())
    except ValueError:
        try:
            data_type = AsusData[data_type_name]
        except KeyError:
            print(f"Error: Unknown data type '{args.data_type}'", file=sys.stderr)
            print(f"Available: {', '.join(d.value for d in AsusData)}", file=sys.stderr)
            sys.exit(1)

    async def _get():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)
            data = await client.get_data(data_type)
            print(json.dumps(data, indent=2, default=str))
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_get())


def cmd_get_wan(args):
    """Get WAN configuration command handler."""

    async def _get_wan():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)
            wan_info = await client.get_data(AsusData.WAN)
            if args.output:
                with open(args.output, "w") as f:
                    json.dump(wan_info, f, indent=2, default=str)
                print(f"WAN configuration saved to {args.output}")
            else:
                print(json.dumps(wan_info, indent=2, default=str))
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_get_wan())


def cmd_set_dns(args):
    """Set WAN DNS servers command handler."""

    async def _set_dns():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)
            dns_servers = [dns.strip() for dns in args.dns_servers.split(",")]
            if args.dry_run:
                print(
                    f"Dry-run: Would set DNS servers to: {dns_servers} (WAN unit: {args.wan_unit})"
                )
                return
            result = await client.set_wan_dns(dns_servers, wan_unit=args.wan_unit)
            print(json.dumps(result, indent=2))
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_set_dns())


def cmd_query_nvram(args):
    """Query specific NVRAM variables."""

    async def _query():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)

            variables = [v.strip() for v in args.variables.split(",")]
            data = await client.query_nvram(variables)
            print(json.dumps(data, indent=2, default=str))
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_query())


def cmd_export_nvram(args):
    """Export NVRAM groups."""

    async def _export():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)

            groups = (
                args.groups.split(",") if args.groups else list(NVRAM_GROUPS.keys())
            )

            all_data = {}
            for group_name in groups:
                group_name = group_name.strip()
                if group_name not in NVRAM_GROUPS:
                    print(f"  ✗ Unknown NVRAM group: {group_name}", file=sys.stderr)
                    continue
                try:
                    data = await client.query_nvram(NVRAM_GROUPS[group_name])
                    all_data[group_name] = data
                    print(f"  ✓ {group_name}", file=sys.stderr)
                except Exception as e:
                    print(f"  ✗ {group_name}: {e}", file=sys.stderr)
                    all_data[group_name] = {"error": str(e)}

            if args.output_dir:
                output_dir = args.output_dir
                if not os.path.exists(output_dir):
                    os.makedirs(output_dir)

                for group_name, data in all_data.items():
                    output_file = os.path.join(output_dir, f"nvram-{group_name}.json")
                    with open(output_file, "w") as f:
                        json.dump(data, f, indent=2, default=str)

                combined = os.path.join(output_dir, "nvram-all.json")
                with open(combined, "w") as f:
                    json.dump(all_data, f, indent=2, default=str)

                print(f"\n✓ NVRAM data saved to: {output_dir}", file=sys.stderr)
            else:
                print(json.dumps(all_data, indent=2, default=str))

        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_export())


def cmd_export_all(args):
    """Export all router configuration command handler."""

    async def _export_all():
        client = make_client(args)
        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)

            all_data = await client.export_all_data()

            output_dir = args.output_dir
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                print(f"Created directory: {output_dir}", file=sys.stderr)

            from datetime import datetime

            timestamp_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

            output_file = os.path.join(
                output_dir, f"router-config-{timestamp_str}.json"
            )
            with open(output_file, "w") as f:
                json.dump(all_data, f, indent=2, default=str)

            print(f"\n✓ All configuration exported to: {output_file}", file=sys.stderr)

            for data_type, data in all_data.items():
                if data_type == "nvram":
                    nvram_dir = os.path.join(output_dir, "nvram")
                    if not os.path.exists(nvram_dir):
                        os.makedirs(nvram_dir)
                    for group_name, group_data in data.items():
                        individual_file = os.path.join(nvram_dir, f"{group_name}.json")
                        with open(individual_file, "w") as f:
                            json.dump(group_data, f, indent=2, default=str)
                else:
                    individual_file = os.path.join(output_dir, f"{data_type}.json")
                    with open(individual_file, "w") as f:
                        json.dump(data, f, indent=2, default=str)

            print(f"✓ Individual data files saved to: {output_dir}", file=sys.stderr)

        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_export_all())


def cmd_list_types(args):
    """List available data types and NVRAM groups."""
    print("AsusData types:")
    for d in AsusData:
        print(f"  {d.value}")
    print(f"\nNVRAM groups ({len(NVRAM_GROUPS)}):")
    for group, variables in NVRAM_GROUPS.items():
        print(f"  {group} ({len(variables)} variables)")


def main():
    parser = argparse.ArgumentParser(description="ASUS Router management tool")

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # List available types
    subparsers.add_parser(
        "list-types", help="List available data types and NVRAM groups"
    )

    # Get specific data type
    get_parser = subparsers.add_parser("get", help="Get a specific AsusData type")
    add_connection_args(get_parser)
    get_parser.add_argument(
        "data_type", help=f"Data type ({', '.join(d.value for d in AsusData)})"
    )

    # Get WAN command
    get_wan_parser = subparsers.add_parser(
        "get-wan", help="Get current WAN configuration (including DNS)"
    )
    add_connection_args(get_wan_parser)
    get_wan_parser.add_argument(
        "--output", help="Output file for WAN configuration (default: stdout)"
    )

    # Set DNS command
    set_dns_parser = subparsers.add_parser("set-dns", help="Set WAN DNS servers")
    add_connection_args(set_dns_parser)
    set_dns_parser.add_argument(
        "--dns-servers",
        required=True,
        help="Comma-separated DNS server IPs (e.g., '1.1.1.1,1.0.0.1')",
    )
    set_dns_parser.add_argument(
        "--wan-unit", type=int, default=0, help="WAN unit number (default: 0)"
    )
    set_dns_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    # Query NVRAM command
    nvram_parser = subparsers.add_parser(
        "query-nvram", help="Query specific NVRAM variables"
    )
    add_connection_args(nvram_parser)
    nvram_parser.add_argument(
        "variables",
        help="Comma-separated NVRAM variable names (e.g., 'dhcp_start,dhcp_end,lan_ipaddr')",
    )

    # Export NVRAM command
    export_nvram_parser = subparsers.add_parser(
        "export-nvram", help="Export NVRAM configuration groups"
    )
    add_connection_args(export_nvram_parser)
    export_nvram_parser.add_argument(
        "--groups",
        help=f"Comma-separated group names (default: all). Available: {', '.join(NVRAM_GROUPS.keys())}",
    )
    export_nvram_parser.add_argument(
        "--output-dir",
        help="Output directory (default: stdout)",
    )

    # Export all configuration command
    export_all_parser = subparsers.add_parser(
        "export-all", help="Export all router configuration (AsusData + NVRAM)"
    )
    add_connection_args(export_all_parser)
    export_all_parser.add_argument(
        "--output-dir",
        required=True,
        help="Output directory for configuration backup files",
    )

    args = parser.parse_args()

    commands = {
        "list-types": cmd_list_types,
        "get": cmd_get,
        "get-wan": cmd_get_wan,
        "set-dns": cmd_set_dns,
        "query-nvram": cmd_query_nvram,
        "export-nvram": cmd_export_nvram,
        "export-all": cmd_export_all,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
