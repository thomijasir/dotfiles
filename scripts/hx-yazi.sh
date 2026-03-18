# ~/.local/bin/hx-yazi  (make sure this is on your PATH; chmod +x it)
#!/usr/bin/env sh
sel="$1" # file path from Helix (may be empty or non-existent)
out="${2:-/tmp/unique-file}"

# If sel is a real file/dir -> pass it to yazi (file will be revealed, dir opens)
# Else -> open current directory (.)
if [ -n "$sel" ] && [ -e "$sel" ]; then
  exec yazi "$sel" --chooser-file="$out"
else
  exec yazi . --chooser-file="$out"
fi
