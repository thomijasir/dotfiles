#!/usr/bin/env python3

import subprocess
import datetime
import os
import sys

BACKUP_BASE_DIR = "/backups"
DOCKER_IMAGE = "alpine:latest"


def run(cmd):
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        sys.exit(f"❌ Command failed: {cmd}")


def get_volumes():
    output = subprocess.check_output(
        ["docker", "volume", "ls", "-q"], text=True
    )
    return [v for v in output.splitlines() if v]


def backup_volume(volume):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    volume_dir = os.path.join(BACKUP_BASE_DIR, volume)
    os.makedirs(volume_dir, exist_ok=True)

    backup_file = f"{volume}_{timestamp}.tar.gz"
    backup_path = os.path.join(volume_dir, backup_file)

    print(f"▶ Backing up: {volume}")

    cmd = f"""
    docker run --rm \
      -v {volume}:/data:ro \
      -v {volume_dir}:/backup \
      {DOCKER_IMAGE} \
      tar czf /backup/{backup_file} -C /data .
    """

    run(cmd.strip())
    print(f"✅ Created: {backup_path}")


def select_volumes(volumes):
    print("\nAvailable Docker Volumes:\n")

    for i, vol in enumerate(volumes, 1):
        print(f"{i}) {vol}")

    print("\nSelect volumes:")
    print("  - Single: 1")
    print("  - Multiple: 1,3")
    print("  - All: all\n")

    choice = input("Your choice: ").strip().lower()

    if choice == "all":
        return volumes

    indexes = []
    for part in choice.split(","):
        if not part.strip().isdigit():
            sys.exit("❌ Invalid selection")
        indexes.append(int(part.strip()))

    selected = []
    for i in indexes:
        if i < 1 or i > len(volumes):
            sys.exit(f"❌ Invalid index: {i}")
        selected.append(volumes[i - 1])

    return selected


def main():
    if os.geteuid() != 0:
        sys.exit("❌ Run as root")

    volumes = get_volumes()

    if not volumes:
        sys.exit("❌ No Docker volumes found")

    selected_volumes = select_volumes(volumes)

    print("\n▶ Volumes selected:")
    for v in selected_volumes:
        print(f"  - {v}")

    print("")
    for volume in selected_volumes:
        backup_volume(volume)

    print("\n✅ Backup completed")


if __name__ == "__main__":
    main()
