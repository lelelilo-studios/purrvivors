extends SceneTree
## Headless tool - builds a SpriteFrames resource (frames.tres) for every
## character folder, so nothing scans directories at runtime (exports remap
## res:// files and runtime scanning breaks on web).
##
## Run after adding sprites:  godot --headless -s res://tools/generate_sprite_frames.gd
##
## Folder convention:
##   <dir>/<direction>.png                    static rotation (idle/walk fallback)
##   <dir>/anim_<name>/<direction>_<i>.png    frame i of animation <name>
## Output animations are named "<name>_<direction>".

const ROOTS := [
	"res://assets/sprites/cats",
	"res://assets/sprites/enemies",
	"res://assets/sprites/bosses",
]
const DIRECTIONS := [
	"south", "south-east", "east", "north-east",
	"north", "north-west", "west", "south-west",
]
const ANIM_FPS := {"walk": 10.0, "idle": 5.0, "death": 12.0, "attack": 12.0, "hurt": 12.0}
const NON_LOOPING := ["death", "attack", "hurt"]


func _init() -> void:
	var built := 0
	for root: String in ROOTS:
		var da := DirAccess.open(root)
		if da == null:
			continue
		for sub in da.get_directories():
			if _build("%s/%s" % [root, sub]):
				built += 1
	print("generate_sprite_frames: built %d frames.tres" % built)
	quit()


func _build(dir: String) -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var rotations := {}
	for d: String in DIRECTIONS:
		var p := "%s/%s.png" % [dir, d]
		if ResourceLoader.exists(p):
			rotations[d] = load(p)

	var da := DirAccess.open(dir)
	var anim_names: Array[String] = []
	for sub in da.get_directories():
		if sub.begins_with("anim_"):
			anim_names.append(sub.substr(5))

	for anim: String in anim_names:
		for d: String in DIRECTIONS:
			var textures: Array[Texture2D] = []
			var i := 0
			while true:
				var p := "%s/anim_%s/%s_%d.png" % [dir, anim, d, i]
				if not ResourceLoader.exists(p):
					break
				textures.append(load(p))
				i += 1
			if textures.is_empty():
				continue
			var name := StringName("%s_%s" % [anim, d])
			frames.add_animation(name)
			frames.set_animation_speed(name, ANIM_FPS.get(anim, 8.0))
			frames.set_animation_loop(name, anim not in NON_LOOPING)
			for t in textures:
				frames.add_frame(name, t)

	# Every character must at least answer to idle_* and walk_* - fall back
	# to the static rotation frame when no real animation exists yet.
	for want in ["idle", "walk"]:
		for d: String in DIRECTIONS:
			var name := StringName("%s_%s" % [want, d])
			if frames.has_animation(name) or not rotations.has(d):
				continue
			frames.add_animation(name)
			frames.set_animation_speed(name, 5.0)
			frames.add_frame(name, rotations[d])

	if frames.get_animation_names().is_empty():
		return false
	var err := ResourceSaver.save(frames, "%s/frames.tres" % dir)
	if err != OK:
		push_error("could not save frames for %s (err %d)" % [dir, err])
		return false
	return true
