# Setup guide

The full procedure, with the checks to do at each step. Do the steps in order and stop at the first thing that surprises you: nothing here is urgent.
All commands run from `tcl-tv-kit/` after `../bootstrap.sh`, with `TV_HOST` set to your TV's address, unless a step says otherwise.

```bash
./bootstrap.sh                 # from the repository root
export TV_HOST=192.168.1.50    # your TV
cd tcl-tv-kit
TV=../cleanyourtv/tools/tv.py  # the ADB client the project ships (no adb binary needed)
```

## 0. Before you start

- **Turn on USB debugging** (Settings > System > Developer options). The TV asks you to allow the computer: accept it. Connect with `$TV --probe`.
- **Check the TV can take a launcher:**
  - `$TV 'getprop ro.build.version.sdk'` must be **26 or higher**.
  - The TV must accept sideloaded APKs. Some China-market sets answer every sideload with `INSTALL_FAILED_VERIFICATION_FAILURE`, and some refuse any package that
    declares the HOME category unless it carries the maker's signature. If yours does, do the debloat half only.
- **If your TV's network is a USB Ethernet adapter**, stop and read the upstream notes first: on some sets the USB port only works with USB debugging off, so
  turning it on can drop the network (and ADB with it).
- **Know what is plugged into the TV's USB ports.** A few devices lose power while USB debugging is on.
- **Back up first:**

  ```bash
  mkdir -p ../backup
  $TV 'pm list packages -f'  > ../backup/packages-all.txt
  $TV 'pm list packages -d'  > ../backup/packages-disabled-before.txt
  $TV 'getprop'              > ../backup/getprop.txt
  $TV 'settings list global' > ../backup/settings-global.txt
  $TV 'settings list secure' > ../backup/settings-secure.txt
  ```

  These files hold serial numbers and MAC addresses. Keep them private, and never commit them.

## 1. Debloat

The lists are in `debloat/`. Open each, read the comments, and comment out (`#`) anything you use. Notes on the ones people care about:

| Batch | What it switches off | Notes |
|---|---|---|
| 1 | TCL's analytics (`com.tcl.ttvs`), TGuard, feedback and partner attribution | `com.tcl.ttvs` also carries **TCL's firmware updater**. Comment it out if you want updates |
| 2 | TCL content, ads and promos (`waterfall`, `partnercustomizer`, `messagebox`, `usercenter`, `dashboard`, ...) | `usercenter` may come back at every boot on some firmware |
| 3 | Preloads: gallery, the USB media player, e-manual, notes, hearing aid, T-Cast, TalkBack, calendar sync | Re-enable `ui_mediaCenter` if you play from USB drives |
| 4 | Streaming apps the original owner did not use | **Personal choices.** Edit or delete this batch |
| 5 | The Google TV setup wizard (`setupwraith`) | See step 2 |
| 6 | The previous third-party launcher | Only if you had one; delete the batch otherwise |
| 7 | Google's ambient-mode screensaver | Do it only after the new screensaver is set |

`debloat/KEPT.txt` lists what was deliberately left on and why: Live TV and HDMI, the remote's helpers, Bluetooth pairing, the keyboard, Play Store and Play Services.
**Never** open a package whose name says factory, production or AT: on some boards that flips a flag you cannot flip back.

```bash
./apply-debloat.sh 1 2 3 4     # one batch at a time is better; take a screenshot between them:
$TV --screenshot shot.png HOME
```

Live TV, HDMI and some streaming apps give an empty screenshot: that is the TV, not damage.

## 2. The setup wizard (batch 5)

On Google TV the setup wizard's recovery screen can claim Home once the stock launcher is off. But a Wi-Fi network saved during first setup **belongs to the wizard**, and
Android deletes it the moment the wizard is disabled, which takes the TV off Wi-Fi and ADB with it. So:

```bash
$TV "dumpsys wifi | grep -o 'cname=[^ ]*' | sort | uniq -c"
$TV 'cmd wifi list-networks'
```

If any network belongs to `setupwraith`, forget it in the TV's Settings and join it again by typing the password, until it belongs to `android.uid.system`. A leftover old
network can be removed with `$TV 'cmd wifi forget-network <id>'` (read the id from `list-networks`, and never forget the one you are using). Then `./apply-debloat.sh 5`.
Whether the disable survives a reboot depends on the firmware build, so reboot once afterwards and check Home before you go on.

## 3. The launcher

Edit `cleanyourtv/launcher/app/src/main/res/values/config.xml` first. At least these:

- `dock_apps`: the apps in the row, in order (package names).
- `hidden_apps`: everything else you want kept off Home (they stay in the app library).
- `app_keys`: your remote's app buttons.
- `live_tv_package`: `com.tcl.tv` on this TV.

Then:

```bash
./install-launcher.sh
$TV 'dumpsys activity activities | grep mFocusedApp'      # must name com.gathin.tvhome
$TV 'dumpsys accessibility | grep "Bound services"'        # the key helper must be listed
```

The script builds the APK, installs it, starts it, and **only then** disables the stock launcher; if Home does not move it puts the stock launcher back. The first build
downloads Gradle and the libraries, which takes a few minutes. The remote-key helper makes the coloured app buttons and the gear work now that the stock launcher is off.
Press every button on the real remote: an injected key is not proof for a button that goes through an accessibility helper.

## 4. Weather

Set your place in `weather-feed/app/src/main/res/values/strings.xml` (`place`, `latitude`, `longitude`: look your city up on a map or with
[Open-Meteo's geocoding API](https://open-meteo.com/en/docs/geocoding-api)), then `./install-weather-feed.sh`. The pill appears under the date within a few seconds.
If it does not, see [troubleshooting](troubleshooting.md).

## 5. Wallpapers

```bash
../cleanyourtv/tools/theme.sh theme
```

pushes `theme/` (the pictures in `theme/wallpapers/` and `theme/config.json`) to the TV and restarts Home. To use your own, replace the pictures: JPEG, PNG or WebP, 16:9, about
1920x1080, names with only letters, digits, `-`, `_` and `.`. Edit `wallpaper_rotation_minutes` (a new picture every N minutes, only while Home is on screen) and `wallpaper_dim`
(0 to 90, the black overlay that keeps text readable on bright pictures). **After a theme push, check the remote's app buttons**: restarting Home can leave the key helper unbound
until a reboot or a re-run of `./install-launcher.sh`.

## 6. The photo screensaver

The screensaver is the project's `photo-screensaver` add-on, used unmodified.

```bash
bash ../cleanyourtv/addons/photo-screensaver/build-and-install.sh
SECONDS_PER_PICTURE=20 bash ../cleanyourtv/addons/photo-screensaver/sync.sh /path/to/your/pictures
$TV 'am start -n com.gathin.photodream/.SettingsActivity'     # then switch on "Show the time and date" with the remote
```

Pictures: JPG, PNG or WebP up to 10 MB each, at most 100 files. The TV starts it on its own idle timer (`$TV 'settings get system screen_off_timeout'`), and **Back on Home**
starts it too. With Google's own ambient mode (`dreamx`) disabled in batch 7, this replaces it. Undo with `sync.sh --off`.

## 7. Optional: ad-blocking Private DNS

```bash
$TV 'settings put global private_dns_specifier dns.adguard-dns.com'
$TV 'settings put global private_dns_mode hostname'
```

It does **not** block YouTube ads. It also bypasses any DNS filtering your router does (a Pi-hole, AdGuard Home or a VPN with domain lists), so skip it if you have one. Undo:
`$TV 'settings put global private_dns_mode opportunistic'`.

## 8. Reboot and check

Reboot once, then check: Home is the new launcher, the pill is back, the remote's buttons work, Back on Home starts the screensaver, and
`$TV 'pm list packages -d'` matches what it was before the reboot (some firmware re-enables a few packages at boot; note those instead of disabling them again).

## 9. Close ADB

Network ADB on port 5555 is plaintext. When you are done: Settings > System > Developer options, **Revoke USB debugging authorizations**, turn **USB debugging** off,
restart the TV, then check from your computer:

```bash
../cleanyourtv/tools/venv/bin/python -I ../cleanyourtv/tools/adb-closed.py $TV_HOST     # must say the TV refused the connection
```

## Undo

`./restore.sh` re-enables every package (except the ones that were already disabled at the factory), gives Home back to the stock launcher, restores Google's screensaver and
sets Private DNS back to automatic. It needs the undo records the debloat scripts wrote to `~/.cleanyourtv/`, so run it from the same computer. Before a factory reset, run it too:
the setup wizard has to be enabled again first.
