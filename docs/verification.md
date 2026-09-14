# Verification notes

## Tested environment

Apple M3, 8 GB unified memory, macOS 15.6.1. macOS AIR SDK release 51.3.4.3; bundled runtime Info.plist reports 51.3.4.2. This is a tested configuration, not a claim of support for every Mac or SDK release.

The maintainer reported a real play session on 2026-09-14: the application ran well and no issues were noticed. This is user acceptance for the observed session. It does not establish exhaustive physical-key rollover, gamepad, speaker, focus, networking, or every-character move coverage.

## Recorded checks before publication

- Original 695-file package and original save remained unchanged.
- Imported original payload remained byte-for-byte unchanged through packaging; adapter code and platform configuration were recorded separately.
- Basic integration coverage: 99 concrete fighter/form IDs, 52 assists, 12 maps with completed matches, 14 local mode flows, and 10 mission-referenced NPC types. Random selection and two Itachi alternates were also exercised in the original UI.
- Fourteen same-input cases compared a Mac AIR reference with original I/O against the captive-runtime compatibility adapter. Representative damage, combo routes, qi, and transformation results agreed. These were not Windows-reference tests.
- Three fixed movement trials had identical geometric ranges and sampled airborne-duration differences of at most 3.2%. Wrapper sampling does not establish one-internal-tick parity or physical input latency.
- Three cold starts and an additional restored-state launch from the delivery directory; configuration save/restart and archive/signature checks.
- Actual AIR storage checks used isolated seeded and unseeded application IDs, plus Python import/build boundary tests.

The integration harness is visibly marked as diagnostic. It uses synthetic AIR key events, explicit fixtures and sampled state; those results are not human handfeel evidence. A 45-second character smoke test is not a completed match. The retained local evidence includes test logs, content coverage, and build manifests; private paths and game-derived payloads are not published here.

## Known limits

- Original package references missing `assetss/bgm/naruto.m3` and `assetss/bgm/winloop.m3`. No replacement tracks were invented.
- An original transformed-Ichigo teardown error was observed under ADL during diagnostic work; the movement reference was repeated in fresh processes. This is not silently counted as a clean result.
- Not every possible move, character pairing, keyboard, controller or macOS release has been tested.
- Local signing is ad hoc. There is no Apple Developer ID signature or public notarization.
- The playable release contains the original game payload and captive runtime; personal save files and development artifacts are excluded. The source tree and release archive have different contents, described in THIRD_PARTY_NOTICES.md.

Icon and application-name changes do not alter the original game payload or application storage ID. Their acceptance requires a rebuilt bundle with matching payload hashes, valid local signature, embedded icon metadata and a real launch; the earlier combat checks remain scoped to the unchanged gameplay payload.
