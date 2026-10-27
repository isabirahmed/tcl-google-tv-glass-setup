# Notices and third-party material

## This repository

Code, patch, scripts, debloat lists and documentation: MIT, Copyright (c) 2026 Sabir Ahmed. See `LICENSE`.
That licence covers only what was written for this repository. It does **not** cover the third-party material below, which keeps its own licence: in particular the wallpaper photographs (CC BY / CC BY-SA) and the Clean Your TV project this patch is applied to (MIT, by its own author).

## Clean Your TV (the base project)

`tcl-tv-kit/launcher-local-changes.patch` modifies, and `bootstrap.sh` downloads, the [Clean Your TV](https://github.com/Gathin23/cleanyourtv) project,
Copyright (c) 2026 Gathin, MIT licence. Its licence text is in `licenses/Clean-Your-TV-MIT.txt`. The patch contains lines of upstream source as context, so that notice applies to it too.
The photo screensaver add-on and the other upstream tools used by the scripts come from that project, unmodified.

## Wallpaper photographs

`tcl-tv-kit/theme/wallpapers/` holds 18 photographs from **Wikimedia Commons**, cropped to 16:9 and resized to 1920x1080 (an adaptation). They are **not** covered by this repository's MIT licence.
Each keeps the licence its author chose (CC BY 2.0, CC BY 4.0, CC BY-SA 3.0 or CC BY-SA 4.0), and the adapted files are shared under that same licence. The author, title, licence and source page of
every picture is in `tcl-tv-kit/theme/CREDITS.txt`. If you reuse them, keep that credit file with them and follow the licence of each picture.
The screenshots in `docs/screenshots/` show some of these photographs behind the interface and carry the same credits.

## Typeface

The app names on the cards and in the app library are set in **Inter** (Copyright The Inter Project Authors, https://github.com/rsms/inter), licensed under the SIL Open Font License 1.1.
The patch adds it as `res/font/inter.ttf`, a modified copy (one fixed Medium weight, trimmed to Latin and Vietnamese letters), together with its licence text as `launcher/FONT-LICENSE-INTER.txt`.
Apple's own SF Pro is not used or included: its licence does not allow bundling it in an app like this. The rest of the launcher keeps the Outfit font it already ships with (SIL OFL 1.1).

## Logos and trademarks

The three logo shapes in `tcl-tv-kit/icons/dl/` (YouTube, Stremio, Surfshark) are from [Simple Icons](https://simpleicons.org/) (CC0); the other tile logos are simple originals drawn for this project.
The brands, product names and logos they show (YouTube, Google, Google TV, Android TV, Google Play, Netflix, Stremio, Surfshark, TCL, Apple, Apple TV and others) are trademarks of their owners and are
used only to identify the apps on the screen. This project is not affiliated with, sponsored by or endorsed by any of them, and "Apple TV-inspired" describes a visual style only.

## Services and data

- **Open-Meteo.com**: weather and air-quality data, CC BY 4.0 ([open-meteo.com](https://open-meteo.com/)). The free API is for non-commercial use; read their terms if you change how it is used.
- **IQAir (AirVisual)**: optional. You use your own API key under your own account and their terms. No key is included or stored in this repository.

## Build tooling

`tcl-tv-kit/weather-feed/gradlew`, `gradlew.bat` and `gradle/wrapper/` are the standard Gradle wrapper (Apache License 2.0, the Gradle project), copied from the upstream project's weather add-on.
