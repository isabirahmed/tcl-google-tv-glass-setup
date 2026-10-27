#!/usr/bin/env bash
# Build the launcher from the repo and install it on the TV as Home, with the remote-key helper on.
# Everything about this TV's launcher (5 dock slots, the dock apps and their order, the hidden Live TV tile,
# the remote buttons mapped to Stremio/YouTube/Settings, the volume fix) lives in ONE file:
#     cleanyourtv/launcher/app/src/main/res/values/config.xml
# (the exact changes against the original are in launcher-config.patch). Edit it, then run this script again.
#
# Usage:  TV_HOST=<tv ip> ./install-launcher.sh
#
# Needs: JDK 17 and the Android SDK (platform 34, build-tools 34.0.0). This Mac has them at the defaults below.
# Order the script keeps: new launcher installed and started FIRST, stock launcher disabled only if Home really
# resolves to the new one (it rolls the stock launcher back otherwise). On a fresh TV run batch 5 first:
#     ./apply-debloat.sh 5      (needs the saved setup-wizard Wi-Fi network forgotten, see README)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$KIT/../cleanyourtv}"
: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.0.50 $0}"
export TV_HOST
# JDK 17 and the Android SDK: use yours if set; else the usual Mac spots when they exist; else the launcher's own build script looks.
if [ -z "${JAVA_HOME:-}" ]; then
  for j in /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home /opt/homebrew/opt/openjdk@17; do [ -x "$j/bin/javac" ] && { export JAVA_HOME="$j"; break; }; done
fi
if [ -z "${ANDROID_HOME:-}" ] && [ -d "$KIT/../android-sdk" ]; then export ANDROID_HOME="$(cd "$KIT/.." && pwd)/android-sdk"; fi
# HomeKeyService is what makes the remote's Netflix / Prime Video / Media / YouTube / gear buttons work now that the
# stock launcher is off (consume_volume_keys in config.xml keeps volume at one step per tap). Android switches the
# helper off on every reinstall, so it is passed every time.
export HOME_KEY_SERVICE=1
exec "$REPO/launcher/build-and-install.sh"
