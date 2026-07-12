class_name SpatialGrid
extends RefCounted
## Uniform hash grid for the horde: neighbor separation and weapon target
## queries without physics bodies. Rebuilt once per frame (O(n)); queries
## touch only nearby cells.

var cell_size := 48.0
var _cells: Dictionary = {}


func clear() -> void:
	_cells.clear()


func insert(item: Object, pos: Vector2) -> void:
	var key := _key(pos)
	if _cells.has(key):
		_cells[key].append(item)
	else:
		_cells[key] = [item]


## All items within `radius` of `pos` (coarse cell pass + exact distance check
## against item.position, so items must expose a `position` property).
func query_radius(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var r2 := radius * radius
	var min_cx := int(floorf((pos.x - radius) / cell_size))
	var max_cx := int(floorf((pos.x + radius) / cell_size))
	var min_cy := int(floorf((pos.y - radius) / cell_size))
	var max_cy := int(floorf((pos.y + radius) / cell_size))
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var cell: Array = _cells.get(Vector2i(cx, cy), [])
			for item in cell:
				if pos.distance_squared_to(item.position) <= r2:
					result.append(item)
	return result


## Nearest item to `pos` within `max_radius`, or null. Searches outward in
## cell rings so it rarely touches more than a few cells.
func nearest(pos: Vector2, max_radius: float) -> Object:
	var best: Object = null
	var best_d2 := max_radius * max_radius
	var center := Vector2i(int(floorf(pos.x / cell_size)), int(floorf(pos.y / cell_size)))
	var max_ring := int(ceilf(max_radius / cell_size)) + 1
	for ring in range(0, max_ring + 1):
		# Once we have a candidate closer than the inner edge of this ring,
		# no farther ring can beat it.
		if best != null:
			var inner_edge := (ring - 1) * cell_size
			if inner_edge > 0.0 and best_d2 <= inner_edge * inner_edge:
				break
		for cx in range(center.x - ring, center.x + ring + 1):
			for cy in range(center.y - ring, center.y + ring + 1):
				if maxi(absi(cx - center.x), absi(cy - center.y)) != ring:
					continue
				var cell: Array = _cells.get(Vector2i(cx, cy), [])
				for item in cell:
					var d2 := pos.distance_squared_to(item.position)
					if d2 < best_d2:
						best_d2 = d2
						best = item
	return best


## Allocation-free separation: accumulated normalized push away from up to
## `max_samples` neighbors within `radius`. Hot path for 300+ enemies.
func separation_push(item: Object, pos: Vector2, radius: float, max_samples := 5) -> Vector2:
	var push := Vector2.ZERO
	var r2 := radius * radius
	var sampled := 0
	var min_cx := int(floorf((pos.x - radius) / cell_size))
	var max_cx := int(floorf((pos.x + radius) / cell_size))
	var min_cy := int(floorf((pos.y - radius) / cell_size))
	var max_cy := int(floorf((pos.y + radius) / cell_size))
	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var cell: Array = _cells.get(Vector2i(cx, cy), [])
			for other in cell:
				if other == item:
					continue
				var away: Vector2 = pos - other.position
				var d2 := away.length_squared()
				if d2 < r2 and d2 > 0.0001:
					var d := sqrt(d2)
					push += (away / d) * (1.0 - d / radius)
					sampled += 1
					if sampled >= max_samples:
						return push
	return push


func _key(pos: Vector2) -> Vector2i:
	return Vector2i(int(floorf(pos.x / cell_size)), int(floorf(pos.y / cell_size)))
