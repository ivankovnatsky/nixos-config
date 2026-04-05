"""Audio download functionality using yt-dlp."""

import glob
import os
import subprocess


def download_audio(url, output_dir=None):
    """Download audio from a URL using yt-dlp.

    Args:
        url: URL to download from
        output_dir: Directory to save the file to (default: current directory)

    Returns:
        Path to the downloaded MP3 file or None if failed
    """
    print(f"Downloading and extracting audio from {url}...")

    # Create a temporary directory if none provided
    if not output_dir:
        output_dir = os.getcwd()

    # Ensure the directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Change to the output directory
    original_dir = os.getcwd()
    os.chdir(output_dir)

    try:
        # Run yt-dlp command
        cmd = [
            "yt-dlp",
            "--extract-audio",
            "--audio-format",
            "mp3",
            "--postprocessor-args",
            "-ac 1 -ar 24000",
            url,
        ]

        subprocess.run(cmd, check=True, capture_output=True, text=True)

        # Find the generated MP3 file
        mp3_files = glob.glob(os.path.join(output_dir, "*.mp3"))

        if not mp3_files:
            print("Error: No MP3 file was generated.")
            return None

        # Return the path to the first MP3 file found
        return mp3_files[0]

    except subprocess.CalledProcessError as e:
        print(f"Error running yt-dlp: {e}")
        print(f"Output: {e.stdout}")
        print(f"Error: {e.stderr}")
        return None
    except Exception as e:
        print(f"Error: {str(e)}")
        return None
    finally:
        # Change back to the original directory
        os.chdir(original_dir)
