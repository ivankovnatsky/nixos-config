"""Click subcommands for asusrouter-cli."""

import asyncio
import json
import os
import sys

import click

from client import AsusData, make_client
from nvram_groups import NVRAM_GROUPS


def connection_options(f):
    f = click.option("--hostname", required=True, help="Router hostname or IP address")(
        f
    )
    f = click.option("--username", required=True, help="Router username")(f)
    f = click.option("--password", required=True, help="Router password")(f)
    f = click.option("--use-ssl", is_flag=True, help="Use HTTPS (default: HTTP)")(f)
    f = click.option(
        "--port",
        type=int,
        default=None,
        help="Router port (optional, default: 80 for HTTP, 443 for HTTPS)",
    )(f)
    return f


@click.group()
def cli():
    """ASUS Router management tool."""


@cli.command("list-types")
def cmd_list_types():
    """List available data types and NVRAM groups."""
    click.echo("AsusData types:")
    for d in AsusData:
        click.echo(f"  {d.value}")
    click.echo(f"\nNVRAM groups ({len(NVRAM_GROUPS)}):")
    for group, variables in NVRAM_GROUPS.items():
        click.echo(f"  {group} ({len(variables)} variables)")


@cli.command("get")
@connection_options
@click.argument("data_type")
def cmd_get(hostname, username, password, use_ssl, port, data_type):
    """Get a specific AsusData type."""
    data_type_name = data_type.upper()
    try:
        resolved_type = AsusData(data_type_name.lower())
    except ValueError:
        try:
            resolved_type = AsusData[data_type_name]
        except KeyError:
            click.echo(f"Error: Unknown data type '{data_type}'", err=True)
            click.echo(f"Available: {', '.join(d.value for d in AsusData)}", err=True)
            sys.exit(1)

    async def _get():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)
            data = await client.get_data(resolved_type)
            click.echo(json.dumps(data, indent=2, default=str))
        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_get())


@cli.command("get-wan")
@connection_options
@click.option(
    "--output",
    default=None,
    help="Output file for WAN configuration (default: stdout)",
)
def cmd_get_wan(hostname, username, password, use_ssl, port, output):
    """Get current WAN configuration (including DNS)."""

    async def _get_wan():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)
            wan_info = await client.get_data(AsusData.WAN)
            if output:
                with open(output, "w") as f:
                    json.dump(wan_info, f, indent=2, default=str)
                click.echo(f"WAN configuration saved to {output}")
            else:
                click.echo(json.dumps(wan_info, indent=2, default=str))
        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_get_wan())


@cli.command("set-dns")
@connection_options
@click.option(
    "--dns-servers",
    required=True,
    help="Comma-separated DNS server IPs (e.g., '1.1.1.1,1.0.0.1')",
)
@click.option(
    "--wan-unit",
    type=int,
    default=0,
    help="WAN unit number (default: 0)",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Show what would be changed without making changes",
)
def cmd_set_dns(
    hostname, username, password, use_ssl, port, dns_servers, wan_unit, dry_run
):
    """Set WAN DNS servers."""

    async def _set_dns():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)
            servers = [dns.strip() for dns in dns_servers.split(",")]
            if dry_run:
                click.echo(
                    f"Dry-run: Would set DNS servers to: {servers} (WAN unit: {wan_unit})"
                )
                return
            result = await client.set_wan_dns(servers, wan_unit=wan_unit)
            click.echo(json.dumps(result, indent=2))
        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_set_dns())


@cli.command("query-nvram")
@connection_options
@click.argument("variables")
def cmd_query_nvram(hostname, username, password, use_ssl, port, variables):
    """Query specific NVRAM variables.

    VARIABLES is a comma-separated list of NVRAM variable names
    (e.g., 'dhcp_start,dhcp_end,lan_ipaddr').
    """

    async def _query():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)
            var_list = [v.strip() for v in variables.split(",")]
            data = await client.query_nvram(var_list)
            click.echo(json.dumps(data, indent=2, default=str))
        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_query())


@cli.command("export-nvram")
@connection_options
@click.option(
    "--groups",
    default=None,
    help=f"Comma-separated group names (default: all). Available: {', '.join(NVRAM_GROUPS.keys())}",
)
@click.option(
    "--output-dir",
    default=None,
    help="Output directory (default: stdout)",
)
def cmd_export_nvram(hostname, username, password, use_ssl, port, groups, output_dir):
    """Export NVRAM configuration groups."""

    async def _export():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)

            group_list = groups.split(",") if groups else list(NVRAM_GROUPS.keys())

            all_data = {}
            for group_name in group_list:
                group_name = group_name.strip()
                if group_name not in NVRAM_GROUPS:
                    click.echo(f"  ✗ Unknown NVRAM group: {group_name}", err=True)
                    continue
                try:
                    data = await client.query_nvram(NVRAM_GROUPS[group_name])
                    all_data[group_name] = data
                    click.echo(f"  ✓ {group_name}", err=True)
                except Exception as e:
                    click.echo(f"  ✗ {group_name}: {e}", err=True)
                    all_data[group_name] = {"error": str(e)}

            if output_dir:
                if not os.path.exists(output_dir):
                    os.makedirs(output_dir)

                for group_name, data in all_data.items():
                    output_file = os.path.join(output_dir, f"nvram-{group_name}.json")
                    with open(output_file, "w") as f:
                        json.dump(data, f, indent=2, default=str)

                combined = os.path.join(output_dir, "nvram-all.json")
                with open(combined, "w") as f:
                    json.dump(all_data, f, indent=2, default=str)

                click.echo(f"\n✓ NVRAM data saved to: {output_dir}", err=True)
            else:
                click.echo(json.dumps(all_data, indent=2, default=str))

        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_export())


@cli.command("export-all")
@connection_options
@click.option(
    "--output-dir",
    required=True,
    help="Output directory for configuration backup files",
)
def cmd_export_all(hostname, username, password, use_ssl, port, output_dir):
    """Export all router configuration (AsusData + NVRAM)."""

    async def _export_all():
        client = make_client(hostname, username, password, use_ssl, port)
        try:
            await client.connect()
            click.echo("Connected to router successfully", err=True)

            all_data = await client.export_all_data()

            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                click.echo(f"Created directory: {output_dir}", err=True)

            from datetime import datetime

            timestamp_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

            output_file = os.path.join(
                output_dir, f"router-config-{timestamp_str}.json"
            )
            with open(output_file, "w") as f:
                json.dump(all_data, f, indent=2, default=str)

            click.echo(f"\n✓ All configuration exported to: {output_file}", err=True)

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

            click.echo(f"✓ Individual data files saved to: {output_dir}", err=True)

        except Exception as e:
            click.echo(f"Error: {e}", err=True)
            sys.exit(1)
        finally:
            await client.cleanup()

    asyncio.run(_export_all())
