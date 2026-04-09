# Hub art (SpriteCook)

Sprites are wired on each interactable's `ArtSprite` (`Sprite2D`). Vector `_draw()` fallback is skipped when `uses_hub_art_sprite()` is true.

## Floor

| File | Source | Usage |
|------|--------|-------|
| `cobble_tile.png` | SpriteCook (`1f616581-a59d-4f74-8666-ede481706da2`), warm tone; 128x128 file (nearest upscale from pixel pass) | `HubRoot.cobble_floor_texture`; `cobble_tile_px` `0` = tile size from texture |

## Existing hub decor

| File | Source | Usage |
|------|--------|-------|
| `hub_wall_h.png` | SpriteCook (`c6b83272-92bc-411b-88bb-5ef3d198f8be`), scaled to 256x56 NE | Reused for top perimeter and training-yard wall accents in `EsseloriaHub.tscn` |
| `hub_wall_v.png` | SpriteCook (`baae06bf-99d9-468b-832f-fbfaf3530b6b`), scaled to 56x256 NE | Reused for side wall accents framing the weapon corner and canal edge |
| `hub_quest_building.png` | SpriteCook (`237ae44b-4d75-45c3-9c84-c1af13441556`) | `QuestArea/QuestBuilding` behind `QuestBoard` |
| `hub_merchant_stalls.png` | SpriteCook (`e08fc03c-4e34-4859-a1d2-4af94489132c`) | Legacy merchant backdrop; retained on disk but removed from the current hub scene |

## Interactables

| File | Source | Scene |
|------|--------|-------|
| `virtue_statue.png` | SpriteCook (`80ec7daf-792a-408a-9cf6-261172aad0bb`) | `VirtueStatue.tscn` |
| `portal.png` | SpriteCook (`bbc99c42-ba15-47f1-a673-0b8f5e48928a`) | `AscensionPortal.tscn` |
| `quest_board.png` | SpriteCook (`90f4ceb7-6aad-48b1-bdf4-5abdcbb20d26`) | `QuestBoard.tscn` |
| `weapon_pillar_bow.png` | SpriteCook (`46207270-fc46-4a40-ba3b-e4279fd630d0`), prompt + virtue statue ref `80ec7daf-792a-408a-9cf6-261172aad0bb`; shape from `reference_majestic_bow.png` | `WeaponStation` instance (Archer); `ArtSprite` scale `(0.5, 0.625)` on bow instance for 128x160 footprint |
| `weapon_pillar_pistol.png` | SpriteCook (`6b2d9188-6781-4a33-95f7-8fb1761b6a8b`) | `WeaponStation` instance (Arcane Pistol) |

### Runtime animation sheets

- `res://assets/animations/portalsheet.png`
  8-frame horizontal loop used by `AscensionPortal.tscn` via `scripts/hub/sprite_sheet_loop.gd`
- `res://assets/animations/virtuestatuesheet.png`
  8-frame horizontal loop used by `VirtueStatue.tscn` via `scripts/hub/sprite_sheet_loop.gd`

## Lived-in pass additions

| File | Source | Usage |
|------|--------|-------|
| `hub_entrance_sign_arch.png` | SpriteCook (`b840aa5a-99ba-4bcc-bb09-f8a10956c142`) | `NorthArrival/SignArch`; title text is a separate `Label` so the wordmark stays crisp |
| `hub_lantern_post.png` | SpriteCook (`71d0262c-6d46-4daa-aefe-eded612058d9`) | `NorthArrival/LanternPostLeft`, `NorthArrival/LanternPostRight` |
| `hub_cargo_cluster.png` | SpriteCook (`68e2f348-4d9c-4234-9444-c0be1560c2a2`) | Reused across north arrival, quest frontage, merchant side storage, and weapon corner |
| `hub_quest_giver_npc.png` | SpriteCook (`bf230b0b-896b-4186-9266-6ad4db73fe91`) | `NPCs/QuestGiver/Visual` |
| `hub_quest_notice_sign.png` | SpriteCook (`d78a40fc-9268-459f-98d3-f8c3a8832683`) | `QuestArea/QuestNoticeSign` |
| `hub_merchant_npc.png` | SpriteCook (`7baed2ff-61ec-4017-ba98-bcd5751ac306`) | `NPCs/MerchantKeeper/Visual` |
| `hub_merchant_stock_cluster.png` | SpriteCook (`b458941b-81c5-49e8-87aa-4d19ac6dbba5`) | `MerchantArea/MerchantStock` foreground layer |
| `hub_training_props.png` | SpriteCook (`535a3668-341c-4675-afc3-363653020735`) | `TrainingArea/TrainingProps`; replaces the placeholder polygons |
| `hub_trainee_npc.png` | SpriteCook (`f5a05281-7496-4c48-91ed-3b0ee68172ba`) | `NPCs/Trainee/Visual` |
| `hub_plaza_anchor_planter.png` | SpriteCook (`0d6eb90b-ade1-4f8a-88d1-3c67e4cbe525`) | Decorative marker for the four existing plaza blocker points |
| `hub_weapon_corner_props.png` | SpriteCook (`d425bf25-1adf-421c-b302-bc314c34882d`) | `WeaponCornerDecor/WeaponCache` near the class pillars |
| `hub_tree_oak.png` | SpriteCook (`60ec37ee-224f-4f2f-8a32-1ec89fd30fd2`) | `NatureEdge` oak blockers with subtle sway |
| `hub_tree_pine.png` | SpriteCook (`aaea9295-b01d-4dcd-8100-6f3bf0ff2203`) | `NatureEdge` pine blockers with subtle sway |
| `hub_bush_round.png` | SpriteCook (`db058a78-cf08-4111-af4b-693af74d56dd`) | Rounded hedge clusters for the visible perimeter |
| `hub_bush_wild.png` | SpriteCook (`32c148fa-de6d-46a0-be09-62a825c6d860`) | Wild hedge clusters for the visible perimeter |
| `hub_river_corner.png` | SpriteCook (`c67a37a4-a22a-4f3a-a39a-e6685a7c996c`) | `SouthEastCanal/RiverCorner`; decorative lower-right canal to echo the reference bridge-and-water corner |
| `hub_stone_bridge.png` | SpriteCook (`6fec9587-7ea0-4f60-a414-c17b9ea23f19`) | `SouthEastCanal/Bridge`; stone footbridge over the canal near the training yard |
| `hub_townfolk_adult_a.png` | SpriteCook (`05d1b781-6d4e-4a44-adef-5d907999dacb`) | `NPCs/TownWalkerA/Visual` |
| `hub_townfolk_adult_b.png` | SpriteCook (`c31e9336-e2a3-4d99-86e4-7f923a8afd71`) | `NPCs/TownWalkerB/Visual` |
| `hub_townfolk_child.png` | SpriteCook (`28bdd2d8-f7cc-4a2d-958d-acba10c38257`) | `NPCs/TownChild/Visual` |
| `hub_townfolk_adult_a_walk.png` | SpriteCook animation (`eced409a-ee5d-4098-b44b-d3576fd48197`) | 8-frame walk sheet for `NPCs/TownWalkerA/Visual` |
| `hub_townfolk_adult_b_walk.png` | SpriteCook animation (`8d46763d-1f87-467b-b450-943d1dfec309`) | Clean 8-frame right-walk sheet for `NPCs/TownWalkerB/Visual` |
| `hub_townfolk_child_walk.png` | SpriteCook animation (`216096ab-638c-4ed0-9e88-6ded78b3e4eb`) | Clean 8-frame right-walk sheet for `NPCs/TownChild/Visual` |
| `hub_townfolk_adult_a_back.png` | SpriteCook rear-view prep (`62e02050-8b2e-43ff-93e8-56818f759324`) | Northbound rear-view still for `NPCs/TownWalkerA` |
| `hub_townfolk_adult_a_walk_down.png` | SpriteCook animation (`c100271b-9e12-43be-a93e-7eda86514581`) | 8-frame southbound walk sheet for `NPCs/TownWalkerA` |
| `hub_townfolk_adult_b_back.png` | SpriteCook rear-view prep (`f5742733-b82d-4833-a6b2-8fbf0710d84c`) | Northbound rear-view still for `NPCs/TownWalkerB` |
| `hub_townfolk_adult_b_walk_down.png` | SpriteCook animation (`2eefe8cc-8c39-4821-b3d9-32454a1233f0`) | 8-frame southbound walk sheet for `NPCs/TownWalkerB` |
| `hub_townfolk_child_back.png` | SpriteCook rear-view prep (`222729a9-2f38-4fb3-826b-d3ea294758cf`) | Northbound rear-view still for `NPCs/TownChild` |
| `hub_townfolk_child_walk_down.png` | SpriteCook animation (`d1321408-4e1d-4187-974e-f56325c67f97`) | 8-frame southbound walk sheet for `NPCs/TownChild` |

## Merchant and quest UI

| File | Source | Usage |
|------|--------|-------|
| `hub_hp_potion.png` | SpriteCook (`085cb19f-331f-43c7-a74d-217815af9d7d`) | Merchant shop icon for the purchasable `HP Potion` in `hub_controller.gd` |
| `hub_quest_scroll.png` | SpriteCook (`b9913f9d-5fcc-46ad-a8d0-31c0dd5334cb`) | Scroll-style quest panel background for the quest-giver overlay in `hub_controller.gd` |

## Notes

- SpriteCook generation used `pixel: true`, `bg_mode: "transparent"`, and existing hub assets as style references.
- Ambient visual-only NPC motion is handled by `scripts/hub/ambient_sprite_motion.gd`.
- Decorative walker loops are handled by `scripts/hub/ambient_loop_walker.gd`, which advances the walk-sheet frames while moving, mirrors right-facing sheets for leftward movement in-scene, swaps to rear-view stills for northbound movement, and plays the new southbound SpriteCook walk sheets when villagers move toward the camera.
- The old `weapon_pedestal.png` remains unused.
