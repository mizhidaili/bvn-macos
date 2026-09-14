# Third-party notices and asset scope

## Original game and API compatibility

Bleach vs. Naruto is made by 剑 jian and 5DPLAY Game Studio. The upstream project is available at <https://github.com/5DPLAY-Game-Studio/BleachVsNaruto> and identifies its code license as GNU GPL version 3 or later. This community project is not an official release or an endorsement by that team.

The compatibility classes retain the original package names and callable interfaces so the compiled game can call the storage adapters. This repository's adapter and diagnostic code is distributed under GPL-3.0-or-later; preserve applicable notices when redistributing modifications. The exact local competitive variant is not assumed to match the upstream source tree or its component licenses.

## Playable release and source tree

The downloadable macOS application contains the original game bytecode, fighter sprites, character illustrations, animation, music and voices from the maintainer-supplied game package. The game payload is unchanged. Personal saves, logs and development credentials are excluded from the release.

The Git source tree contains the macOS adapters, build tools, tests and icon; it does not contain the original game payload or the Windows distribution. The original game, Naruto and Bleach characters, and their artwork and audio retain their respective authorship and rights. This project's GPL notice applies to its adapter code and other stated contributions, not as a blanket license for third-party game assets or franchise trademarks.

## AIR and other tooling

The playable macOS application includes the AIR captive runtime and retains its embedded vendor notices. AIR is provided by HARMAN under its own terms: <https://airsdk.harman.com/>. The runtime is not relicensed under this project's GPL notice. The development SDK, Java and signing keys are not included in the release or source tree; developers building from source supply their own SDK.

Python build scripts use the standard library. `sips`, `iconutil`, and `codesign` are macOS system tools, invoked locally and not redistributed.

## Application icon

`assets/app-icon.png` is newly AI-generated fan artwork depicting Itachi Uchiha from Masashi Kishimoto's Naruto, created for this project with the built-in OpenAI image generation tool. No game image was extracted. The character and depicted franchise insignia are not original to this project. `assets/AppIcon.icns` is its macOS packaging, produced with `sips` and `iconutil`.

To the extent the project maintainers hold licensable rights in this generated image, those contributions are provided under GPL-3.0-or-later with the project. No ownership of the underlying character or franchise trademarks is asserted or granted. Its prompt and conversion method are recorded in `docs/icon.md`.
