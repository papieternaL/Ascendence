# Ascendence Sprite Prompt Pack

This prompt pack adapts the extracted Vibejam turnaround workflow to Ascendence's current 2D art direction and existing in-project anchor assets.

## Goals

- Keep characters readable when downscaled into gameplay and HUD use.
- Fill the frame more aggressively so sprites and icons do not feel like a small picture dropped into a large slot.
- Push silhouettes, color grouping, and contrast toward a cleaner action-roguelite read.
- Preserve identity between front, side, and diagonal directions.

## Anchor Assets

Use these project assets as the identity and style anchors before generating new sheets.

### Player loadouts

- `res://art/player/player_bow_equipped.png`
- `res://art/player/player_arcane_pistol_equipped.png`
- `res://art/player/player_arcane_sniper_equipped.png`

### Hub NPCs

- `res://art/hub/hub_merchant_npc.png`
- `res://art/hub/hub_quest_giver_npc.png`
- `res://art/hub/hub_trainee_npc.png`

### Environmental style references

- `res://art/hub/hub_quest_building.png`
- `res://art/hub/hub_tree_oak.png`
- `res://art/hub/hub_tree_pine.png`
- `res://art/hub/hub_cargo_cluster.png`

## Core Art Direction Rules

- Frame occupancy: the character or prop should use roughly 75% to 90% of the available square or frame height unless the design intentionally needs extra weapon or cape space.
- Downscale readability: simplify belts, buckles, trim, and tiny folds into larger shape groups.
- Pixel grouping: use broader color clusters and cleaner ramps instead of noisy painterly texture.
- Palette: keep warm mids, controlled highlights, and darker grounded shadows so the sprite fits the current hub/combat palette.
- Bottom anchor: feet or base contact should sit consistently near the same bottom line across every direction.
- Turntable consistency: head size, shoulder width, hand size, and boot height must stay stable from frame to frame.

## Recommended Workflow

1. Create a clean full-body master from the current in-game identity anchor.
2. Create a downscale-aware master that is chunkier and more game-readable.
3. Generate a 2x2 cardinal sheet.
4. Generate a 2x2 diagonal sheet using the cardinal sheet plus the downscale-aware master as anchors.
5. Normalize height and bottom alignment after generation.
6. Split into per-direction frames and import into Godot.

## Shared Prompt Rules

Append these rules to most character-generation prompts:

```text
Make the sprite read cleanly when downscaled for a 2D action roguelite. Fill the frame confidently so the character does not look tiny inside the canvas. Use chunky readable forms, broader shadow groups, simplified costume detail, crisp silhouette separation, and a restrained pixel-friendly color count. Keep the feet fully visible and preserve a stable bottom anchor for sheet consistency. No background scene, no text, no border, no extra props unless requested.
```

## Player Master Prompt

Use this to create a stronger full-body master from an existing loadout sprite.

```text
Use image 1 as the identity anchor. Create a full-body game-ready 2D fantasy action roguelite character sprite of the same hero. Preserve the face, hair silhouette, outfit identity, weapon type, and overall palette family, but rebuild the character with clearer shape language and better downscale readability. Make the silhouette bolder, the hands and boots slightly chunkier, and the weapon readable at gameplay size. Keep the full body visible from head to boots in a neutral standing pose, centered, with a transparent background. Make the character fill most of the canvas vertically without cropping. No environment, no text, no frame, no glow, and no painterly backdrop.
```

## Archer Loadout Variant

Use with `res://art/player/player_bow_equipped.png`.

```text
Preserve the Ascendence Archer identity. Keep the bow as a readable heroic ranged weapon with a clear bow arc and clean hand placement. Push the silhouette toward a fast agile hunter rather than a generic fantasy ranger. Keep the palette grounded and readable, with warm leather mids and stronger separation between cloak, limbs, and bow body.
```

## Arcane Pistol Loadout Variant

Use with `res://art/player/player_arcane_pistol_equipped.png` or `res://art/player/player_arcane_sniper_equipped.png`.

```text
Preserve the Ascendence Arcane Pistol identity. Keep the weapon clearly readable as a magical firearm, not a wand and not a sci-fi gun. Make the pistol silhouette compact and punchy with a bright magical focal accent, while the outfit stays grounded in fantasy materials. Push the overall read toward a nimble magical gunslinger with strong glove, coat, and boot separation.
```

## Downscale-Aware Master Prompt

Use this before building turnaround sheets.

```text
Image 1 is the identity anchor. Create a downscale-aware sprite master of this same character for a 2D roguelite. Optimize for readability at 64x96, 48x72, and small HUD portraits. Increase frame occupancy, simplify micro-detail, use fewer but stronger value groups, and make the pose compact and tile-friendly. Keep the full body visible, preserve the costume identity, and maintain a crisp clean silhouette. Background must be exact flat chroma green #00FF00 with no gradient, no floor, no cast shadow, and no texture.
```

## Cardinal Direction Sheet Prompt

```text
Image 1 is the identity, costume, style, and scale anchor. Create a single 2x2 spritesheet showing the same character in the four cardinal directions with maximum consistency. The sheet must contain exactly four full-body standing idle poses, one per quadrant. Reading order must be: top-left north/back, top-right east/right, bottom-left south/front, bottom-right west/left. Keep the same head size, shoulder width, hand size, boot height, palette family, and line weight in every panel. Fill each quadrant confidently so the sprite feels game-ready and not undersized. Background must be exact flat chroma green #00FF00 with no gradient, no floor, no text, and no borders.
```

## Diagonal Direction Sheet Prompt

```text
Image 1 is the curated cardinal direction sheet for consistency and direction logic. Image 2 is the downscale-aware master and diagonal angle anchor. Create a single 2x2 spritesheet showing the same character in the four diagonal directions with maximum consistency. Reading order must be: top-left northwest, top-right northeast, bottom-left southwest, bottom-right southeast. Preserve the same proportions, frame occupancy, palette family, shading style, and bottom anchor across all four panels. Make this feel like one stable game character rotated through directions, not four reinterpretations. Use exact flat chroma green #00FF00 with no text, no borders, no gradient, and no environment.
```

## Hub NPC Prompt

Use with merchant, quest giver, or trainee anchors.

```text
Use image 1 as the identity anchor. Create a game-ready full-body NPC sprite for Ascendence that preserves the same role, costume identity, and personality. Keep the silhouette readable at gameplay size and slightly exaggerate major shapes so the NPC remains legible beside environment props. Match the project's warm pixel-fantasy palette and grounded medieval materials. Keep the figure centered, feet visible, and framed large enough to feel present in the scene. Transparent background. No environment, no text, no frame.
```

## Square-Fill Icon Prompt

Use this for ability, item, and equipment icons so they occupy the icon slot better.

```text
Create a square game icon for a 2D action roguelite. The subject should fill most of the square with a strong central silhouette and minimal dead space. Use bold pixel-friendly shape design, simplified detail, high readability at small sizes, and controlled warm-to-cool contrast similar to action roguelite icons. Keep the composition centered and large, with a clean edge treatment and no tiny floating object in the middle of the frame. No text, no ornate border, no photorealism, and no muddy gradients.
```

## Normalization Checklist

After generation, normalize the sheet before import:

- Match visible sprite height across all directions.
- Match the bottom contact line across all directions.
- Recenter each frame without changing perceived scale.
- Remove extra empty padding that makes one direction feel smaller.
- Keep weapon tips inside the frame, but not at the cost of shrinking the whole body too much.

## Review Checklist

Approve a sheet only if:

- The sprite fills the frame confidently.
- The silhouette stays readable at gameplay size.
- Cardinal and diagonal poses feel like the same character.
- The palette fits the existing hub/combat art.
- The character does not "breathe" in scale from one direction to the next.
- The bottom anchor is stable and the sprite will drop cleanly into Godot animation frames.
