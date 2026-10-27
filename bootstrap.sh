#!/usr/bin/env bash
# Prepare this folder: clone Clean Your TV at the exact commit this setup was made against, apply the local launcher changes, put
# the debloat lists where the scripts expect them, and make the Python environment the ADB client needs. Run it once, from here.
#
# Usage:  ./bootstrap.sh
# Needs:  git, python3. It changes nothing on your TV.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_URL="https://github.com/Gathin23/cleanyourtv"
COMMIT="b06ab21105c49900cb1ed76b24414dba1e21d0db"   # the upstream commit the patch applies to
DEST="$HERE/cleanyourtv"

command -v git >/dev/null || { echo "git is needed" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is needed" >&2; exit 1; }

if [ -e "$DEST" ]; then
  echo "$DEST already exists: leaving it alone. Delete it to start over." >&2
  exit 1
fi
git clone "$REPO_URL" "$DEST"
git -C "$DEST" checkout --quiet "$COMMIT"
# The patch includes the new files (git diff with intent-to-add), so one apply does it all. --check first: nothing half-applied.
git -C "$DEST" apply --check "$HERE/tcl-tv-kit/launcher-local-changes.patch"
git -C "$DEST" apply "$HERE/tcl-tv-kit/launcher-local-changes.patch"
mkdir -p "$DEST/work"
cp "$HERE"/tcl-tv-kit/debloat/*.txt "$DEST/work/"
python3 -m venv "$DEST/tools/venv"
"$DEST/tools/venv/bin/pip" install -q -r "$DEST/tools/requirements.txt"
chmod +x "$HERE"/tcl-tv-kit/*.sh
echo
echo "Ready. Next:  export TV_HOST=<your tv ip>;  cd tcl-tv-kit  and follow README.md from step 1."
echo "Edit cleanyourtv/launcher/app/src/main/res/values/config.xml first (the apps in the row, the remote buttons, ...)."
