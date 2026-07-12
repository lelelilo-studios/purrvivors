# Purrvivors

*cozy. chaotic. covered in fur.*

A cross-platform top-down survivor-like where you play a cute cat swarmed by
growing hordes of critters - mice, dogs, roombas, rival cats and worse. Your
attacks fire automatically; you steer, dodge, and gobble the snacks that
defeated enemies drop to level up. Survive the 15-minute gauntlet, bonk the
three milestone bosses, and spend your Fish Coins at the Cat Café on permanent
upgrades and new cats.

**Play it in your browser:** https://lelelilo-studios.github.io/purrvivors/

## How a run works

- **Move** with WASD / arrow keys (desktop) or the floating joystick (touch).
  Attacks are automatic - position is everything.
- Enemies drop **snacks** where they fall. Eat them for XP; level-ups offer
  3 upgrade cards (new weapons, weapon levels, passives).
- A **boss** arrives every 5 minutes. Beat at least one and the run counts as
  a win: 1 boss = Bronze Paw, 2 = Silver, all 3 = the Golden Paw full clear.
- Whatever happens, you keep every Fish Coin for the **Cat Café** shop -
  permanent upgrades that carry into every future run. A fresh cat is NOT
  supposed to survive the full 15 minutes; grow across runs.

## Running from source

1. Install [Godot 4.7+](https://godotengine.org/download) (standard build).
2. Clone this repo and open `project.godot` in the editor, or run
   `godot --path .` from the repo root.

### Debug keys (debug builds)

`F1` god mode · `F2` +60s run time · `F3` bonk everything on screen ·
`F4` +200 coins · `F5` level up · `F6` spawn the next boss

### Exporting

Export presets for Web, Linux, Windows, Android and iOS are committed in
`export_presets.cfg` (install export templates via the editor first).

```sh
# Web build into docs/ (served by GitHub Pages; threads disabled on purpose -
# GitHub Pages cannot send the COOP/COEP headers threaded builds need)
godot --headless --export-release "Web" docs/index.html
```

Note: Android/iOS presets are configured but unsigned native builds are left
to you (they need platform SDKs / certificates).

### Asset pipeline

All pixel art is generated with [PixelLab](https://pixellab.ai) and curated by
hand (see `assets/pixellab_manifest.json` for asset IDs + generation spend).
Useful tools:

- `tools/import_character.py` - unpack a PixelLab character zip into the
  sprite folder convention
- `godot --headless -s res://tools/generate_sprite_frames.gd` - rebuild
  SpriteFrames resources after adding sprites
- `tools/convert_tilesets.py` - convert PixelLab Wang tilesets
- `python3 tools/generate_audio.py` - regenerate the procedural SFX + music

All balance numbers live in `autoload/balance.gd` - one file to retune the
whole game (see the balance table comment at the bottom of it).

## Credits

See [CREDITS.md](CREDITS.md). Font: m5x7 by Daniel Linssen. Audio:
procedurally generated, CC0. Art: PixelLab + human curation.
