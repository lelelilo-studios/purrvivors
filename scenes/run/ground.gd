class_name Ground
extends TileMapLayer
## Infinite streaming arena floor. Seeded noise decides which vertices are
## "upper" terrain (rug / path / checker patches); each cell picks its Wang
## tile from the biome's lookup table. Cells far behind the cat are erased,
## so a 15-minute marathon never runs off the map or bloats memory.

const BIOMES := ["kitchen", "living_room", "backyard"]
const VIEW_CELLS_X := 60      # painted window half-size (16px tiles)
const VIEW_CELLS_Y := 40
const PATCH_SCALE := 9.0      # noise frequency for patches
const PATCH_THRESHOLD := 0.42
## Floors sit back a touch so the cast reads instantly against them.
const GROUND_TINT := Color(0.93, 0.9, 0.86)

var biome := "kitchen"
var _wang: Dictionary = {}    # bitmask int -> Vector2i atlas coords
var _noise := FastNoiseLite.new()
var _painted_center := Vector2i(1 << 30, 1 << 30)


func setup(biome_name: String, run_seed: int) -> void:
	biome = biome_name
	self_modulate = GROUND_TINT
	_noise.seed = run_seed
	_noise.frequency = 1.0 / PATCH_SCALE
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/tiles/%s.json" % biome))
	var tile_px := int(data.tile_size)
	_wang.clear()
	for mask: String in data.wang:
		_wang[int(mask)] = Vector2i(int(data.wang[mask][0]), int(data.wang[mask][1]))

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/tiles/%s.png" % biome)
	source.texture_region_size = Vector2i(tile_px, tile_px)
	for coords: Vector2i in _wang.values():
		if not source.has_tile(coords):
			source.create_tile(coords)
	var set_res := TileSet.new()
	set_res.tile_size = Vector2i(tile_px, tile_px)
	set_res.add_source(source, 0)
	tile_set = set_res
	_painted_center = Vector2i(1 << 30, 1 << 30)


func update_around(world_pos: Vector2) -> void:
	var center := local_to_map(to_local(world_pos))
	if (center - _painted_center).length() < 12:
		return
	var old := _painted_center
	_painted_center = center
	for cx in range(center.x - VIEW_CELLS_X, center.x + VIEW_CELLS_X):
		for cy in range(center.y - VIEW_CELLS_Y, center.y + VIEW_CELLS_Y):
			var cell := Vector2i(cx, cy)
			if get_cell_source_id(cell) == -1:
				set_cell(cell, 0, _tile_for(cell))
	# Drop cells far outside the new window.
	if old.x < (1 << 29):
		for cell: Vector2i in get_used_cells():
			if absi(cell.x - center.x) > VIEW_CELLS_X * 2 or absi(cell.y - center.y) > VIEW_CELLS_Y * 2:
				erase_cell(cell)


func _tile_for(cell: Vector2i) -> Vector2i:
	var mask := 0
	if _vertex_upper(cell.x, cell.y):         mask += 8   # NW
	if _vertex_upper(cell.x + 1, cell.y):     mask += 4   # NE
	if _vertex_upper(cell.x, cell.y + 1):     mask += 2   # SW
	if _vertex_upper(cell.x + 1, cell.y + 1): mask += 1   # SE
	return _wang.get(mask, _wang.get(0, Vector2i.ZERO))


func _vertex_upper(vx: int, vy: int) -> bool:
	return _noise.get_noise_2d(vx, vy) > PATCH_THRESHOLD
