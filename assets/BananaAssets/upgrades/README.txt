Upgrade card images (PNG) — optional / future use

Level-up UI in the game currently uses procedural IconGlyph placeholders only
(see scripts/ui/hud.gd). These PNGs are not loaded by the HUD.

If you reintroduce per-card art later, you could wire TextureRect loading again
from filenames matching upgrade "id" in scripts/systems/upgrade_catalog.gd

Examples:
  arch_c_sharpened_tips.png
  arch_c_quick_nock.png
  arch_r_split_shot.png
  arch_e_arrow_storm.png
