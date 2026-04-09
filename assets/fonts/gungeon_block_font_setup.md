# Gungeon Block Bitmap Font Setup

## Source Asset
- Canonical source atlas: `res://assets/BananaAssets/Gemini_Generated_Image_oz31w6oz31w6oz31.png`
- Source image size: `2816x1536`

This atlas is used for **short UI text only**:
- floating damage numbers
- `LEVEL UP`
- short upgrade titles / short labels

Do not slice this into separate PNG files.
Do not use it as a sprite animation sheet.

## Godot Import Workflow
In the Godot editor:

1. Select `res://assets/BananaAssets/Gemini_Generated_Image_oz31w6oz31w6oz31.png`
2. In the Import dock, change **Import As** to:
   - `Font Data (Monospace Image Font)`
3. Reimport the asset

The runtime helper loads this PNG path directly. Once it is imported as an image font, `load()` will resolve it as a `Font` resource.

## Important Notes
- This atlas still contains section headers and decorations, so the importer setup must be tuned with **image_margin**, **columns**, **rows**, and **character_ranges**.
- Keep the workflow configuration-driven. Do not hand-author one glyph texture per character.
- If the import is not configured yet, the game falls back to the existing UI font so the project still runs.

## Settings To Tune First
If glyphs are misaligned, adjust in this order:

1. `image_margin`
2. `columns`
3. `rows`
4. `character_margin`
5. `ascent`
6. `descent`

Only after those are correct should you change label font sizes in code.

## Suggested Starting Import Values
These are **starting points**, not locked final values:

- `columns`: tune to the visible glyph grid width after trimming
- `rows`: tune to the visible glyph grid height after trimming
- `image_margin`: use this first to cut away the title text and corner decorations
- `character_margin`: use this to remove guide lines / excess padding inside each cell
- `ascent`: set high enough that capitals sit correctly on the baseline
- `descent`: keep small unless punctuation or lower glyphs clip

Because the atlas is not a pure tight glyph rectangle, you should expect one editor pass to finalize the margins and baseline.

## Intended Character Order
Configure the importer to traverse the glyph cells in this order:

1. Uppercase letters
   - `A-Z`
2. Lowercase letters
   - `a-z`
3. Numbers
   - `0-9`
4. Common punctuation / symbols
   - `., ; : ! ? + - x / = % # $ @ * & < > [ ] { } | ( ) ~ ^ ' " _`

If the final tuned grid still includes empty cells between sections, keep those cells as unused positions in the traversal instead of trying to create a separate image asset.

## Runtime Integration
The reusable helper is:
- `res://scripts/ui/bitmap_font_library.gd`

Current hooks:
- floating damage numbers in `res://scripts/effects/damage_number.gd`
- demo preview scene in `res://scenes/ui/BitmapFontDemo.tscn`

## Validation
After reimport:

1. Open `res://scenes/ui/BitmapFontDemo.tscn`
2. Verify:
   - `LEVEL UP`
   - `RICOCHET ARROW`
   - `128!`
3. Run gameplay and confirm floating damage numbers use the bitmap font.
