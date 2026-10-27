# Troubleshooting

`tv.py` below is `cleanyourtv/tools/tv.py` with `TV_HOST` set.

Things that actually happened while building this on a TCL Smart TV Pro (`G05_4K_GB`, Android 11, AR25). For anything about the base project, see the upstream
`docs/TROUBLESHOOTING.md` in `cleanyourtv/` after bootstrap.

## Home is black, or shows a recovery screen, after the stock launcher is disabled

The Google TV setup wizard (`com.google.android.tungsten.setupwraith`) answers the HOME category with a recovery activity at higher priority than anything else.
`install-launcher.sh` refuses to disable the stock launcher unless Home resolves to the new one, and rolls back if it does not. If you are stuck anyway (you need ADB):

```bash
tv.py 'pm enable com.google.android.apps.tv.launcherx'
tv.py 'pm enable com.google.android.tungsten.setupwraith'
tv.py 'cmd package set-home-activity --user 0 com.google.android.apps.tv.launcherx/.home.HomeActivity'
```

## The TV dropped off Wi-Fi after disabling the setup wizard

The saved Wi-Fi network belonged to the wizard, and Android deletes a disabled app's networks. Re-join the network in Settings (with a keyboard or the phone remote), or re-enable the wizard
(`pm enable com.google.android.tungsten.setupwraith`). Next time, forget and re-join the network *before* disabling it (guide, step 2).

## The remote's app buttons or the gear do nothing

They go through an accessibility helper (`HomeKeyService`). Check it is enabled **and bound**:

```bash
tv.py 'dumpsys accessibility | grep -E "Bound services|Enabled services"'
```

`Bound services:{}` means it is enabled but not running. Reinstalling the launcher, force-stopping it, or pushing a theme can leave it that way. Re-run `./install-launcher.sh` (it re-enables the
helper), or reboot. An injected key (`input keyevent`) is **not** proof for these buttons: press the real remote.

## Volume goes up two steps per press

With a key-filtering helper bound, this TV applies the volume key once itself and once when the helper hands it back. `consume_volume_keys` is on in the shipped `config.xml` for that reason.
Holding the key should still ramp. If your remote behaves differently, turn it off.

## The weather pill never appears

1. Is the feed installed, and may it start? `tv.py 'pm list packages local.tvweather'`, then `tv.py 'appops get local.tvweather APP_AUTO_START'` should say `allow`.
2. Ask the feed directly: `tv.py 'content query --user 0 --uri content://local.tvweather/now'`. The first call may return nothing while it fetches; ask again after a few seconds.
3. `Could not find provider` means TCL's boot manager blocked it: `tv.py 'appops set local.tvweather APP_AUTO_START allow; appops write-settings'`.
4. No network, or Private DNS blocking Open-Meteo, shows nothing rather than stale numbers (data older than 6 hours is hidden).

## The Wi-Fi button just says "Wi-Fi" instead of the network name

Android hides the network name from apps while **Location** is off. Turn Location on in the TV's settings if you want the name (a privacy trade-off).

## Wallpapers do not change

They advance only while Home is on screen, in steps of `wallpaper_rotation_minutes`. After a long time in an app, Home moves on by one picture when you come back, not by one per elapsed interval.
A picture that is still over about 8.4 million pixels after being scaled down is skipped.

## The air quality number differs from my phone

See "Why the index can differ" in [how-it-works](how-it-works.md). Use `./set-aqi-key.sh` for a station reading.

## A package came back after a reboot

Some TCL firmware re-enables a few packages at boot (`com.tcl.usercenter`, `com.tcl.smartalexa`, and on some builds others). Note them rather than disabling them again every time.
Compare `pm list packages -d` before and after a reboot.

## I want to start over

`./restore.sh`, then reboot. If you lost the undo records (`~/.cleanyourtv/`), the upstream project's recovery notes explain how to re-enable the packages in a list by hand.

## Not exercised

Honest list of what the author did not test: other TVs and firmware; the library's hold-OK options menu on a real remote; the setup from a factory-fresh TV in one run (each step was run
and checked on the live TV, and the package was rebuilt from a clean clone, but not replayed end to end on a second TV).
