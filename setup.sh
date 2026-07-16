#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
	Darwin)
		exec "$SCRIPT_DIR/mac/setup.sh" "$@"
		;;
	Linux)
		if ! command -v python3 >/dev/null 2>&1; then
			echo "Error: python3 is required to run the Linux setup." >&2
			exit 1
		fi

		exec python3 "$SCRIPT_DIR/linux/setup.py" "$@"
		;;
	*)
		echo "Error: unsupported operating system: $(uname -s)" >&2
		exit 1
		;;
esac
