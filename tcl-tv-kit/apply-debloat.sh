#!/usr/bin/env bash
# Disable the packages in this TV's debloat batches (never uninstalls; undo with ./restore.sh).
#
# Usage:  TV_HOST=<tv ip> ./apply-debloat.sh            batches 1-4 (telemetry, TCL content/ads, preloads, unused apps)
#         TV_HOST=<tv ip> ./apply-debloat.sh 5          one or more batches by number
#
# Batches (lists are in cleanyourtv/work/):
#   1 telemetry and analytics          2 TCL content, ads and promos      3 preloaded apps not used
#   4 streaming apps you don't use     5 setup wizard (before the launcher; forget its Wi-Fi network first)
#   6 Projectivy (after the launcher)  7 Google ambient screensaver (after the launcher + clock screensaver set)
# Batches 5-7 depend on the new launcher; they're listed here for completeness, run them in that order.
# Take a screenshot between batches:  cleanyourtv/tools/tv.py --screenshot shots/x.png HOME
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$KIT/../cleanyourtv}"
: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.0.50 $0}"
export TV_HOST
[ "$#" -gt 0 ] || set -- 1 2 3 4
for n in "$@"; do
  f=$(ls "$REPO"/work/batch"$n"-*.txt 2>/dev/null | head -n 1) || true
  [ -n "${f:-}" ] || { echo "no batch $n in $REPO/work" >&2; exit 1; }
  echo "== batch $n: $(basename "$f")"
  "$REPO/tools/disable.sh" "$f"
done
