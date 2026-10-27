#!/usr/bin/env bash
# Put the TCL TV back the way it was before the cleanup: every package re-enabled (apart from the ones that
# were ALREADY disabled at the factory, which the undo records remember), Home handed back to the stock Google TV
# launcher, the Google ambient-mode screensaver restored, Private DNS back to automatic, and the new launcher's
# remote-key helper switched off.
#
# Usage:  TV_HOST=<tv ip> ./restore.sh          (ADB must be on again: Developer options > USB debugging)
#
# It replays the seven batches in reverse order through the repo's own tools/restore.sh, which uses the records
# in ~/.cleanyourtv/ (copies are in ./records/). The lists stay in cleanyourtv/work/: the records are keyed to
# those exact paths, so do not move them.
#
# Not restorable by script: the saved Wi-Fi network that the setup wizard owned. Re-join it in Settings if you
# want it back. The network the TV is actually on was never touched.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
REPO="${REPO:-$KIT/../cleanyourtv}"
LISTS="$REPO/work"
: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.0.50 $0}"
export TV_HOST
STOCK=com.google.android.apps.tv.launcherx
tv() { "$REPO/tools/tv.py" "$@"; }

echo "Restoring packages (batch 7 first, batch 1 last). Each step re-enables the stock launcher and points Home at it."
for f in batch7-dreamx batch6-projectivy batch5-setupwraith batch4-apps batch3-preloads batch2-content batch1-telemetry; do
  echo "== $f"
  "$REPO/tools/restore.sh" "$LISTS/$f.txt" "$STOCK"
done

echo "== screensaver back to Google ambient mode"
tv 'settings put secure screensaver_components com.google.android.apps.tv.dreamx/.service.Backdrop'

echo "== Private DNS back to automatic"
tv 'settings put global private_dns_mode opportunistic'

echo "== remote-key helper of the new launcher off, new launcher disabled (not uninstalled)"
tv 's=$(settings get secure enabled_accessibility_services); n=$(echo "$s" | sed "s#com.gathin.tvhome/com.gathin.tvhome.HomeKeyService##; s#::#:#g; s#^:##; s#:\$##"); if [ -z "$n" ]; then settings delete secure enabled_accessibility_services; else settings put secure enabled_accessibility_services "$n"; fi'
tv 'pm disable-user --user 0 com.gathin.tvhome'

echo "== check"
tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -n 1'
echo "Home should read com.google.android.apps.tv.launcherx/... above. Reboot the TV once to be sure."
echo "To bring the new launcher back later: ./install-launcher.sh (it re-enables itself and takes Home)."
