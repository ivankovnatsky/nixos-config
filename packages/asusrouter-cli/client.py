"""ASUS router connection wrapper around the asusrouter library."""

import sys
from typing import Any, Optional

import click

try:
    import aiohttp
    from asusrouter import AsusRouter
    from asusrouter.modules.data import AsusData
except ImportError as e:
    click.echo(f"Error: Required module not found: {e}", err=True)
    click.echo("This tool requires the 'asusrouter' package.", err=True)
    sys.exit(1)

from nvram_groups import NVRAM_GROUPS


ALL_DATA_TYPES = [member for member in AsusData]


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

        click.echo("Exporting AsusData types...", err=True)
        for data_type in ALL_DATA_TYPES:
            try:
                data = await self.router.async_get_data(data_type)
                all_data[data_type.value] = data
                click.echo(f"  ✓ {data_type.value}", err=True)
            except Exception as e:
                click.echo(f"  ✗ {data_type.value}: {e}", err=True)
                all_data[data_type.value] = {"error": str(e)}

        click.echo("\nExporting NVRAM groups...", err=True)
        nvram_data = {}
        for group_name, variables in NVRAM_GROUPS.items():
            try:
                data = await self.query_nvram(variables)
                nvram_data[group_name] = data
                click.echo(f"  ✓ nvram/{group_name}", err=True)
            except Exception as e:
                click.echo(f"  ✗ nvram/{group_name}: {e}", err=True)
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


def make_client(hostname, username, password, use_ssl, port) -> AsusRouterClient:
    return AsusRouterClient(
        hostname=hostname,
        username=username,
        password=password,
        use_ssl=use_ssl,
        port=port,
    )
