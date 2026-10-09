#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

PACKAGES_DIR = Path(__file__).resolve().parent / "packages"


def get_scripts():
    """Find package scripts named NN-description.sh in numeric order."""
    return sorted(
        path
        for path in PACKAGES_DIR.glob("[0-9][0-9]-*.sh")
        if path.is_file() and path.stem[3:]
    )


def check_os():
    if sys.platform != "linux":
        print("    This installer requires Debian or Ubuntu Linux.")
        return False

    try:
        os_release = dict(
            line.split("=", 1)
            for line in Path("/etc/os-release").read_text().splitlines()
            if "=" in line and not line.startswith("#")
        )
    except OSError as error:
        print(f"    Could not read /etc/os-release: {error}")
        return False

    if os_release.get("ID", "").strip("\"'") not in {"debian", "ubuntu"}:
        print("    This installer supports Debian and Ubuntu only.")
        return False

    if shutil.which("apt") is None or shutil.which("bash") is None:
        print("    This installer requires apt and Bash.")
        return False

    return True


def color(text, code):
    if sys.stdout.isatty() and "NO_COLOR" not in os.environ:
        return f"\033[{code}m{text}\033[0m"
    return text


def print_menu(menu):
    print(color("\n    ╭────────────────────────────────────────────────╮", "36"))
    print(color("    │  LINUX SETUP                                   │", "1;36"))
    print(color("    ╰────────────────────────────────────────────────╯", "36"))
    print("    Packages and tools for Debian / Ubuntu\n")
    for number, script in menu.items():
        label = script.stem[3:].replace("-", " ").title()
        print(f"    {color(f'{number:>2}', '36')}  {label}")
    print(f"\n    {color(' 0', '36')}  Exit")
    print(color("    ──────────────────────────────────────────────────", "36"))
    print("    One package:       1")
    print("    Several packages:  1,2,3,4  (spaces are fine)")
    print("    Runs in the order entered; stops if a script fails.")
    print("    Repeated numbers run once. Enter 0 to exit.\n")


def run_script(script):
    print(color(f"\n    Running {script.name}...", "1;36"), flush=True)
    try:
        subprocess.run(["bash", str(script)], check=True)
    except subprocess.CalledProcessError as error:
        print(color(f"    Failed: {script.name} (exit code {error.returncode}).", "31"))
        return False
    except OSError as error:
        print(color(f"    Could not run {script.name}: {error}", "31"))
        return False

    print(color(f"    Finished {script.name}.", "32"))
    return True


def main():
    if not check_os():
        return 1

    if not PACKAGES_DIR.is_dir():
        print(f"    Package directory not found: {PACKAGES_DIR}")
        return 1

    scripts = get_scripts()
    if not scripts:
        print("    No package scripts found. Expected names such as 01-essential.sh.")
        return 1

    menu = {str(number): script for number, script in enumerate(scripts, start=1)}
    while True:
        print_menu(menu)
        choice = input("    Select packages > ").strip()
        if choice == "0":
            return 0

        # Validate the whole selection before running anything; keep its order.
        selections = list(dict.fromkeys(item.strip() for item in choice.split(",")))
        if any(number not in menu for number in selections):
            print(color("\n    Invalid selection. Use menu numbers such as 1 or 1,2,3,4.", "31"))
            continue

        print(color(f"\n    Selected: {', '.join(selections)}", "1"))
        for number in selections:
            if not run_script(menu[number]):
                print("    Stopped. Fix the failed script before continuing.")
                break
        else:
            print(color("\n    Selected packages finished successfully.", "32"))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except EOFError:
        print("\n    Input closed. Exiting.")
        sys.exit(0)
    except KeyboardInterrupt:
        print("\n    Setup interrupted.")
        sys.exit(130)
    except OSError as error:
        print(f"    Setup failed: {error}", file=sys.stderr)
        sys.exit(1)
