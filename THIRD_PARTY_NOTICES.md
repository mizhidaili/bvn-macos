# Third-party notices and asset scope

## Original game and API compatibility

Bleach vs. Naruto is made by 剑 jian and 5DPLAY Game Studio. The upstream project is available at <https://github.com/5DPLAY-Game-Studio/BleachVsNaruto> and identifies its code license as GNU GPL version 3 or later. This community project is not an official release or an endorsement by that team.

The compatibility classes retain the original package names and callable interfaces so the user's compiled game can call the storage adapters. This repository's adapter and diagnostic code is distributed under GPL-3.0-or-later; preserve applicable notices when redistributing modifications. Original game bytecode and assets are not included. The exact local competitive variant is not assumed to match the upstream source tree or its component licenses.

## User-supplied game files

Game SWF/packed bytecode, fighter sprites, character illustrations, animation, music, voices, save files, and the original Windows distribution are excluded from this repository and its published source release. Obtain and use those materials under their applicable permissions. The repository license does not grant rights to any excluded material or to franchise trademarks.

## AIR and other tooling

AIR SDK and runtime are provided separately by their vendor under their own terms: <https://airsdk.harman.com/>. A developer must supply an appropriately licensed macOS SDK. The public repository does not bundle the SDK, runtime, signing certificates, Java, or a compiled game application. Any future runtime redistribution needs a separate review of the applicable terms.

Python build scripts use the standard library. `sips`, `iconutil`, and `codesign` are macOS system tools, invoked locally and not redistributed.

## Application icon

`assets/app-icon.png` is an AI-generated original raven-and-crimson icon created for this project with the built-in OpenAI image generation tool. It does not use an extracted game image or franchise crest. `assets/AppIcon.icns` is its macOS packaging, produced with `sips` and `iconutil`.

To the extent the project maintainers hold licensable rights in this generated icon, it is provided under GPL-3.0-or-later with the project. No exclusive ownership or trademark rights in the generated design are asserted. Its prompt and conversion method are recorded in `docs/icon.md`.
