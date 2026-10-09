#!/usr/bin/env python3
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
        print("This installer requires Debian or Ubuntu Linux.")
        return False

    try:
        os_release = dict(
            line.split("=", 1)
            for line in Path("/etc/os-release").read_text().splitlines()
            if "=" in line and not line.startswith("#")
        )
    except OSError as error:
        print(f"Could not read /etc/os-release: {error}")
        return False

    if os_release.get("ID", "").strip("\"'") not in {"debian", "ubuntu"}:
        print("This installer supports Debian and Ubuntu only.")
        return False

    if shutil.which("apt") is None or shutil.which("bash") is None:
        print("This installer requires apt and Bash.")
        return False

    return True


def run_script(script):
    print(f"\nRunning {script.name}...", flush=True)
    try:
        subprocess.run(["bash", str(script)], check=True)
    except subprocess.CalledProcessError as error:
        print(f"Failed: {script.name} (exit code {error.returncode}).")
        return False
    except OSError as error:
        print(f"Could not run {script.name}: {error}")
        return False

    print(f"Finished {script.name}.")
    return True


def main():
    if not check_os():
        return 1

    if not PACKAGES_DIR.is_dir():
        print(f"Package directory not found: {PACKAGES_DIR}")
        return 1

    scripts = get_scripts()
    if not scripts:
        print("No package scripts found. Expected names such as 01-essential.sh.")
        return 1

    menu = {str(number): script for number, script in enumerate(scripts, start=1)}
    while True:
        print("\nLinux setup\n")
        for number, script in menu.items():
            label = script.stem[3:].replace("-", " ").title()
            print(f"{number:>2}) {label}")
        print("99) Run all scripts")
        print(" 0) Exit")

        choice = input("Choose an option: ").strip()
        if choice == "0":
            return 0

        if choice == "99":
            confirm = input(
                "Run all scripts, including swap, user/SSH setup, and symlinks? [y/N]: "
            ).strip().lower()
            if confirm != "y":
                continue
            for script in scripts:
                if not run_script(script):
                    print("Stopped. Fix the failed script before running the remaining tasks.")
                    break
            else:
                print("All scripts finished successfully.")
            continue

        if choice in menu:
            run_script(menu[choice])
        else:
            print("Invalid option. Choose a number from the menu.")


if __name__ == "__main__":
    try:
        sys.exit(main())
    except EOFError:
        print("\nInput closed. Exiting.")
        sys.exit(0)
    except KeyboardInterrupt:
        print("\nSetup interrupted.")
        sys.exit(130)
    except OSError as error:
        print(f"Setup failed: {error}", file=sys.stderr)
        sys.exit(1)
