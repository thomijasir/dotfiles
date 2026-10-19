#!/usr/bin/env python3
"""Find reusable Mozilla APT sources without editing existing configuration."""

import re
import shlex
import sys
from pathlib import Path
from urllib.parse import urlsplit


def find_mozilla_sources(apt_dir):
    sources = []
    paths = [apt_dir / "sources.list"]
    paths += sorted((apt_dir / "sources.list.d").glob("*.list"))
    paths += sorted((apt_dir / "sources.list.d").glob("*.sources"))
    for path in paths:
        if not path.exists():
            continue
        text = path.read_text()
        entries = []
        if path.suffix == ".sources":
            for block in re.split(r"\n\s*\n", text):
                fields = {}
                current = None
                for line in block.splitlines():
                    if not line.strip() or line.lstrip().startswith("#"):
                        continue
                    if line[0].isspace() and current:
                        fields[current] += " " + line.strip()
                    elif ":" in line:
                        current, value = line.split(":", 1)
                        current = current.lower()
                        fields[current] = value.strip()
                if fields.get("enabled", "yes").lower() == "no":
                    continue
                if "deb" not in fields.get("types", "").split():
                    continue
                entries.append((
                    fields.get("uris", "").split(),
                    fields.get("suites", "").split(),
                    fields.get("components", "").split(),
                    fields.get("signed-by", ""),
                    fields,
                ))
        else:
            for line in text.splitlines():
                match = re.match(r"^\s*deb\s+(?:\[([^\]]*)\]\s+)?(\S+)\s+(\S+)\s+([^#]+)", line)
                if not match:
                    continue
                options, uri, suite, components = match.groups()
                fields = dict(item.split("=", 1) for item in shlex.split(options or "") if "=" in item)
                entries.append(([uri], [suite], components.split(), fields.get("signed-by", ""), fields))
        for uris, suites, components, key, fields in entries:
            if not any(urlsplit(uri).hostname == "packages.mozilla.org" for uri in uris):
                continue
            if (
                len(uris) != 1
                or uris[0].rstrip("/") != "https://packages.mozilla.org/apt"
                or suites != ["mozilla"]
                or components != ["main"]
                or not key.startswith("/")
                or any(char.isspace() for char in key)
                or any(fields.get(option, "no").lower() != "no" for option in (
                    "trusted", "allow-insecure", "allow-weak", "allow-downgrade-to-insecure",
                ))
            ):
                raise ValueError(f"Conflicting Mozilla APT source: {path}. Use HTTPS, mozilla/main, and one Signed-By key file.")
            sources.append((str(path), key))
    return sources


if __name__ == "__main__":
    try:
        for source, key in find_mozilla_sources(Path(sys.argv[1] if len(sys.argv) > 1 else "/etc/apt")):
            print(f"{source}\t{key}")
    except (OSError, ValueError) as error:
        sys.exit(str(error))
