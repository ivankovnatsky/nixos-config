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

try:  # shared repo helper on PYTHONPATH; notifications are best-effort
    from discord import send_discord
except Exception:  # noqa: BLE001 - never let a missing notifier break monitoring
    send_discord = None

LOG = logging.getLogger("anker-monitor")

DEFAULT_PN = "A1763"  # C1000 Gen 2
TRIGGER_TIMEOUT = 300  # seconds the device keeps publishing before re-trigger
BLIND_ALERT_AFTER = 2  # consecutive readless polls before alerting "can't read battery"


def _read_webhook(path):
    if not path:
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read().strip() or None
    except OSError as err:
        LOG.warning("cannot read webhook file %s: %s", path, err)
        return None


def _notify(webhook, message):
    """Best-effort Discord post for critical events only; never raises."""
    if not webhook or send_discord is None:
        return
    try:
        send_discord(webhook, message, source="anker-monitor")
    except Exception as err:  # noqa: BLE001 - a failed alert must not break the loop
        LOG.warning("discord notify failed: %s", err)


def _load_secrets(path):
    """Parse one secrets file holding email/password/country as key=value or key: value."""
    creds = {}
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            # Split on whichever delimiter comes first, so a value that itself
            # contains '=' (e.g. "password: ab=cd") is kept intact.
            positions = [line.find(d) for d in ("=", ":")]
            positions = [p for p in positions if p != -1]
            if not positions:
                continue
            idx = min(positions)
            key, value = line[:idx], line[idx + 1:]
            creds[key.strip().lower()] = value.strip().strip("\"'")
    user = creds.get("email") or creds.get("user") or creds.get("ankeruser")
    password = creds.get("password") or creds.get("ankerpassword")
    country = creds.get("country") or creds.get("ankercountry") or "US"
    if not user or not password:
        raise click.ClickException(f"{path}: missing email/password")
    return user, password, country


def _creds(secrets_file):
    """Resolve creds from a single secrets file, else the ANKER* env vars."""
    if secrets_file:
        return _load_secrets(secrets_file)
    user, password = os.environ.get("ANKERUSER"), os.environ.get("ANKERPASSWORD")
    if not user or not password:
        raise click.ClickException("provide --secrets-file (or ANKERUSER/ANKERPASSWORD)")
    return user, password, os.environ.get("ANKERCOUNTRY", "US")


def cred_options(func):
    """Single --secrets-file option for commands that reach Anker."""
    return click.option(
        "--secrets-file", type=click.Path(exists=True), default=None,
        help="File with email/password/country (key=value or key: value). Else ANKER* env.",
    )(func)


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


def _marker(st):
    return st.get("msg_timestamp") or st.get("utc_timestamp") or st.get("last_update")


async def _serve(host, port, pn, sn, max_age, creds):
    user, password, country = creds
    async with ClientSession() as websession:
        api = AnkerSolixApi(user, password, country, websession, LOG)
        serial, device, poller = await _connect(api, pn, sn)

        # Track when the device's data last changed, to detect a stalled stream.
        # Sampled by a background task (not lazily on request) so age reflects when
        # MQTT data actually arrived, even if no client polls for a long time.
        seen = {"marker": None, "at": 0.0}

        async def sampler():
            while True:
                marker = _marker(device.get_status())
                if marker is not None and marker != seen["marker"]:
                    seen["marker"] = marker
                    seen["at"] = asyncio.get_running_loop().time()
                await asyncio.sleep(5)

        async def soc(_request):
            st = device.get_status()
            now = asyncio.get_running_loop().time()
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

        sampler_task = asyncio.create_task(sampler())
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
            sampler_task.cancel()
            poller.cancel()
            api.stopMqttSession()
            await runner.cleanup()


async def _check(url, threshold, debounce, interval, shutdown, shutdown_cmd, webhook_file):
    webhook = _read_webhook(webhook_file)
    below = 0
    blind = 0  # consecutive polls with no usable reading
    blind_alerted = False
    acted = False  # sent the shutdown/would-shutdown alert for the current low episode
    timeout = ClientTimeout(total=10)
    async with ClientSession(timeout=timeout) as s:
        while True:
            raw = None
            unreachable = False
            try:
                async with s.get(url) as resp:
                    resp.raise_for_status()
                    data = await resp.json()
                raw = data.get("soc")
                soc = _to_num(raw)
            except Exception as err:  # noqa: BLE001 - unreachable endpoint must not shut down
                soc, unreachable, err_detail = None, True, str(err)

            valid = soc is not None and 0 <= soc <= 100

            # No usable reading -> hold (never shut down), and alert once if we stay blind.
            if not valid:
                if unreachable:
                    LOG.warning("soc endpoint unreachable; holding")
                    detail = f"endpoint unreachable ({err_detail})"
                else:
                    if raw is not None:
                        LOG.warning("ignoring invalid soc=%r; holding", raw)
                    detail = "invalid/stale reading"
                below = 0
                blind += 1
                if blind >= BLIND_ALERT_AFTER and not blind_alerted:
                    _notify(webhook, f"can't read battery SOC ({detail}); monitoring is blind")
                    blind_alerted = True
                await asyncio.sleep(interval)
                continue

            # Valid reading restored.
            if blind_alerted:
                _notify(webhook, f"battery SOC readable again ({soc:g}%)")
            blind = 0
            blind_alerted = False

            if soc <= threshold:
                below += 1
                click.echo(f"soc={soc:g}% <= {threshold}% ({below}/{debounce})")
                if below >= debounce:
                    if not shutdown:
                        # Dry-run: alert once, then keep polling (do NOT exit, or the
                        # supervisor would relaunch us and re-alert every restart).
                        if not acted:
                            click.echo(f"threshold sustained; would run: {shutdown_cmd}")
                            _notify(
                                webhook,
                                f"[DRY-RUN] battery {soc:g}% <= {threshold}% sustained; "
                                "would shut this host down (not armed)",
                            )
                            acted = True
                    else:
                        if not acted:
                            _notify(
                                webhook,
                                f"battery {soc:g}% <= {threshold}% sustained; "
                                "shutting this host down now",
                            )
                            acted = True
                        click.echo(f"threshold sustained; running: {shutdown_cmd}")
                        result = subprocess.run(shutdown_cmd, shell=True)
                        if result.returncode != 0:
                            LOG.error(
                                "shutdown command failed (exit %s); retrying next poll",
                                result.returncode,
                            )
            else:
                below = 0
                acted = False  # recovered above threshold; re-arm alerting
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
@cred_options
def serve(host, port, pn, sn, max_age, secrets_file):
    """Read C1000 SOC over Anker cloud MQTT and expose GET /soc."""
    creds = _creds(secrets_file)
    try:
        asyncio.run(_serve(host, port, pn, sn, max_age, creds))
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
@click.option("--webhook-file", type=click.Path(exists=True), default=None,
              help="File with a Discord webhook URL; alerts on shutdown and blind monitoring.")
def check(url, threshold, debounce, interval, shutdown, shutdown_cmd, webhook_file):
    """Poll a serve endpoint and shut this host down on sustained low SOC."""
    try:
        asyncio.run(_check(url, threshold, debounce, interval, shutdown, shutdown_cmd, webhook_file))
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
@cred_options
def status(pn, sn, wait, as_json, secrets_file):
    """One-shot: print the full realtime status the device publishes."""
    creds = _creds(secrets_file)

    async def run():
        user, password, country = creds
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
@cred_options
def devices(pn, secrets_file):
    """List devices on the account (debug; verify creds/region and find the SN)."""
    creds = _creds(secrets_file)

    async def run():
        user, password, country = creds
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
