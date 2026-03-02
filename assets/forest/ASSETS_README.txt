Forest Scene Asset Specifications
=================================

Add these image files to enable asset-based rendering (procedural fallback when missing):

1. grass_dirt.png (512x512)
   - Seamless tiling grass/dirt texture
   - Grass tufts transitioning to forest floor dirt
   - Wrap mode: repeat

2. forest_sheet.png
   - Gnarled trees: Pine 1, Pine 2 (snow-dusted), Oak 3, Oak 4 (moss), Dead 5
   - Bushes: 3 variants
   - Mossy stones: 2 variants
   - Root clumps
   - Suggested layout: 320x192 or larger; quads in forest_scene.lua define slices

3. fungi_sheet.png
   - Small glowing spores
   - Large blue-green mushroom cluster
   - Tiny drifting light specks
   - Bioluminescent blue-green palette

4. volcano_sheet.png (optional, for fire/volcano biome)
   - Craggy rocks, lava flow sprites, molten elements

5. menu_icons_sheet.png (optional, 32x32 HD)
   - Ability slots (bottom HUD): Bow/Arrow (Q), Shield/Guard (W), Radiating burst (SPACE), Multi-shot (E), Focus arrow (R)
   - Upgrade card icons: boot (Fleetfoot), flame (Fire), snowflake (Ice), bolt (Lightning), arrow (Ricochet), target (crit), magnet (XP), blood (Bleed), star (default)

Quad coordinates in scenes/forest_scene.lua should be adjusted to match your sheet layouts.
