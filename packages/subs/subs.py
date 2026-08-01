#!/usr/bin/env python3
"""Generate SRT subtitle sidecars from media with Whisper on the local GPU.

One CLI over both backends: openai-whisper (CUDA, a3) and mlx-whisper (Apple
GPU, mini). It normalises audio with ffmpeg, runs the chosen engine with the
loop-resistant greedy decoding we settled on (beam_size 1, temperature 0,
condition_on_previous_text off), strips the stray cold-open "The" cue, checks
for a hallucination loop, and drops the result next to the media as a
Jellyfin-friendly `NAME.<lang>.srt` sidecar.
"""

import platform
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import click

# Friendly model name -> per-engine identifier.
MODELS = {
    "turbo": {
        "openai": "turbo",
        "mlx": "mlx-community/whisper-large-v3-turbo",
    },
    "large-v3": {
        "openai": "large-v3",
        "mlx": "mlx-community/whisper-large-v3-mlx",
    },
}

def default_engine() -> str:
    """mini (Apple Silicon) -> mlx; everything else (a3/Linux) -> openai."""
    return "mlx" if platform.system() == "Darwin" else "openai"


def have(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def run(cmd: list[str], *, dry: bool) -> None:
    if dry:
        click.echo("+ " + " ".join(cmd))
        return
    subprocess.run(cmd, check=True)


def extract_audio(src: Path, wav: Path, *, dry: bool) -> None:
    """Mono 16 kHz PCM — what Whisper wants."""
    run(
        [
            "ffmpeg", "-y", "-i", str(src),
            "-vn", "-ac", "1", "-ar", "16000",
            "-c:a", "pcm_s16le", str(wav),
        ],
        dry=dry,
    )


def openai_cmd(wav: Path, model: str, language: str, cond: bool, out: Path) -> list[str]:
    # a3 `whisper` wrapper forces `--device cuda --model large-v3`; the trailing
    # flags override (argparse keeps the last value). Greedy = beam_size 1 + temp 0,
    # which reads far cleaner than the openai-whisper default (beam 5 + temperature
    # fallback ladder, whose high-temp retries produce lowercase run-ons).
    binary = "whisper" if have("whisper") else None
    prefix = [binary] if binary else ["uvx", "--from", "openai-whisper", "whisper", "--device", "cpu"]
    return prefix + [
        str(wav),
        "--model", model,
        "--language", language,
        "--beam_size", "1",
        "--temperature", "0",
        "--condition_on_previous_text", "True" if cond else "False",
        "--output_format", "srt",
        "--output_dir", str(out),
    ]


def mlx_cmd(wav: Path, model: str, language: str, cond: bool, out: Path) -> list[str]:
    # mlx-whisper is greedy at temperature 0 by default (no beam flag exists).
    prefix = ["mlx_whisper"] if have("mlx_whisper") else ["uvx", "--from", "mlx-whisper", "mlx_whisper"]
    return prefix + [
        str(wav),
        "--model", model,
        "--language", language,
        "--temperature", "0",
        "--condition-on-previous-text", "True" if cond else "False",
        "--output-format", "srt",
        "--output-dir", str(out),
    ]


def clean_srt(path: Path) -> int:
    """Drop standalone `The` cues (cold-open artifact / loop marker), renumber.

    Returns how many were removed so the caller can flag a hallucination loop.
    """
    blocks = [b for b in re.split(r"\n\s*\n", path.read_text(encoding="utf-8").strip()) if b.strip()]
    removed = 0
    kept: list[str] = []
    for b in blocks:
        lines = b.splitlines()
        # lines: index, timestamp, text...
        text = " ".join(lines[2:]).strip() if len(lines) >= 3 else ""
        if text == "The":
            removed += 1
            continue
        kept.append(b)
    out = []
    for i, b in enumerate(kept, 1):
        lines = b.splitlines()
        lines[0] = str(i)
        out.append("\n".join(lines))
    path.write_text("\n\n".join(out) + "\n", encoding="utf-8")
    return removed


@click.command()
@click.argument("media", nargs=-1, required=True, type=click.Path(exists=True, path_type=Path))
@click.option("-e", "--engine", type=click.Choice(["auto", "openai", "mlx"]), default="auto",
              help="Whisper backend. auto: mlx on Apple Silicon, openai elsewhere.")
@click.option("-m", "--model", default="turbo", show_default=True,
              help="turbo (fast, default) or large-v3 (small accuracy bump), or a raw engine model id.")
@click.option("-l", "--language", default="en", show_default=True)
@click.option("--lang-tag", default=None, help="Filename language tag (defaults to --language).")
@click.option("--condition-on-previous-text/--no-condition-on-previous-text", "cond",
              default=False, show_default=True,
              help="Context carry-over. Off is loop-resistant (recommended).")
@click.option("-o", "--output", type=click.Path(path_type=Path), default=None,
              help="Explicit output .srt path (single input only). Default: sidecar next to media.")
@click.option("--no-sidecar", is_flag=True, help="Write NAME.<lang>.srt into the CWD, not next to the media.")
@click.option("--keep-audio", is_flag=True, help="Keep the extracted wav (debug).")
@click.option("-f", "--force", is_flag=True, help="Overwrite an existing .srt (default: skip it).")
@click.option("-n", "--dry-run", is_flag=True, help="Print commands without running them.")
def main(media, engine, model, language, lang_tag, cond, output, no_sidecar, keep_audio, force, dry_run):
    """Transcribe MEDIA to sidecar .srt subtitles with Whisper."""
    if engine == "auto":
        engine = default_engine()
    lang_tag = lang_tag or language
    resolved = MODELS.get(model, {}).get(engine, model)  # friendly alias or raw passthrough

    if output and len(media) > 1:
        raise click.UsageError("--output takes a single input file.")

    build = openai_cmd if engine == "openai" else mlx_cmd
    if engine == "openai" and not have("whisper"):
        click.secho("warn: no CUDA `whisper` wrapper on PATH — falling back to CPU openai-whisper (slow).", fg="yellow")

    rc = 0
    for src in media:
        if output:
            dest = output
        elif no_sidecar:
            dest = Path.cwd() / f"{src.stem}.{lang_tag}.srt"
        else:
            dest = src.with_name(f"{src.stem}.{lang_tag}.srt")

        # Refuse to clobber an existing subtitle (may be hand-edited) unless --force.
        if dest.exists() and not force and not dry_run:
            click.secho(f"skip: {dest.name} exists (use --force to overwrite)", fg="yellow")
            rc = 1
            continue

        click.secho(f"\n== {src.name}  [engine={engine} model={model}]", bold=True)
        started = time.monotonic()
        try:
            with tempfile.TemporaryDirectory(prefix="subs-") as td:
                tmp = Path(td)
                wav = tmp / "audio.wav"
                extract_audio(src, wav, dry=dry_run)
                run(build(wav, resolved, language, cond, tmp), dry=dry_run)
                if dry_run:
                    continue

                produced = wav.with_suffix(".srt")
                if not produced.exists():
                    click.secho(f"error: engine produced no SRT for {src.name}", fg="red")
                    rc = 1
                    continue

                removed = clean_srt(produced)
                if removed > 5:  # bare-"The" count doubles as a loop signal
                    click.secho(f"  WARNING: {removed} bare-'The' cues removed — likely a hallucination "
                                f"loop; inspect the transcript.", fg="red")

                shutil.copyfile(produced, dest)
                dest.chmod(0o644)
                if keep_audio:
                    shutil.copyfile(wav, src.with_name(f"{src.stem}.wav"))
        except subprocess.CalledProcessError as exc:
            click.secho(f"error: {src.name}: {Path(exc.cmd[0]).name} failed (exit {exc.returncode})", fg="red")
            rc = 1
            continue

        elapsed = time.monotonic() - started
        click.secho(f"  -> {dest}  ({elapsed:.0f}s)", fg="green")

    sys.exit(rc)


if __name__ == "__main__":
    main()
