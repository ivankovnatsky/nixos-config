#!/usr/bin/env python3
"""
ASUS Router management tool.
Supports WAN DNS configuration management using the asusrouter library.
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

    async def get_wan_info(self) -> dict[str, Any]:
        """Get WAN information including DNS configuration."""
        if not self.router:
            raise Exception("Not connected to router")

        try:
            wan_data = await self.router.async_get_data(AsusData.WAN)
            return wan_data or {}
        except Exception as e:
            raise Exception(f"Failed to get WAN data: {e}")

    async def export_all_data(self) -> dict[str, Any]:
        """Export all available router configuration data."""
        if not self.router:
            raise Exception("Not connected to router")

        all_data = {}
        data_types = [
            AsusData.AIMESH,
            AsusData.AURA,
            AsusData.BOOTTIME,
            AsusData.CLIENTS,
            AsusData.CPU,
            AsusData.DDNS,
            AsusData.DEVICEMAP,
            AsusData.DSL,
            AsusData.FIRMWARE,
            AsusData.FIRMWARE_NOTE,
            AsusData.FLAGS,
            AsusData.GWLAN,
            AsusData.LED,
            AsusData.NETWORK,
            AsusData.NODE_INFO,
            AsusData.OPENVPN,
            AsusData.OPENVPN_CLIENT,
            AsusData.OPENVPN_SERVER,
            AsusData.PARENTAL_CONTROL,
            AsusData.PING,
            AsusData.PORT_FORWARDING,
            AsusData.PORTS,
            AsusData.RAM,
            AsusData.SPEEDTEST,
            AsusData.SPEEDTEST_RESULT,
            AsusData.SYSINFO,
            AsusData.SYSTEM,
            AsusData.TEMPERATURE,
            AsusData.VPNC,
            AsusData.VPNC_CLIENTLIST,
            AsusData.WAN,
            AsusData.WIREGUARD,
            AsusData.WIREGUARD_CLIENT,
            AsusData.WIREGUARD_SERVER,
            AsusData.WLAN,
        ]

        for data_type in data_types:
            try:
                data = await self.router.async_get_data(data_type)
                all_data[data_type.value] = data
                print(f"  ✓ {data_type.value}", file=sys.stderr)
            except Exception as e:
                print(f"  ✗ {data_type.value}: {e}", file=sys.stderr)
                all_data[data_type.value] = {"error": str(e)}

        return all_data

    async def set_wan_dns(
        self, dns_servers: list[str], wan_unit: int = 0
    ) -> dict[str, Any]:
        """
        Set WAN DNS servers using the router's API.

        Args:
            dns_servers: List of DNS server IPs (up to 2: primary and secondary)
            wan_unit: WAN unit number (default: 0)

        Returns:
            Result dictionary with status and message
        """
        if not self.router:
            raise Exception("Not connected to router")

        if len(dns_servers) > 2:
            raise ValueError("Maximum 2 DNS servers allowed (primary and secondary)")

        # Validate DNS server IPs
        import ipaddress

        for dns in dns_servers:
            try:
                ipaddress.ip_address(dns)
            except ValueError:
                raise ValueError(f"Invalid IP address: {dns}")

        # Prepare DNS configuration
        dns1 = dns_servers[0] if len(dns_servers) >= 1 else ""
        dns2 = dns_servers[1] if len(dns_servers) >= 2 else ""

        try:
            # Import the endpoint type
            from asusrouter.modules.endpoint import EndpointControl

            # Build the command parameters
            # For ASUS routers, DNS settings use wan{unit}_dns{1,2}_x parameters
            # Try multiple approaches to set DNS

            # Approach 1: Use applyapp.cgi (COMMAND endpoint)
            commands = {
                f"wan{wan_unit}_dns1_x": dns1,
                f"wan{wan_unit}_dns2_x": dns2,
                f"wan{wan_unit}_dnsenable_x": "1",
                "action_mode": "apply",
            }

            # Send the command using applyapp.cgi endpoint (COMMAND)
            response = await self.router.async_api_command(
                commands=commands, endpoint=EndpointControl.COMMAND
            )

            # If that didn't work, try restarting DNS service
            if not response or response.get("modify") != "1":
                restart_commands = {
                    "action_mode": "apply",
                    "rc_service": f"restart_wan_dns {wan_unit}",
                }
                await self.router.async_api_command(
                    commands=restart_commands, endpoint=EndpointControl.COMMAND
                )

            # Check if the command was successful
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


def cmd_get_wan(args):
    """Get WAN configuration command handler."""

    async def _get_wan():
        client = AsusRouterClient(
            hostname=args.hostname,
            username=args.username,
            password=args.password,
            use_ssl=args.use_ssl,
            port=args.port,
        )

        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)

            wan_info = await client.get_wan_info()

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
        client = AsusRouterClient(
            hostname=args.hostname,
            username=args.username,
            password=args.password,
            use_ssl=args.use_ssl,
            port=args.port,
        )

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


def cmd_export_all(args):
    """Export all router configuration command handler."""

    async def _export_all():
        client = AsusRouterClient(
            hostname=args.hostname,
            username=args.username,
            password=args.password,
            use_ssl=args.use_ssl,
            port=args.port,
        )

        try:
            await client.connect()
            print("Connected to router successfully", file=sys.stderr)
            print("Exporting all configuration data...", file=sys.stderr)

            all_data = await client.export_all_data()

            output_dir = args.output_dir
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                print(f"Created directory: {output_dir}", file=sys.stderr)

            timestamp = asyncio.get_event_loop().time()
            from datetime import datetime
            timestamp_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

            output_file = os.path.join(output_dir, f"router-config-{timestamp_str}.json")
            with open(output_file, "w") as f:
                json.dump(all_data, f, indent=2, default=str)

            print(f"\n✓ All configuration exported to: {output_file}", file=sys.stderr)

            for data_type, data in all_data.items():
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


def main():
    parser = argparse.ArgumentParser(
        description="ASUS Router management tool for WAN DNS configuration"
    )

    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Command to execute"
    )

    # Get WAN command
    get_wan_parser = subparsers.add_parser(
        "get-wan", help="Get current WAN configuration (including DNS)"
    )
    get_wan_parser.add_argument(
        "--hostname", required=True, help="Router hostname or IP address"
    )
    get_wan_parser.add_argument("--username", required=True, help="Router username")
    get_wan_parser.add_argument("--password", required=True, help="Router password")
    get_wan_parser.add_argument(
        "--use-ssl", action="store_true", help="Use HTTPS (default: HTTP)"
    )
    get_wan_parser.add_argument("--port", type=int, help="Router port (optional, default: 80 for HTTP, 443 for HTTPS)")
    get_wan_parser.add_argument(
        "--output", help="Output file for WAN configuration (default: stdout)"
    )

    # Set DNS command
    set_dns_parser = subparsers.add_parser("set-dns", help="Set WAN DNS servers")
    set_dns_parser.add_argument(
        "--hostname", required=True, help="Router hostname or IP address"
    )
    set_dns_parser.add_argument("--username", required=True, help="Router username")
    set_dns_parser.add_argument("--password", required=True, help="Router password")
    set_dns_parser.add_argument(
        "--use-ssl", action="store_true", help="Use HTTPS (default: HTTP)"
    )
    set_dns_parser.add_argument("--port", type=int, help="Router port (optional, default: 80 for HTTP, 443 for HTTPS)")
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

    # Export all configuration command
    export_all_parser = subparsers.add_parser(
        "export-all", help="Export all router configuration data"
    )
    export_all_parser.add_argument(
        "--hostname", required=True, help="Router hostname or IP address"
    )
    export_all_parser.add_argument("--username", required=True, help="Router username")
    export_all_parser.add_argument("--password", required=True, help="Router password")
    export_all_parser.add_argument(
        "--use-ssl", action="store_true", help="Use HTTPS (default: HTTP)"
    )
    export_all_parser.add_argument("--port", type=int, help="Router port (optional, default: 80 for HTTP, 443 for HTTPS)")
    export_all_parser.add_argument(
        "--output-dir",
        required=True,
        help="Output directory for configuration backup files",
    )

    args = parser.parse_args()

    if args.command == "get-wan":
        cmd_get_wan(args)
    elif args.command == "set-dns":
        cmd_set_dns(args)
    elif args.command == "export-all":
        cmd_export_all(args)


if __name__ == "__main__":
    main()
