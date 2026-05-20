"""AutoVolume: lower system volume after no sound activity (macOS + Linux).

Activity detection combines several probes:
  macOS:
    * IOKit IOAudioEngine state — playback on Intel Macs. Absent on Apple
      Silicon (built-in audio is not an IOAudioEngine), where this probe
      abstains rather than guessing.
    * pmset assertions — `coreaudiod` holds a `com.apple.audio.*` power
      assertion whenever audio is being output (works on Apple Silicon),
      and conferencing apps show up as assertion owners (call guard).
  Linux:
    * PulseAudio/PipeWire uncorked sink inputs — playback.
    * an application capturing the microphone — call guard.

Each probe returns True / False / None. `is_audio_active()` ignores probes
that returned None (could not tell) and decides from the rest; if no probe
could tell, it returns None and the daemon treats that as active. Better to
leave the volume alone than to silence the user during a meeting.
"""

from __future__ import annotations

import re
import subprocess
import sys
import time

import volume as volume_mod
from common import is_linux, is_macos

# Defaults intentionally re-exported so the daemon CLI and the nix module
# can share them.
DEFAULT_IDLE_SECONDS = 60 * 30  # 30 minutes
DEFAULT_THRESHOLD_PERCENT = 2.5
DEFAULT_CHECK_INTERVAL = 60 * 5  # 5 minutes

# Hard timeout for every probe subprocess so a stuck ioreg/pmset/pactl can
# never wedge the daemon loop (and block signal handling).
PROBE_TIMEOUT = 10

# Process-name fragments that imply an active conferencing call. Matched as
# lowercase substrings against `pmset -g assertions`, which lists assertion
# owners by process name. Kept to real app names on purpose — generic terms
# like "coreaudio" would match the always-running coreaudiod and pin the
# daemon to "active" forever.
CALL_GUARD_KEYWORDS = (
    "zoom",
    "webex",
    "microsoft teams",
    "teams.helper",
    "slack helper",
    "slack call",
    "facetime",
    "google meet",
    "meet.google",
    "discord",
    "whatsapp",
    "skype",
)


def _run(cmd: list[str]) -> str | None:
    """Run a probe command; return stdout, or None on any failure."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            timeout=PROBE_TIMEOUT,
        )
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        FileNotFoundError,
    ):
        return None
    return result.stdout


def _ioreg_audio_active() -> bool | None:
    """True if an IOKit audio engine is running; otherwise abstains (None).

    Scoped to the IOAudioEngine class (and its subclasses) so we don't dump
    the whole IORegistry on every tick.

    This probe only ever votes "active" — a positive sighting of a running
    engine (state 1). Anything else returns None (abstain): a not-running
    engine, no IOAudioEngine node at all (Apple Silicon), or a failed
    command. Absence of a running engine does NOT prove silence — audio can
    be routed through HDMI / AirPlay / Bluetooth paths not modelled here —
    so the authoritative idle verdict is left to the pmset probe.
    """
    out = _run(["ioreg", "-c", "IOAudioEngine", "-r", "-l", "-w", "0"])
    if out is None:
        return None
    # IOAudioEngineState values: 0 idle, 1 running, 2 paused, 3 stopping.
    if '"IOAudioEngineState" = 1' in out:
        return True
    return None


def _pmset_audio_active() -> bool | None:
    """True if pmset -g assertions shows audio playback or a known call.

    Two signals, both from a single `pmset -g assertions` call:
      * `coreaudiod` holding a `com.apple.audio.*` assertion — present only
        while audio is actually being output. This is the signal that works
        on Apple Silicon, where IOAudioEngine nodes do not exist.
      * an assertion owned by a known conferencing process (call guard, so
        a momentarily silent meeting is not mistaken for idle).
    """
    out = _run(["pmset", "-g", "assertions"])
    if out is None:
        return None
    text = out.lower()
    for line in text.splitlines():
        if "coreaudiod" in line and "com.apple.audio" in line:
            return True
    return any(k in text for k in CALL_GUARD_KEYWORDS)


def _pactl_audio_active() -> bool | None:
    """True if PulseAudio/PipeWire has an uncorked sink input (playback)."""
    out = _run(["pactl", "list", "sink-inputs"])
    if out is None:
        return None
    if "Sink Input #" not in out:
        return False
    corked = re.findall(r"Corked:\s*(yes|no)", out)
    if not corked:
        return True
    return any(state == "no" for state in corked)


def _pactl_mic_in_use() -> bool | None:
    """True if any application is capturing the microphone; else abstains.

    A live source output means the user is in a call or recording, so we
    treat it as activity regardless of whether playback is momentarily
    silent — the Linux equivalent of the macOS call guard.

    This is a guard only: it votes "active" or abstains (None), never a
    hard False. No mic capture does NOT prove silence — the authoritative
    idle verdict belongs to the playback probe (_pactl_audio_active).
    """
    out = _run(["pactl", "list", "source-outputs"])
    if out is None:
        return None
    if "Source Output #" in out:
        return True
    return None


def is_audio_active() -> bool | None:
    """Combined signal across all probes.

    A probe returning None abstained (could not tell — e.g. IOAudioEngine
    is absent on Apple Silicon, or a command failed). Such probes are
    dropped; the verdict comes from the probes that could decide.

    Returns:
      True  — at least one deciding probe says active.
      False — every deciding probe says idle.
      None  — no probe could decide; caller should treat as active
              (fail-safe — never silence on a total blackout of signal).
    """
    if is_macos():
        probes = [_ioreg_audio_active(), _pmset_audio_active()]
    elif is_linux():
        probes = [_pactl_audio_active(), _pactl_mic_in_use()]
    else:
        return None
    decided = [p for p in probes if p is not None]
    if not decided:
        return None
    return any(decided)


class AutoVolume:
    """Lower volume to `threshold_percent` after `idle_seconds` of silence.

    Lowers at most once per idle period within a single daemon run; the
    latch resets when audio resumes so the user can raise the volume
    manually and the next idle period will lower it again. The latch is
    in-memory only — a daemon restart re-arms it, but re-lowering an
    already-low volume is a harmless no-op.
    """

    name = "autovolume"

    def __init__(
        self,
        idle_seconds: int,
        threshold_percent: float,
        verbose: bool = True,
    ) -> None:
        self.idle_seconds = idle_seconds
        self.threshold_percent = threshold_percent
        self.verbose = verbose
        self.last_audio_time = time.monotonic()
        self.lowered_in_this_idle = False

    def log(self, msg: str) -> None:
        if self.verbose:
            print(f"[autovolume] {msg}", file=sys.stdout, flush=True)

    def tick(self) -> None:
        active = is_audio_active()
        now = time.monotonic()
        # Fail-safe: unknown counts as active so we never silence a call
        # when the detector is broken.
        if active is None or active:
            self.last_audio_time = now
            if self.lowered_in_this_idle:
                self.log("audio resumed; idle latch reset")
            self.lowered_in_this_idle = False
            return
        if self.lowered_in_this_idle:
            return
        idle = now - self.last_audio_time
        if idle < self.idle_seconds:
            return
        current = volume_mod.volume_get()
        if current is None:
            self.log("cannot read current volume; skipping")
            return
        if current <= self.threshold_percent:
            self.log(
                f"volume {current:.1f}% already <= {self.threshold_percent}%; "
                "latching without write"
            )
            self.lowered_in_this_idle = True
            return
        self.log(
            f"idle for {idle:.0f}s (>= {self.idle_seconds}s); "
            f"lowering volume {current:.1f}% -> {self.threshold_percent}%"
        )
        if volume_mod.volume_set(self.threshold_percent):
            self.lowered_in_this_idle = True


def register(cli):
    @cli.command()
    def autovolume():
        """Probe audio activity (the same signal the daemon uses)."""
        if not is_macos() and not is_linux():
            print(
                "autovolume only available on macOS and Linux",
                file=sys.stderr,
            )
            sys.exit(1)
        active = is_audio_active()
        if active is None:
            print("audio: unknown (treated as active by daemon)")
            # Exit 3: distinct from Click's usage-error code (2).
            sys.exit(3)
        print(f"audio: {'active' if active else 'idle'}")
