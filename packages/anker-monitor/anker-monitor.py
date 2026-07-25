#!/usr/bin/env python3
"""Monitor an Anker Solix C1000 Gen 2 (A1763) and trigger graceful host shutdowns.

Architecture (read-only against Anker):

    anker-monitor serve   -- one process, one Anker cloud login. Reads the C1000
                             battery SOC over Anker's cloud MQTT stream and exposes
                             it as GET /soc on the LAN.
    anker-monitor check   -- runs on each protected host. Polls the /soc endpoint;
                             when SOC stays at/below the threshold it shuts the host
                             down cleanly (before the C1000's own ~15% AC cutoff).

The C1000 Gen 2 is a *standalone* PPS: the Anker cloud REST cache carries no SOC or
power for it, so realtime data is only available via the cloud MQTT stream. "MQTT"
here is a protocol to Anker's cloud broker over the internet -- no local broker or
hardware is involved.

get_status() only returns data while the device is subscribed AND a realtime trigger
is active; message_poller() handles both (subscribe + auto re-trigger).

serve credentials come from the environment: ANKERUSER, ANKERPASSWORD, ANKERCOUNTRY.
"""

import asyncio
import json
import logging
import os
import subprocess

import click
from aiohttp import ClientSession, ClientTimeout, web
from anker_solix_api.api import AnkerSolixApi
from anker_solix_api.mqtt_factory import SolixMqttDeviceFactory

LOG = logging.getLogger("anker-monitor")

DEFAULT_PN = "A1763"  # C1000 Gen 2
TRIGGER_TIMEOUT = 300  # seconds the device keeps publishing before re-trigger


def _creds():
    try:
        return (
            os.environ["ANKERUSER"],
            os.environ["ANKERPASSWORD"],
            os.environ.get("ANKERCOUNTRY", "US"),
        )
    except KeyError as err:
        raise click.ClickException(f"missing env var {err}")


def _match_device(api, pn, sn):
    for serial, dev in api.devices.items():
        if sn and serial == sn:
            return serial
        if not sn and dev.get("device_pn") == pn:
            return serial
    return None


def _to_num(value):
    """Coerce a library value (SOC/power are numeric strings) to float, or None."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


async def _serve(host, port, pn, sn, max_age):
    user, password, country = _creds()
    async with ClientSession() as websession:
        api = AnkerSolixApi(user, password, country, websession, LOG)
        serial, device, poller = await _connect(api, pn, sn)

        # Track when the device's data last changed, to detect a stalled stream.
        seen = {"marker": None, "at": 0.0}

        async def soc(_request):
            st = device.get_status()
            marker = st.get("msg_timestamp") or st.get("utc_timestamp") or st.get("last_update")
            now = asyncio.get_running_loop().time()
            if marker != seen["marker"]:
                seen["marker"] = marker
                seen["at"] = now
            age = now - seen["at"] if seen["marker"] is not None else None
            soc_num = _to_num(st.get("battery_soc"))
            stale = age is None or age > max_age
            return web.json_response(
                {
                    # null when stale so the checker treats it as unavailable, not a reading
                    "soc": None if stale or soc_num is None else int(soc_num),
                    "ac_w": _to_num(st.get("ac_output_power")),
                    "ac_on": bool(st.get("ac_output_power_switch")),
                    "sn": serial,
                    "age": None if age is None else round(age, 1),
                    "stale": stale,
                    "ts": st.get("last_update") or st.get("utc_timestamp"),
                }
            )

        app = web.Application()
        app.router.add_get("/soc", soc)
        app.router.add_get("/healthz", lambda _r: web.Response(text="ok"))
        runner = web.AppRunner(app)
        await runner.setup()
        await web.TCPSite(runner, host, port).start()
        LOG.warning("serving SOC for %s on http://%s:%s/soc", serial, host, port)

        try:
            # Tie lifecycle to the poller: if it stops or errors, exit so the service
            # manager restarts us instead of serving null/stale data indefinitely.
            await poller
        finally:
            poller.cancel()
            api.stopMqttSession()
            await runner.cleanup()


async def _check(url, threshold, debounce, interval, shutdown, shutdown_cmd):
    below = 0
    timeout = ClientTimeout(total=10)
    async with ClientSession(timeout=timeout) as s:
        while True:
            try:
                async with s.get(url) as resp:
                    resp.raise_for_status()
                    data = await resp.json()
                soc = _to_num(data.get("soc"))
            except Exception as err:  # noqa: BLE001 - unreachable endpoint must not shut down
                LOG.warning("soc endpoint unreachable (%s); holding", err)
                below = 0
                await asyncio.sleep(interval)
                continue

            if soc is None or not 0 <= soc <= 100:
                # missing / stale / malformed value -> unavailable, never act on it
                if data.get("soc") is not None:
                    LOG.warning("ignoring invalid soc=%r; holding", data.get("soc"))
                below = 0
            elif soc <= threshold:
                below += 1
                click.echo(f"soc={soc:g}% <= {threshold}% ({below}/{debounce})")
                if below >= debounce:
                    if not shutdown:
                        click.echo(
                            f"threshold sustained; would run: {shutdown_cmd} "
                            "(pass --shutdown to enable)"
                        )
                        return
                    click.echo(f"threshold sustained; running: {shutdown_cmd}")
                    result = subprocess.run(shutdown_cmd, shell=True)
                    if result.returncode == 0:
                        return
                    LOG.error(
                        "shutdown command failed (exit %s); retrying next poll",
                        result.returncode,
                    )
            else:
                below = 0
            await asyncio.sleep(interval)


@click.group()
@click.option("-v", "--verbose", is_flag=True)
def cli(verbose):
    """Monitor an Anker Solix C1000 and shut down hosts on low battery."""
    logging.basicConfig(level=logging.INFO if verbose else logging.WARNING)


@cli.command()
@click.option("--host", default="0.0.0.0", show_default=True)
@click.option("--port", type=int, default=8787, show_default=True)
@click.option("--pn", default=DEFAULT_PN, show_default=True, help="Device product number to match.")
@click.option("--sn", default=None, help="Exact device serial (overrides --pn).")
@click.option("--max-age", type=int, default=60, show_default=True,
              help="Report soc as null once the MQTT stream stalls this many seconds.")
def serve(host, port, pn, sn, max_age):
    """Read C1000 SOC over Anker cloud MQTT and expose GET /soc."""
    try:
        asyncio.run(_serve(host, port, pn, sn, max_age))
    except KeyboardInterrupt:
        pass


@cli.command()
@click.option("--url", default="http://localhost:8787/soc", show_default=True)
@click.option("--threshold", type=int, default=30, show_default=True,
              help="Shut down when SOC is at/below this percent.")
@click.option("--debounce", type=int, default=2, show_default=True,
              help="Consecutive sub-threshold polls required before acting.")
@click.option("--interval", type=int, default=30, show_default=True,
              help="Seconds between polls.")
@click.option("--shutdown", is_flag=True, help="Actually run the shutdown command.")
@click.option("--shutdown-cmd", default="shutdown -h now", show_default=True)
def check(url, threshold, debounce, interval, shutdown, shutdown_cmd):
    """Poll a serve endpoint and shut this host down on sustained low SOC."""
    try:
        asyncio.run(_check(url, threshold, debounce, interval, shutdown, shutdown_cmd))
    except KeyboardInterrupt:
        pass


async def _connect(api, pn, sn):
    """Discover the device and start a subscribed, auto-triggered MQTT session."""
    await api.get_bind_devices()
    serial = _match_device(api, pn, sn)
    if not serial:
        raise click.ClickException(f"no device matching pn={pn} sn={sn or '*'} on this account")
    device = SolixMqttDeviceFactory(api, serial).create_device()
    session = await api.startMqttSession()
    if session is None:
        raise click.ClickException("failed to start Anker MQTT session")
    topics = {f"{session.get_topic_prefix(api.devices[serial])}#"}
    poller = asyncio.create_task(session.message_poller(topics, {serial}, timeout=TRIGGER_TIMEOUT))
    return serial, device, poller


async def _await_status(device, wait):
    """Poll the MQTT cache until battery_soc is populated or timeout."""
    st = device.get_status()
    for _ in range(max(1, wait // 5)):
        if st.get("battery_soc") is not None:
            return st
        await asyncio.sleep(5)
        st = device.get_status()
    return st


@cli.command()
@click.option("--pn", default=DEFAULT_PN, show_default=True)
@click.option("--sn", default=None, help="Exact device serial (overrides --pn).")
@click.option("--wait", type=int, default=60, show_default=True,
              help="Max seconds to wait for the first realtime message.")
@click.option("--json", "as_json", is_flag=True, help="Print the full status dict as JSON.")
def status(pn, sn, wait, as_json):
    """One-shot: print the full realtime status the device publishes."""
    async def run():
        user, password, country = _creds()
        async with ClientSession() as websession:
            api = AnkerSolixApi(user, password, country, websession, LOG)
            _serial, device, poller = await _connect(api, pn, sn)
            try:
                st = await _await_status(device, wait)
                if not st:
                    raise click.ClickException("no data received (device asleep or trigger not honored)")
                if as_json:
                    click.echo(json.dumps(st, indent=2, default=str, sort_keys=True))
                else:
                    for key in sorted(st):
                        click.echo(f"{key} = {st[key]}")
            finally:
                poller.cancel()
                api.stopMqttSession()

    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass


@cli.command()
@click.option("--pn", default=None, help="Filter by product number.")
def devices(pn):
    """List devices on the account (debug; verify creds/region and find the SN)."""
    async def run():
        user, password, country = _creds()
        async with ClientSession() as websession:
            api = AnkerSolixApi(user, password, country, websession, LOG)
            await api.update_sites()
            await api.get_bind_devices()
            if not api.devices:
                click.echo(
                    f"no devices for this account on region {country!r} "
                    "(check ANKERCOUNTRY and that the account owns the device)"
                )
                return
            for serial, dev in api.devices.items():
                if pn and dev.get("device_pn") != pn:
                    continue
                click.echo(
                    f"{serial}  pn={dev.get('device_pn')}  type={dev.get('type')}  "
                    f"name={dev.get('name') or dev.get('alias')}"
                )

    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    cli()
