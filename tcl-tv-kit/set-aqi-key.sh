#!/usr/bin/env bash
# Give the TV's weather feed YOUR IQAir (AirVisual) API key, so the air-quality number is IQAir's station reading
# instead of Open-Meteo's satellite-model estimate (the model reads high in Dubai: 128 against ~87 from stations).
#
# YOU run this and YOU type the key: it is read from your keyboard without echo, checked for the right shape
# (36 characters: hex digits and dashes), and sent straight to the TV. It is never written to a file, to the
# project, or to the screen. (It is briefly visible in the process list of this computer and of the TV, so use a
# machine only you use.) The launcher never receives it either: it only gets the number.
#
# Usage:  TV_HOST=<tv ip> ./set-aqi-key.sh            ask for the key and store it
#         TV_HOST=<tv ip> ./set-aqi-key.sh --remove   forget the key (back to the Open-Meteo model value)
# ADB must be on (Developer options > USB debugging).
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$KIT/../cleanyourtv}"
: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.0.50 $0}"
export TV_HOST
if [ "${1:-}" = "--remove" ]; then
  ARG=clear
else
  read -r -s -p "Paste your IQAir API key (hidden), then press Enter: " ARG
  echo
fi
if [ "$ARG" != clear ] && ! printf '%s' "$ARG" | grep -Eq '^[0-9a-fA-F-]{36}$'; then
  echo "That does not look like an IQAir key (36 characters: 0-9, a-f and dashes). Nothing was sent." >&2
  exit 1
fi
"$REPO/tools/tv.py" "content call --user 0 --uri content://local.tvweather --method set_key --arg $ARG"
echo "Done. Press Home on the TV; the number updates within a few seconds."
