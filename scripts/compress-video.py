#!/usr/bin/env python3

import argparse
import os
import platform
import shutil
import signal
import subprocess
import sys
from pathlib import Path


# ==============================================================================
# SMART VIDEO COMPRESSOR
# Requirements: ffmpeg, ffprobe
#
# Compression profiles:
#   standard = safer default, max 1080p
#   maximum  = smaller file, max 720p
#
# Encoder behavior:
#   macOS Apple Silicon + h264_videotoolbox available -> h264_videotoolbox
#   otherwise -> libx264
# ==============================================================================

# --- Colors & Icons ---
BOLD = "\033[1m"
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN = "\033[0;36m"
WHITE = "\033[1;37m"
NC = "\033[0m"

ICON_INFO = "ℹ️"
ICON_SUCCESS = "✅"
ICON_ERROR = "❌"
ICON_WARN = "⚠️"
ICON_VIDEO = "🎬"
ICON_SAVE = "💾"
ICON_TRASH = "🗑️"

SUPPORTED_EXTENSIONS = {".mov", ".mp4", ".avi", ".mkv"}


# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

def check_dependency(command_name: str) -> None:
    """Exit if required command is not installed."""
    if shutil.which(command_name) is None:
        print(f"{RED}{ICON_ERROR} Error: {command_name} is not installed.{NC} Please install it first.")
        sys.exit(1)


def human_filesize(size_bytes: int) -> str:
    """Convert bytes into human-readable text."""
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(size_bytes)

    for unit in units:
        if size < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(size)} {unit}"
            return f"{size:.2f} {unit}"
        size /= 1024

    return f"{size_bytes} B"


def run_command(command: list[str], capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run a subprocess command safely."""
    return subprocess.run(
        command,
        capture_output=capture_output,
        text=True,
        check=False
    )


def get_video_info(input_file: Path) -> tuple[str, str, str]:
    """
    Read width, height, codec from ffprobe.
    Returns strings: (width, height, codec)
    """
    command = [
        "ffprobe",
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height,codec_name",
        "-of", "csv=p=0",
        str(input_file)
    ]
    result = run_command(command, capture_output=True)

    if result.returncode != 0 or not result.stdout.strip():
        return "N/A", "N/A", "N/A"

    parts = [p.strip() for p in result.stdout.strip().split(",")]

    if len(parts) >= 3:
        width, height, codec = parts[0], parts[1], parts[2]
        return width or "N/A", height or "N/A", codec or "N/A"

    return "N/A", "N/A", "N/A"


def get_duration_seconds(input_file: Path) -> float | None:
    """Read media duration in seconds using ffprobe."""
    command = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(input_file)
    ]
    result = run_command(command, capture_output=True)

    if result.returncode != 0:
        return None

    text = result.stdout.strip()
    if not text:
        return None

    try:
        return float(text)
    except ValueError:
        return None


def ffmpeg_encoder_available(encoder_name: str) -> bool:
    """Check whether ffmpeg has a specific encoder available."""
    command = [
        "ffmpeg",
        "-hide_banner",
        "-encoders"
    ]
    result = run_command(command, capture_output=True)

    if result.returncode != 0:
        return False

    return encoder_name in result.stdout


def is_apple_silicon_mac() -> bool:
    """Return True if running on macOS Apple Silicon."""
    return platform.system() == "Darwin" and platform.machine().lower() in {"arm64", "aarch64"}


def choose_video_encoder() -> str:
    """
    Automatically choose the best encoder.

    Apple Silicon macOS:
        use h264_videotoolbox if available

    Other systems:
        use libx264
    """
    if is_apple_silicon_mac() and ffmpeg_encoder_available("h264_videotoolbox"):
        return "h264_videotoolbox"

    return "libx264"


def get_scale_filter(max_width: int, max_height: int) -> str:
    """
    Safer scaling filter.

    - Prevents upscaling
    - Works better for both landscape and portrait
    - Forces even dimensions for encoder compatibility
    """
    return (
        f"scale='min({max_width},iw)':'min({max_height},ih)':"
        "force_original_aspect_ratio=decrease,"
        "scale=trunc(iw/2)*2:trunc(ih/2)*2"
    )


def get_ffmpeg_args(mode: str, encoder: str) -> tuple[str, list[str], str]:
    """
    Return:
        mode_label
        ffmpeg_args
        mode_color

    Profiles:
        standard = safer default, max 1080p
        maximum  = stronger compression, max 720p

    Encoder:
        libx264
        h264_videotoolbox
    """
    if mode == "maximum":
        mode_label = "MAXIMUM (Max 720p, Strong Compression)"
        mode_color = PURPLE

        if encoder == "h264_videotoolbox":
            ffmpeg_args = [
                "-map", "0:v:0",
                "-map", "0:a?",
                "-c:v", "h264_videotoolbox",
                "-b:v", "2200k",
                "-maxrate", "3200k",
                "-bufsize", "5000k",
                "-pix_fmt", "yuv420p",
                "-vf", get_scale_filter(1280, 720),
                "-c:a", "aac",
                "-b:a", "96k",
                "-ac", "2",
                "-movflags", "+faststart",
            ]
        else:
            ffmpeg_args = [
                "-map", "0:v:0",
                "-map", "0:a?",
                "-c:v", "libx264",
                "-preset", "slow",
                "-crf", "26",
                "-pix_fmt", "yuv420p",
                "-vf", get_scale_filter(1280, 720),
                "-c:a", "aac",
                "-b:a", "96k",
                "-ac", "2",
                "-movflags", "+faststart",
            ]

    else:
        mode_label = "STANDARD (Max 1080p, Safe Balanced)"
        mode_color = GREEN

        if encoder == "h264_videotoolbox":
            ffmpeg_args = [
                "-map", "0:v:0",
                "-map", "0:a?",
                "-c:v", "h264_videotoolbox",
                "-b:v", "4500k",
                "-maxrate", "6000k",
                "-bufsize", "9000k",
                "-pix_fmt", "yuv420p",
                "-vf", get_scale_filter(1920, 1080),
                "-c:a", "aac",
                "-b:a", "128k",
                "-ac", "2",
                "-movflags", "+faststart",
            ]
        else:
            ffmpeg_args = [
                "-map", "0:v:0",
                "-map", "0:a?",
                "-c:v", "libx264",
                "-preset", "slow",
                "-crf", "24",
                "-pix_fmt", "yuv420p",
                "-vf", get_scale_filter(1920, 1080),
                "-c:a", "aac",
                "-b:a", "128k",
                "-ac", "2",
                "-movflags", "+faststart",
            ]

    return mode_label, ffmpeg_args, mode_color


def make_temp_file(output_file: Path) -> Path:
    """
    Create a temp file next to final output without producing:
    name.mp4.tmp.mp4

    Example:
    final: Screen Recording.mp4
    temp : .Screen Recording.tmp.mp4
    """
    return output_file.with_name(f".{output_file.stem}.tmp{output_file.suffix}")


def get_numbered_backup_name(original_file: Path) -> Path:
    """
    Return a safe backup filename like:
    video_original.mp4
    video_original_1.mp4
    video_original_2.mp4
    """
    first_choice = original_file.with_name(f"{original_file.stem}_original{original_file.suffix}")
    if not first_choice.exists():
        return first_choice

    counter = 1
    while True:
        candidate = original_file.with_name(f"{original_file.stem}_original_{counter}{original_file.suffix}")
        if not candidate.exists():
            return candidate
        counter += 1


def build_output_plan(input_file: Path, output_folder: str | None, replace: bool, delete_original: bool):
    """
    Decide output file path and post-processing behavior.

    Returns:
        output_file: Path
        backup_original_mp4: bool
        delete_source_after_success: bool
    """
    input_ext = input_file.suffix.lower()
    stem = input_file.stem

    # If output folder is provided, write there as <stem>.mp4
    if output_folder:
        out_dir = Path(output_folder).expanduser()
        out_dir.mkdir(parents=True, exist_ok=True)
        output_file = out_dir / f"{stem}.mp4"

        # No backup rename of source in output-folder mode.
        # Source file is separate from the destination.
        backup_original_mp4 = False
        delete_source_after_success = delete_original or replace
        return output_file, backup_original_mp4, delete_source_after_success

    # No output folder: same directory
    if replace:
        # True replace mode, no backup
        if input_ext == ".mp4":
            output_file = input_file
        else:
            output_file = input_file.with_suffix(".mp4")
        return output_file, False, (input_ext != ".mp4")

    if delete_original:
        # Delete original after success, no backup
        if input_ext == ".mp4":
            output_file = input_file
        else:
            output_file = input_file.with_suffix(".mp4")
        return output_file, False, (input_ext != ".mp4")

    # Default mode
    if input_ext == ".mp4":
        # Keep compressed file with same name, move original to *_original.mp4
        return input_file, True, False

    # Non-MP4 default: just convert to .mp4 with same stem
    return input_file.with_suffix(".mp4"), False, False


def same_file(path1: Path, path2: Path) -> bool:
    """Check if two paths point to the same resolved file location."""
    try:
        return path1.resolve() == path2.resolve()
    except FileNotFoundError:
        return False


def validate_output_file(input_file: Path, output_file: Path) -> bool:
    """
    Validate compressed output before replacing/deleting original.

    Checks:
    - File exists
    - File size is not empty
    - Video stream is readable
    - Output duration is close to input duration
    """
    if not output_file.exists():
        print(f"{RED}{ICON_ERROR} Validation failed: output file does not exist.{NC}")
        return False

    if output_file.stat().st_size <= 0:
        print(f"{RED}{ICON_ERROR} Validation failed: output file is empty.{NC}")
        return False

    width, height, codec = get_video_info(output_file)

    if width == "N/A" or height == "N/A" or codec == "N/A":
        print(f"{RED}{ICON_ERROR} Validation failed: ffprobe could not read output video stream.{NC}")
        return False

    input_duration = get_duration_seconds(input_file)
    output_duration = get_duration_seconds(output_file)

    if input_duration is not None and output_duration is not None:
        allowed_difference = max(2.0, input_duration * 0.02)
        actual_difference = abs(input_duration - output_duration)

        if actual_difference > allowed_difference:
            print(f"{RED}{ICON_ERROR} Validation failed: output duration differs too much from input.{NC}")
            print(f"{BOLD}Input duration:{NC}  {input_duration:.2f}s")
            print(f"{BOLD}Output duration:{NC} {output_duration:.2f}s")
            print(f"{BOLD}Difference:{NC}      {actual_difference:.2f}s")
            return False

    return True


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Smart Video Compressor",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=(
            "Examples:\n"
            "  compress-video.py video.mp4\n"
            "  compress-video.py -s video.mov\n"
            "  compress-video.py -m video.mov\n"
            "  compress-video.py -d video.mov\n"
            "  compress-video.py -r video.mp4\n"
            "  compress-video.py video.mp4 ./out/\n\n"
            "Notes:\n"
            "  Default mode is STANDARD for safer compression.\n"
            "  On Apple Silicon macOS, h264_videotoolbox is used automatically if available.\n"
            "  On other systems, libx264 is used.\n"
        )
    )

    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "-m",
        "--maximum",
        action="store_true",
        help="Maximum compression. Max 720p. Smaller file, still safer than old aggressive mode."
    )
    mode_group.add_argument(
        "-s",
        "--standard",
        action="store_true",
        help="Standard compression. Max 1080p. Safer balanced mode. This is the default."
    )

    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
        "-r",
        "--replace",
        action="store_true",
        help="Replace the original file. No backup."
    )
    action_group.add_argument(
        "-d",
        "--delete-original",
        action="store_true",
        help="Delete original file after compression. No backup."
    )

    parser.add_argument("video_file", help="Input video file")
    parser.add_argument("output_folder", nargs="?", help="Optional output folder")

    return parser.parse_args()


def main():
    # Check dependencies
    check_dependency("ffmpeg")
    check_dependency("ffprobe")

    args = parse_args()

    # Safer default:
    # Previous script defaulted to maximum.
    # New script defaults to standard unless -m is passed.
    compression_mode = "maximum" if args.maximum else "standard"

    replace = args.replace
    delete_original = args.delete_original

    input_file = Path(args.video_file).expanduser()

    # Input validation
    if not input_file.exists() or not input_file.is_file():
        print(f"{RED}{ICON_ERROR} Error: File '{input_file}' not found.{NC}")
        sys.exit(1)

    input_ext = input_file.suffix.lower()
    if input_ext not in SUPPORTED_EXTENSIONS:
        supported = ", ".join(ext.lstrip(".") for ext in sorted(SUPPORTED_EXTENSIONS))
        print(f"{RED}{ICON_ERROR} Unsupported file format: {input_ext}{NC} (supported: {supported})")
        sys.exit(1)

    output_file, backup_original_mp4, delete_source_after_success = build_output_plan(
        input_file=input_file,
        output_folder=args.output_folder,
        replace=replace,
        delete_original=delete_original,
    )

    temp_file = make_temp_file(output_file)

    # Extra safety: if temp file exists from earlier failed run, remove it first
    if temp_file.exists():
        temp_file.unlink()

    # Analyze source file
    print(f"{BLUE}{ICON_INFO} Analyzing source file...{NC}")

    orig_size = input_file.stat().st_size
    orig_size_hr = human_filesize(orig_size)
    orig_width, orig_height, orig_codec = get_video_info(input_file)
    orig_duration = get_duration_seconds(input_file)

    # Choose encoder automatically
    encoder = choose_video_encoder()
    mode_label, ffmpeg_args, mode_color = get_ffmpeg_args(compression_mode, encoder)

    # Show job info
    print(f"{WHITE}=================================================={NC}")
    print(f"  {ICON_VIDEO}  {BOLD}VIDEO COMPRESSION JOB{NC}")
    print(f"{WHITE}=================================================={NC}")
    print(f"{BOLD}Input:{NC}         {input_file}")
    print(f"{BOLD}Details:{NC}       {orig_width}x{orig_height} | {orig_codec} | {orig_size_hr}")

    if orig_duration is not None:
        print(f"{BOLD}Duration:{NC}      {orig_duration:.2f}s")

    print(f"{BOLD}Mode:{NC}          {mode_color}{mode_label}{NC}")
    print(f"{BOLD}Encoder:{NC}       {CYAN}{encoder}{NC}")

    if encoder == "h264_videotoolbox":
        print(f"{BOLD}Hardware:{NC}      {GREEN}Apple VideoToolbox enabled automatically{NC}")

    print(f"{BOLD}Output:{NC}        {output_file}")

    if backup_original_mp4:
        future_backup = get_numbered_backup_name(input_file)
        print(f"{BOLD}Backup:{NC}        {YELLOW}{future_backup.name}{NC}")

    if delete_original or replace:
        print(f"{BOLD}Action:{NC}        {RED}{ICON_TRASH} Original will be removed after success{NC}")

    print(f"{WHITE}=================================================={NC}")
    print(f"{CYAN}{ICON_INFO} Processing...{NC}")

    def handle_sigint(signum, frame):
        if temp_file.exists():
            temp_file.unlink()
        print(f"\n{RED}{ICON_ERROR} Aborted by user.{NC}")
        sys.exit(1)

    signal.signal(signal.SIGINT, handle_sigint)

    # Build ffmpeg command
    ffmpeg_command = []

    # Optional lower priority on macOS/Linux.
    # VideoToolbox benefits less from nice, but it is still okay.
    system_name = platform.system()
    if system_name in {"Darwin", "Linux"} and shutil.which("nice"):
        ffmpeg_command.extend(["nice", "-n", "10"])

    ffmpeg_command.extend([
        "ffmpeg",
        "-v", "error",
        "-stats",
        "-i", str(input_file),
        *ffmpeg_args,
        "-y",
        str(temp_file),
    ])

    result = run_command(ffmpeg_command)

    print()  # new line after ffmpeg stats

    if result.returncode != 0:
        print(f"{RED}{ICON_ERROR} Compression failed!{NC}")
        if temp_file.exists():
            temp_file.unlink()
        sys.exit(1)

    # Validate temp output before touching original
    print(f"{BLUE}{ICON_INFO} Validating output file...{NC}")

    if not validate_output_file(input_file, temp_file):
        print(f"{RED}{ICON_ERROR} Output validation failed. Original file was not modified.{NC}")
        if temp_file.exists():
            temp_file.unlink()
        sys.exit(1)

    print(f"{GREEN}{ICON_SUCCESS} Output validation passed.{NC}")

    # Success path:
    # Handle backup / replace / move carefully.
    try:
        # Case 1: default MP4 behavior -> rename original to *_original.mp4
        if backup_original_mp4 and same_file(input_file, output_file):
            backup_file = get_numbered_backup_name(input_file)
            input_file.rename(backup_file)
            temp_file.rename(output_file)

        # Case 2: output overwrites same file, MP4 replace/delete mode
        elif same_file(input_file, output_file):
            old_file_for_delete = input_file.with_name(f"{input_file.stem}.pre_replace{input_file.suffix}")
            counter = 0

            while old_file_for_delete.exists():
                counter += 1
                old_file_for_delete = input_file.with_name(
                    f"{input_file.stem}.pre_replace_{counter}{input_file.suffix}"
                )

            input_file.rename(old_file_for_delete)
            temp_file.rename(output_file)

            # In replace/delete mode, remove old original with no backup
            old_file_for_delete.unlink()

        # Case 3: normal separate output path
        else:
            temp_file.rename(output_file)

            # Remove original after success if requested
            if delete_source_after_success and input_file.exists():
                input_file.unlink()

    except Exception as exc:
        print(f"{RED}{ICON_ERROR} Failed during final file move/rename: {exc}{NC}")
        if temp_file.exists():
            temp_file.unlink()
        sys.exit(1)

    # Summarize
    new_size = output_file.stat().st_size
    new_size_hr = human_filesize(new_size)

    if orig_size > 0:
        saved_bytes = orig_size - new_size
        if saved_bytes < 0:
            percent_saved = 0.0
            saved_color = RED
        else:
            percent_saved = (saved_bytes / orig_size) * 100
            saved_color = GREEN
    else:
        percent_saved = 0.0
        saved_color = NC

    new_width, new_height, new_codec = get_video_info(output_file)
    new_duration = get_duration_seconds(output_file)

    print(f"{WHITE}=================================================={NC}")
    print(f"  {ICON_SUCCESS}  {BOLD}{GREEN}COMPRESSION COMPLETE{NC}")
    print(f"{WHITE}=================================================={NC}")
    print(f"{BOLD}Original:{NC}      {orig_size_hr}")
    print(f"{BOLD}New Size:{NC}      {GREEN}{new_size_hr}{NC}")
    print(f"{BOLD}Reduction:{NC}     {saved_color}-{percent_saved:.1f}%{NC}")
    print(f"{BOLD}Output Info:{NC}   {new_width}x{new_height} | {new_codec}")

    if new_duration is not None:
        print(f"{BOLD}New Duration:{NC}  {new_duration:.2f}s")

    print(f"{BOLD}Location:{NC}      {ICON_SAVE} {output_file}")

    if backup_original_mp4:
        print(f"{BOLD}Status:{NC}        {YELLOW}Original MP4 was renamed to *_original*.mp4{NC}")
    elif delete_original or replace:
        print(f"{BOLD}Status:{NC}        {RED}{ICON_TRASH} Original file removed.{NC}")

    print(f"{WHITE}=================================================={NC}")


if __name__ == "__main__":
    main()
