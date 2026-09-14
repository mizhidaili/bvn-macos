# Application icon

Created with the built-in OpenAI image generation tool on 2026-09-14, without reference images. The selected icon depicts Itachi Uchiha in an expressive two-dimensional anime style: an off-center face, enlarged diagonal collar, loose ink silhouettes and restrained vermilion brushwork. It replaces the earlier raven motif at the user's request.

The final 1254-by-1254 PNG, including its transparent alpha channel, is preserved in `assets/app-icon.png`. `scripts/build_icon.py` uses Apple's `sips` to create 16, 32, 128, 256 and 512 point variants at 1x/2x, then packages them into `assets/AppIcon.icns` with `iconutil`. The build installs the icon and signs the app afterwards. The illustration is not programmatically repainted.

## Generation prompt

Use case: stylized-concept.
Asset: ONE exceptionally designed hand-drawn ANIME portrait icon of Itachi Uchiha for macOS. A new composition, not a conventional character screenshot or a realistic portrait.

Art direction: contemporary Japanese anime editorial illustration with bold graphic authorship. Recognizably 2D ANIME, but deliberately expressive and imperfect. Create visual invention IN THE CHARACTER'S SHAPES AND COMPOSITION, not just a layer of texture on a neat drawing. A tilted, off-center head; black hair reorganized into a few exaggerated sweeping, angular ink masses; a dramatically enlarged high cloak collar cuts diagonally across the lower composition. One large unpainted ivory wedge balances the black silhouette. Use confident irregular lines, changing line weights, abrupt missing edges, a few exposed construction-like strokes, lively dry-brush ends. Selectively leave some hair and clothing edges unfinished. A sparse vermilion brush gesture links the cloak lining to the negative space. Asymmetrical, dynamic, strongly designed yet restrained and readable at 64 pixels.

Character: unmistakably Itachi Uchiha from Naruto, long black hair with iconic face-framing locks, slashed Leaf forehead protector, narrow red Sharingan eyes, under-eye lines, calm intense expression, Akatsuki high collar. Preserve the essential anime identity, but freely reinterpret shape rhythm and framing. Face uses a SMALL NUMBER of expressive anime ink lines and flat ivory color; small simplified graphic nose, thin mouth line, NO rendered lips, NO human skin modeling. Eyes are the single concentrated detail; face and body are stylized and planar. Shape contrast matters more than anatomical detail.

Medium: loose ink brush drawing and flat gouache blocks, handmade editorial anime key art. Roughness must affect silhouettes and linework, not merely background grain. Broad flat charcoal, ivory and muted vermilion shapes; a tiny amount of cool gray. No airbrushed gradients, no realistic face shading, no 3D, no photorealism, no oil-painted real-person face. No highly polished uniform vector outlines, no generic tidy anime avatar, no symmetric centered bust, no elaborate background.

Icon delivery: square composition on a single pale ivory softly rounded-square tile, with a small transparent margin and REAL transparent alpha outside its rounded corners. No cast shadow. The actual icon only, no mockup. No raven, crow, bird, moon, extra characters, weapons, letters, typography, signature or watermark.

This is newly generated fan artwork of an existing fictional character, not an extracted game sprite or an original character design. The source illustration and alpha channel are preserved during macOS icon conversion.
