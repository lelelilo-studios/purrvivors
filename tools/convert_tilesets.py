#!/usr/bin/env python3
"""Convert PixelLab Wang tileset downloads into the game's ground format.

Usage: tools/convert_tilesets.py <dir-with-*_metadata.json+*_image.png> <out_dir>

Produces per biome:  <out>/<name>.png   (the sprite sheet, unchanged)
                     <name>.json  {"tile_size": N, "wang": {"<bitmask>": [ax, ay]}}
Bitmask = NW*8 + NE*4 + SW*2 + SE*1 where 1 = upper terrain.
ground.gd samples run-seeded noise at cell corners and looks tiles up here -
no Godot terrain-connect pass needed, which keeps infinite streaming cheap.
"""
import json, pathlib, shutil, sys


def convert(meta_path: pathlib.Path, out_dir: pathlib.Path) -> None:
    name = meta_path.name.replace("_metadata.json", "")
    meta = json.loads(meta_path.read_text())
    tile_size = meta["tileset_data"]["tile_size"]["width"]
    wang = {}
    for tile in meta["tileset_data"]["tiles"]:
        c = tile["corners"]
        mask = (
            (8 if c["NW"] == "upper" else 0) + (4 if c["NE"] == "upper" else 0)
            + (2 if c["SW"] == "upper" else 0) + (1 if c["SE"] == "upper" else 0)
        )
        bb = tile["bounding_box"]
        wang[str(mask)] = [bb["x"] // tile_size, bb["y"] // tile_size]
    out_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy(meta_path.with_name(f"{name}_image.png"), out_dir / f"{name}.png")
    (out_dir / f"{name}.json").write_text(
        json.dumps({"tile_size": tile_size, "wang": wang}, indent=1))
    print(f"{name}: {len(wang)} wang tiles, {tile_size}px")


if __name__ == "__main__":
    src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    for meta in sorted(src.glob("*_metadata.json")):
        convert(meta, out)
