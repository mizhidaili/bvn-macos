# Application icon

Generated with the built-in OpenAI image generation tool on 2026-09-14. No source images were supplied. The actual PNG is preserved in `assets/app-icon.png`; `scripts/build_icon.py` creates 16, 32, 128, 256 and 512 point variants at 1x/2x with Apple sips and packages them with iconutil. The build installs `AppIcon.icns`, sets `CFBundleIconFile`, and signs the app after these changes.

## Generation prompt

Use case: logo-brand. Create one finished macOS application icon for a community-made classic anime fighting game compatibility app called BVN Mac. Original symbolic artwork inspired by the user's favorite character's crow motif: a bold silver-black raven in profile with one deep crimson eye and a restrained red crescent/rising moon behind it, forming a strong compact graphic silhouette. Premium macOS game icon, dark charcoal rounded-square tile with very subtle dimensional bevel and soft lighting, high contrast, clean deliberate shapes, restrained crimson glow, beautiful at 32px as well as 1024px. Center composition, tile occupies about 84 percent of the square canvas with consistent transparent padding. Output a single 1024 by 1024 PNG icon with genuinely transparent background outside the rounded square, crisp antialiased edges, straight front-facing view. No letters, no words, no logos, no watermarks, no extra scenery, no app-window mockup, no multiple icons, no existing franchise crest or copy of another app icon. This is the actual icon asset to embed in a Mac app, not a presentation of an icon.

The generated source resolution is 1254 by 1254; the requested size in the prompt was advisory. macOS icon sizes are produced from the preserved source. The icon references the crow motif without using extracted character or franchise artwork.
