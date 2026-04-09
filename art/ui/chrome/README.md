# UI chrome art (SpriteCook)

These decorative HUD and upgrade-frame textures are loaded by `FrontendStyle` from `res://art/ui/chrome/<chrome_asset_id>.png` and overlaid by `HUD.gd` on top of the existing runtime UI. The gameplay logic still uses the live Godot controls underneath; these textures are presentation-only chrome.

## Notes

- Generated through SpriteCook with `mode: "ui"`, `pixel: true`, `bg_mode: "transparent"`, and `smart_crop: false`.
- The shared style direction was ornate roguelite fantasy metal with jewel accents so the HUD and level-up cards sit closer to the reference image.
- `hud_ability_orb_frame.png` was used as the first style anchor for the rest of the chrome batch.

## Assets

| File | Source |
|------|--------|
| `hud_ability_orb_frame.png` | SpriteCook (`f4c464d4-26d0-4033-a71b-752f225898d0`) |
| `hud_level_ring_frame.png` | SpriteCook (`6945f040-78ea-48c0-969a-29102fa8f3d8`) |
| `hud_health_frame.png` | SpriteCook (`e3369f24-af59-46cf-9cc9-a5b5c333a895`) |
| `hud_xp_frame.png` | SpriteCook (`ca9705e7-7cc8-42fc-a1d8-799ae360e220`) |
| `upgrade_card_frame.png` | SpriteCook (`adb7acb6-4b1b-42a3-846b-7b3c581bdb2d`) |
| `upgrade_header_frame.png` | SpriteCook (`6638f953-4555-4b28-a271-391e7921b8ca`) |
| `upgrade_icon_well_frame.png` | SpriteCook (`dfefff30-499b-4363-9a83-97b215d0017a`) |
