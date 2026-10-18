#!/usr/bin/env python3
"""Write a hybrid Linux installer ISO to an external USB drive on macOS."""

import argparse
from contextlib import contextmanager
from dataclasses import dataclass
import fcntl
import hashlib
import os
from pathlib import Path
import platform
import plistlib
import re
import stat
import subprocess
import sys
import time


CHUNK_SIZE = 4 * 1024 * 1024
DISKUTIL = "/usr/sbin/diskutil"
IOREG = "/usr/sbin/ioreg"
# From macOS sys/disk.h: _IO('d', 22). Flush the device's hardware write cache.
DKIOCSYNCHRONIZECACHE = 0x20006416
WHOLE_DISK = re.compile(r"disk[0-9]+")
DISK = re.compile(r"disk[0-9]+(?:s[0-9]+)*")


class BootError(Exception):
    pass


@dataclass(frozen=True)
class Iso:
    path: Path
    size: int
    digest: str
    identity: tuple


@dataclass(frozen=True)
class UsbDisk:
    identifier: str
    name: str
    size: int
    block_size: int
    media_id: int
    tree_path: str
    volumes: tuple

    @property
    def device(self):
        return f"/dev/{self.identifier}"

    @property
    def raw_device(self):
        return f"/dev/r{self.identifier}"

    @property
    def identity(self):
        return (self.identifier, self.name, self.size, self.block_size, self.media_id, self.tree_path)


class Progress:
    def __init__(self, label, total):
        self.label = label
        self.total = total
        self.start = time.monotonic()
        self.last = 0

    def __call__(self, done):
        now = time.monotonic()
        if done != self.total and now - self.last < 0.2:
            return
        self.last = now
        speed = done / max(now - self.start, 0.001)
        print(
            f"\r{self.label}: {done / self.total:6.1%}  "
            f"{done:,}/{self.total:,} bytes  {human_size(speed)}/s",
            end="\n" if done == self.total else "",
            flush=True,
        )


def human_size(size):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if size < 1024 or unit == "TiB":
            return f"{size:.1f} {unit}"
        size /= 1024


def display(value):
    # Disk labels and filenames can contain terminal control characters.
    return "".join(char if char.isprintable() else "?" for char in str(value))


def run_command(command):
    result = subprocess.run(command, capture_output=True, check=False)
    if result.returncode:
        detail = (result.stderr or result.stdout).decode(errors="replace").strip()
        raise BootError(f"{Path(command[0]).name} failed: {display(detail)}")
    return result.stdout


def read_plist(command):
    try:
        data = plistlib.loads(run_command(command))
    except (plistlib.InvalidFileException, ValueError, TypeError) as error:
        raise BootError("Could not read macOS disk metadata.") from error
    if not isinstance(data, (dict, list)) or (isinstance(data, dict) and data.get("Error")):
        raise BootError("macOS returned invalid disk metadata.")
    return data


def disk_info(device):
    data = read_plist([DISKUTIL, "info", "-plist", device])
    if not isinstance(data, dict) or not DISK.fullmatch(data.get("DeviceIdentifier", "")):
        raise BootError(f"Could not identify disk: {display(device)}")
    return data


def file_identity(info):
    return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)


@contextmanager
def open_source(path):
    descriptor = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    try:
        if not stat.S_ISREG(os.fstat(descriptor).st_mode):
            raise BootError("The ISO must be a regular file.")
        source = os.fdopen(descriptor, "rb")
    except BaseException:
        os.close(descriptor)
        raise
    with source:
        yield source


def hash_stream(source, size, progress=None):
    digest = hashlib.sha256()
    done = 0
    while done < size:
        chunk = source.read(min(CHUNK_SIZE, size - done))
        if not chunk:
            raise BootError("Unexpected end of data during verification.")
        digest.update(chunk)
        done += len(chunk)
        if progress:
            progress(done)
    return digest.hexdigest()


def validate_iso(path, expected=None):
    path = Path(path).expanduser().resolve(strict=True)
    with open_source(path) as source:
        before = os.fstat(source.fileno())
        if before.st_size < 17 * 2048:
            raise BootError("The file is too small to be an ISO image.")
        # ISO 9660's first volume descriptor starts at sector 16.
        source.seek(16 * 2048)
        if source.read(7) not in (b"\x00CD001\x01", b"\x01CD001\x01", b"\x02CD001\x01"):
            raise BootError("The file does not have an ISO 9660 signature.")
        source.seek(0)
        digest = hash_stream(source, before.st_size, Progress("Checking ISO", before.st_size))
        if file_identity(before) != file_identity(os.fstat(source.fileno())):
            raise BootError("The ISO changed during verification.")
    if expected and digest != expected.lower():
        raise BootError(f"ISO SHA256 mismatch. Calculated: {digest}")
    return Iso(path, before.st_size, digest, file_identity(before))


def physical_disks(info, seen=None):
    """Resolve APFS snapshots, volumes and containers to every backing disk."""
    seen = set() if seen is None else seen
    identifier = info["DeviceIdentifier"]
    if identifier in seen:
        raise BootError("Could not resolve a disk's physical backing devices.")
    seen = seen | {identifier}
    stores = info.get("APFSPhysicalStores")
    if stores:
        result = set()
        for store in stores:
            device = store.get("APFSPhysicalStore") or store.get("DeviceIdentifier")
            if not isinstance(device, str) or not DISK.fullmatch(device):
                raise BootError("Could not identify an APFS physical store.")
            result.update(physical_disks(disk_info(device), seen))
        return result
    if info.get("WholeDisk") is True:
        physical = info.get("VirtualOrPhysical") == "Physical"
        internal = info.get("Internal") is True and info.get("VirtualOrPhysical") != "Virtual"
        if physical or internal:
            return {identifier}
    # An APFS physical-store partition also names its synthesized container.
    # Follow its parent disk first to avoid a store -> container -> store cycle.
    parent = info.get("ParentWholeDisk")
    if parent and parent != identifier and WHOLE_DISK.fullmatch(parent):
        return physical_disks(disk_info(parent), seen)
    container = info.get("APFSContainerReference")
    if container and container != identifier:
        return physical_disks(disk_info(container), seen)
    raise BootError(f"Could not safely resolve the physical disk for {identifier}.")


def protected_disks(source_path):
    output = run_command(["/bin/df", "-P", str(source_path)]).decode(errors="replace").splitlines()
    device = output[-1].split()[0] if len(output) >= 2 and output[-1].split() else ""
    if not device.startswith("/dev/") or not DISK.fullmatch(device[5:]):
        raise BootError("Could not identify the disk containing the ISO.")
    return physical_disks(disk_info("/")) | physical_disks(disk_info(device))


def media_ids():
    nodes = read_plist([IOREG, "-r", "-c", "IOMedia", "-a"])
    result = {}

    def visit(items):
        for node in items:
            if not isinstance(node, dict):
                raise BootError("Could not identify USB media in IOKit.")
            name = node.get("BSD Name", "")
            entry_id = node.get("IORegistryEntryID")
            if node.get("Whole") is True and WHOLE_DISK.fullmatch(name) and type(entry_id) is int:
                result[name] = entry_id
            visit(node.get("IORegistryEntryChildren", []))

    if not isinstance(nodes, list):
        raise BootError("Could not read IOKit media identities.")
    visit(nodes)
    return result


def mounted_volumes(entries, identifier):
    volumes = []
    for entry in entries:
        stores = entry.get("APFSPhysicalStores", [])
        associated = entry.get("DeviceIdentifier") == identifier or any(
            re.fullmatch(re.escape(identifier) + r"s[0-9]+", store.get("DeviceIdentifier", ""))
            for store in stores
        )
        if not associated:
            continue
        for volume in [entry] + entry.get("Partitions", []) + entry.get("APFSVolumes", []):
            if volume.get("MountPoint"):
                volumes.append(volume.get("VolumeName") or volume["MountPoint"])
            for snapshot in volume.get("MountedSnapshots", []):
                if snapshot.get("SnapshotMountPoint"):
                    volumes.append(snapshot["SnapshotMountPoint"])
    return tuple(sorted(set(volumes)))


def discover_usb_disks(source_path):
    protected = protected_disks(source_path)
    listing = read_plist([DISKUTIL, "list", "-plist"])
    external = read_plist([DISKUTIL, "list", "-plist", "external", "physical"])
    if not isinstance(listing, dict) or not isinstance(listing.get("AllDisksAndPartitions"), list):
        raise BootError("Could not read the disk list.")
    if not isinstance(external, dict) or not isinstance(external.get("WholeDisks"), list):
        raise BootError("Could not read the external physical disk list.")
    identities = media_ids()
    disks = []
    for identifier in external["WholeDisks"]:
        if not isinstance(identifier, str) or not WHOLE_DISK.fullmatch(identifier):
            raise BootError("macOS returned an invalid whole-disk identifier.")
        if identifier in protected:
            continue
        info = disk_info(identifier)
        if not (
            info.get("DeviceIdentifier") == identifier
            and info.get("DeviceNode") == f"/dev/{identifier}"
            and info.get("WholeDisk") is True
            and info.get("Internal") is False
            and info.get("VirtualOrPhysical") == "Physical"
            and info.get("BusProtocol") == "USB"
            and info.get("WritableMedia") is True
            and info.get("Writable") is True
        ):
            continue
        if info.get("RAIDMaster") or info.get("RAIDSlice") or info.get("CoreStorageLogical"):
            continue
        size = info.get("TotalSize")
        block_size = info.get("DeviceBlockSize")
        tree_path = info.get("DeviceTreePath")
        if not (
            type(size) is int and size > 0
            and type(block_size) is int and block_size > 0 and CHUNK_SIZE % block_size == 0
            and identifier in identities and isinstance(tree_path, str) and tree_path
        ):
            raise BootError(f"Could not establish a safe identity for {identifier}.")
        disks.append(UsbDisk(
            identifier, info.get("MediaName") or "USB drive", size, block_size,
            identities[identifier], tree_path, mounted_volumes(listing["AllDisksAndPartitions"], identifier),
        ))
    return disks


def select_disk(disks, iso):
    if not disks:
        raise BootError("No eligible USB drives found. Connect a writable USB drive and run again.")
    print("\nUSB drives:")
    for number, disk in enumerate(disks, 1):
        volumes = ", ".join(display(name) for name in disk.volumes) or "none"
        print(f"  {number}) {disk.device}  {display(disk.name)}  {human_size(disk.size)}  Volumes: {volumes}")
    while True:
        choice = input("Select a USB drive number, or q to cancel: ").strip()
        if choice.lower() == "q" or not choice:
            return None
        if (
            choice.isascii() and choice.isdigit()
            and len(choice) <= len(str(len(disks))) and 1 <= int(choice) <= len(disks)
        ):
            selected = disks[int(choice) - 1]
            if selected.size < iso.size:
                raise BootError("The selected USB drive is smaller than the ISO.")
            if iso.size % selected.block_size:
                raise BootError("The ISO size is not aligned to this drive's sector size.")
            return selected
        print("Enter a number from the list, or q to cancel.")


def confirm_erase(iso, disk):
    print(f"\nISO: {display(iso.path)} ({human_size(iso.size)})")
    print(f"USB: {disk.device}  {display(disk.name)}  {human_size(disk.size)}")
    print("This will erase all data on this USB drive.")
    phrase = f"ERASE {disk.identifier}"
    return input(f'Type "{phrase}" to continue: ') == phrase


def recheck_disk(selected, source_path, require_unmounted=False):
    disks = discover_usb_disks(source_path)
    current = next((disk for disk in disks if disk.identifier == selected.identifier), None)
    if current is None or current.identity != selected.identity:
        raise BootError("The selected USB drive changed or disappeared. Run again and select it again.")
    if require_unmounted and current.volumes:
        raise BootError("The selected USB drive still has mounted volumes. Nothing was written.")


def write_all(target, data):
    remaining = memoryview(data)
    while remaining:
        written = target.write(remaining)
        if written is None or written <= 0:
            raise BootError("The USB drive stopped accepting data.")
        remaining = remaining[written:]


def copy_image(source, target, iso):
    digest = hashlib.sha256()
    done = 0
    progress = Progress("Writing USB", iso.size)
    while done < iso.size:
        chunk = source.read(min(CHUNK_SIZE, iso.size - done))
        if not chunk:
            raise BootError("The ISO ended before the expected size.")
        write_all(target, chunk)
        digest.update(chunk)
        done += len(chunk)
        progress(done)
    if digest.hexdigest() != iso.digest:
        raise BootError("The ISO changed while writing. The USB is incomplete.")


def verify_image(source, iso):
    if hash_stream(source, iso.size, Progress("Verifying USB", iso.size)) != iso.digest:
        raise BootError("USB verification failed: the written data does not match the ISO.")


def flash_iso(iso, disk):
    writing_started = False
    verified = False
    try:
        # Keep the checked file open so pathname replacement cannot change the input.
        with open_source(iso.path) as source:
            before = os.fstat(source.fileno())
            if file_identity(before) != iso.identity:
                raise BootError("The ISO changed after verification. Nothing was written.")
            if hash_stream(source, iso.size, Progress("Rechecking ISO", iso.size)) != iso.digest:
                raise BootError("The ISO changed after verification. Nothing was written.")
            if file_identity(os.fstat(source.fileno())) != iso.identity:
                raise BootError("The ISO changed during verification. Nothing was written.")
            source.seek(0)
            recheck_disk(disk, iso.path)
            print(f"Unmounting {disk.device}...")
            run_command([DISKUTIL, "unmountDisk", disk.device])
            recheck_disk(disk, iso.path, require_unmounted=True)
            # Do not create or truncate a path if the device has disappeared.
            descriptor = os.open(disk.raw_device, os.O_RDWR | os.O_NOFOLLOW)
            with os.fdopen(descriptor, "r+b", buffering=0) as target:
                if not stat.S_ISCHR(os.fstat(target.fileno()).st_mode):
                    raise BootError("The destination is not a raw disk device. Nothing was written.")
                recheck_disk(disk, iso.path, require_unmounted=True)
                writing_started = True
                copy_image(source, target, iso)
                target.flush()
                fcntl.ioctl(target.fileno(), DKIOCSYNCHRONIZECACHE)
        if media_ids().get(disk.identifier) != disk.media_id:
            raise BootError("The USB drive changed before verification. Its contents were not verified.")
        # Disk Arbitration may have mounted newly discovered ISO volumes after writing.
        run_command([DISKUTIL, "unmountDisk", disk.device])
        if media_ids().get(disk.identifier) != disk.media_id:
            raise BootError("The USB drive changed before verification. Its contents were not verified.")
        descriptor = os.open(disk.raw_device, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(descriptor, "rb", buffering=0) as written:
            if not stat.S_ISCHR(os.fstat(written.fileno()).st_mode):
                raise BootError("The USB raw device disappeared before verification.")
            if media_ids().get(disk.identifier) != disk.media_id:
                raise BootError("The USB drive changed before verification. Its contents were not verified.")
            verify_image(written, iso)
        verified = True
        print("USB write verified.")
        if media_ids().get(disk.identifier) != disk.media_id:
            raise BootError("The USB drive changed before ejection. Eject it manually.")
        try:
            run_command([DISKUTIL, "eject", disk.device])
        except (BootError, OSError) as error:
            raise BootError(
                f"The installer was verified, but ejection failed. Eject the USB manually. {error}"
            ) from error
        print("Bootable USB created and ejected. You can remove it now.")
    except (OSError, BootError, KeyboardInterrupt):
        if writing_started and not verified:
            print(
                "\nThe USB was not verified and may contain an incomplete installer. Run again before using it.",
                file=sys.stderr,
            )
        raise


def checksum_argument(value):
    if not re.fullmatch(r"[0-9a-fA-F]{64}", value):
        raise argparse.ArgumentTypeError("SHA256 must contain exactly 64 hexadecimal characters.")
    return value.lower()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("iso", help="path to a hybrid Linux installer ISO")
    parser.add_argument("--sha256", type=checksum_argument, help="expected SHA256 from the ISO publisher")
    args = parser.parse_args(argv)
    try:
        if platform.system() != "Darwin":
            raise BootError("This script supports macOS only.")
        if not sys.stdin.isatty():
            raise BootError("Run this script in a terminal so you can select and confirm a USB drive.")
        iso = validate_iso(args.iso, args.sha256)
        print(f"ISO: {display(iso.path)} ({human_size(iso.size)})")
        print(f"SHA256: {iso.digest}")
        if args.sha256:
            print("Download checksum matched.")
        else:
            print("Download integrity was not checked against a publisher checksum.")
        if os.geteuid() != 0:
            print("Administrator access is required to write USB drives. Requesting sudo...", flush=True)
            command = ["/usr/bin/sudo", "--", sys.executable, str(Path(__file__).resolve()), str(iso.path)]
            if args.sha256:
                command += ["--sha256", args.sha256]
            result = subprocess.run(command, check=False)
            return result.returncode if result.returncode >= 0 else 130
        disks = discover_usb_disks(iso.path)
        selected = select_disk(disks, iso)
        if selected is None or not confirm_erase(iso, selected):
            print("Cancelled. Nothing was written.")
            return 0
        flash_iso(iso, selected)
        return 0
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.", file=sys.stderr)
        return 130
    except (BootError, OSError) as error:
        print(f"\nError: {display(error)}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
