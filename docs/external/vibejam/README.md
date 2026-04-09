# Vibejam Starter Pack Extracts

Source repo:
- `https://github.com/chongdashu/vibejam-starter-pack`

Why these files were pulled in:
- Our project is a Godot 2D game, so the Phaser and Three.js starter code is not directly reusable.
- The best cross-engine carryovers are workflow references and visual-pipeline notes.
- The upstream repo explicitly notes that several starters rely on third-party asset packs, so those art assets were not copied into this project.

What was extracted:
- `tinyswords-tilemap-skill.md`
  - Useful for layered 2D map composition, elevation reads, shadow placement, water-edge breakup, and terrain color separation.
  - Most relevant for future combat-map polish, hub terrain transitions, and any biome pass where we want stronger depth from layered 2D art.
- `tictac-adventurer-8way-turntable-prompts.md`
  - Useful as a prompt/reference workflow for generating consistent 8-way or isometric character sheets.
  - Most relevant if we create new characters, NPCs, enemies, or item/portrait turnarounds through AI-assisted art workflows.

What was intentionally not copied:
- The bundled Phaser and Three.js project code.
- The Tiny Swords, Oak Woods, and Quaternius asset content.
- Any large generated media outputs from the bonus art repo.

Recommended use in Ascendence:
- Use `tinyswords-tilemap-skill.md` as a composition reference when we revisit arena floor layering, shoreline edges, elevation illusions, or decorative shadow logic.
- Use `tictac-adventurer-8way-turntable-prompts.md` as a prompt bank/template if we want to generate cleaner 8-way sprite sheets or normalize directional character art.
- The current repo implementation based on those references lives in:
  - `scripts/hub/hub_controller.gd` for layered hub path grounding and terrain transitions
  - `scripts/main/arena.gd` for stronger combat-floor clearing/trail separation
  - `docs/ascendence_sprite_prompt_pack.md` for an Ascendence-specific sprite and icon prompt workflow
- Keep upstream licensing in mind before reusing any third-party art from the original starter pack.
