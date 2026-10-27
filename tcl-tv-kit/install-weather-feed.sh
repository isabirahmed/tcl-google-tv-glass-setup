#!/usr/bin/env bash
# Build the headless weather feed app (local.tvweather) and install it on the TV.
# It is what the launcher's weather pill reads: it fetches Open-Meteo (weather, and air quality unless you gave it an IQAir
# key with set-aqi-key.sh) and publishes one row at content://local.tvweather/now. It has the INTERNET permission; the
# launcher does not.
#
# TCL's firmware (TclAppBoot) refuses to start a never-launched app's provider until the auto-start app-op is granted,
# so this grants it (and saves it to disk, or a reboot drops it). Without it the pill simply stays hidden.
#
# Usage:  TV_HOST=<tv ip> ./install-weather-feed.sh
# Needs:  JDK 17 and the Android SDK (platform 34), as for the launcher. Edit weather-feed/app/src/main/res/values/strings.xml
#         first to change the place.
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
cd "$KIT/weather-feed"
[ -f local.properties ] || echo "sdk.dir=${ANDROID_HOME:-$HOME/Library/Android/sdk}" > local.properties
./gradlew assembleRelease -q --console=plain
APK=app/build/outputs/apk/release/app-release.apk
"$REPO/tools/venv/bin/python" -I "$REPO/tools/b64push.py" "$APK" /data/local/tmp/feed.apk
# --force-queryable (Android 11+, only the ADB shell may use it) makes the feed visible to every app and is kept with the package.
# Without it, Android's package-visibility rules can refuse the launcher access to the feed's provider after a restart
# ("Failed to find provider info"), while the ADB shell, which skips those rules, still reads it. Older Android: plain install.
"$REPO/tools/tv.py" 'pm install -r --force-queryable /data/local/tmp/feed.apk || pm install -r /data/local/tmp/feed.apk; rm -f /data/local/tmp/feed.apk'
"$REPO/tools/tv.py" 'cmd appops set local.tvweather APP_AUTO_START allow; appops write-settings'
echo "Installed. Press Home on the TV; the weather pill appears within a few seconds."
