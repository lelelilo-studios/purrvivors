#!/usr/bin/env python3
"""Import a PixelLab character download zip into the project's sprite layout.

Usage: tools/import_character.py <zip_path> <dest_dir> [zipanim=ourname ...]

Zip layout:   <Name>/rotations/<dir>.png
              <Name>/animations/<anim>/<dir>/frame_NNN.png
Our layout:   <dest>/<dir>.png
              <dest>/anim_<ourname>/<dir>_<N>.png

Animation names are normalized via DEFAULT_MAP plus any zipanim=ourname args.
"""
import sys, zipfile, pathlib, shutil

DEFAULT_MAP = {
    "walking": "walk", "walk": "walk", "fast-walk": "walk",
    "idle": "idle", "breathing-idle": "idle",
    "death": "death", "dying": "death", "hurt": "hurt",
    "attack": "attack", "bark": "attack",
}


def main() -> None:
    zip_path, dest = sys.argv[1], pathlib.Path(sys.argv[2])
    name_map = dict(DEFAULT_MAP)
    for arg in sys.argv[3:]:
        src, _, dst = arg.partition("=")
        name_map[src] = dst
    dest.mkdir(parents=True, exist_ok=True)
    copied = 0
    with zipfile.ZipFile(zip_path) as zf:
        for info in zf.infolist():
            parts = pathlib.PurePosixPath(info.filename).parts
            if len(parts) >= 3 and parts[1] == "rotations":
                out = dest / parts[2]
            elif len(parts) >= 5 and parts[1] == "animations":
                anim = name_map.get(parts[2], parts[2].split("-")[0])
                direction = parts[3]
                frame = int(parts[4].replace("frame_", "").replace(".png", ""))
                out = dest / f"anim_{anim}" / f"{direction}_{frame}.png"
            else:
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(info) as src_f, open(out, "wb") as dst_f:
                shutil.copyfileobj(src_f, dst_f)
            copied += 1
    print(f"imported {copied} files -> {dest}")


if __name__ == "__main__":
    main()
