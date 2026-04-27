#!/usr/bin/env python3

import subprocess
import sys
import os
import re

DOCKER_IMAGE = "alpine:latest"


def run(cmd):
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        sys.exit(f"❌ Command failed: {cmd}")


def volume_exists(volume):
    result = subprocess.run(
        ["docker", "volume", "inspect", volume],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0


def volume_is_empty(volume):
    cmd = (
        f"docker run --rm -v {volume}:/data "
        f"{DOCKER_IMAGE} sh -c 'ls -A /data'"
    )
    output = subprocess.check_output(cmd, shell=True).decode().strip()
    return len(output) == 0


def extract_volume_name(backup_path):
    filename = os.path.basename(backup_path)
    match = re.match(r"(.+?)_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.tar\.gz", filename)
    if not match:
        sys.exit("❌ Cannot detect volume name from filename")
    return match.group(1)


def restore_volume(backup_path):
    if not os.path.isfile(backup_path):
        sys.exit("❌ Backup file not found")

    volume = extract_volume_name(backup_path)

    print(f"▶ Detected volume name: {volume}")

    if not volume_exists(volume):
        print(f"▶ Creating Docker volume: {volume}")
        run(f"docker volume create {volume}")

    if not volume_is_empty(volume):
        sys.exit(
            f"❌ Volume '{volume}' is not empty — restore aborted\n"
            f"   (Remove volume manually if you want to overwrite)"
        )

    backup_dir = os.path.dirname(os.path.abspath(backup_path))
    backup_file = os.path.basename(backup_path)

    print(f"▶ Restoring backup into volume: {volume}")

    cmd = f"""
    docker run --rm \
      -v {volume}:/data \
      -v {backup_dir}:/backup \
      {DOCKER_IMAGE} \
      tar xzf /backup/{backup_file} -C /data
    """

    run(cmd.strip())

    print(f"✅ Restore complete for volume: {volume}")


def main():
    if os.geteuid() != 0:
        sys.exit("❌ Run as root")

    if len(sys.argv) != 2:
        sys.exit("Usage: docker-volume-restore.py /path/to/backup.tar.gz")

    restore_volume(sys.argv[1])


if __name__ == "__main__":
    main()
 
