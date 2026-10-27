# A prompt for your coding agent

Paste this into Claude Code (or a similar agent that can run shell commands) in the folder where you unpacked this package. It asks the
agent to reproduce the setup on *your* TV, step by step and asking you first. The safety rules matter: keep them.

---

I want to debloat my Android/Google TV and give it the home screen from this package (`README.md`, `tcl-tv-kit/`). My TV is: <model and
Android version>. The TV's IP is <ip>. Work on the real TV, step by step, and check every change with a screenshot pulled from the TV.
Ask me before anything that depends on my preferences.

Rules (not negotiable):
1. Run `./bootstrap.sh`, read `README.md` and `cleanyourtv/PROMPT.md` and `AGENTS.md` fully first. Use `cleanyourtv/tools/` instead of writing new tools.
2. **Back up first**: package list, disabled list, `getprop`, settings, into a backup folder, before any change.
3. **Disable, never uninstall** (`pm disable-user --user 0`, one package per call, small batches, a screenshot between batches). Never touch the
   TV/HDMI/tuner/input/remote/Bluetooth/keyboard/Play Store/Play Services packages or Android's core packages. Never launch a package whose
   name says factory/production/AT.
4. The lists in `tcl-tv-kit/debloat/` were made for one TCL model. **Do not apply them blindly to a different TV**: for each package read
   `dumpsys package <name>`, then ask me about anything unclear, and about streaming apps, the voice assistant, casting and the firmware updater.
5. Check that the TV accepts sideloaded APKs and its SDK level is at least 26 before building anything. If it doesn't, stop at the debloat.
6. Install the launcher with `tcl-tv-kit/install-launcher.sh`; never disable the stock launcher before the new one is confirmed as Home.
   Before disabling the setup wizard, check which saved Wi-Fi network it owns (README step 3).
7. Ask me for my dock apps and their order, my place for the weather, and my wallpaper and screensaver pictures. Never enter my passwords or API keys
   anywhere; I run `set-aqi-key.sh` myself.
8. Verify with key presses and screenshots, then reboot once and verify again. Ask me to press the real remote's buttons.
9. At the end: give me the restore script and a README of what changed, switch USB debugging off, revoke the authorisations, reboot, and check
   `tools/adb-closed.py` reports the port closed. Warn me before anything that needs USB debugging on a TV whose network is a USB Ethernet adapter.

---
