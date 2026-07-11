extends Node
## ObjectPool — pre-instances and recycles scenes so late-run hordes
## (hundreds of enemies, snacks, projectiles) never allocate mid-frame.
##
## Usage:
##   ObjectPool.prewarm(MOUSE_SCENE, 200)
##   var mouse := ObjectPool.acquire(MOUSE_SCENE)  # caller adds it to the tree
##   ObjectPool.release(mouse)                     # instead of queue_free()
##
## Pooled scenes may implement two optional hooks:
##   _pool_reset() — called on acquire; restore HP, visibility, timers, etc.
##   _pool_sleep() — called on release; stop particles, disconnect targets, etc.

const _META_KEY := "_pool_scene_path"

# scene resource path -> Array of idle (out-of-tree) instances
var _pools: Dictionary = {}


func prewarm(scene: PackedScene, count: int) -> void:
	var pool: Array = _pool_for(scene.resource_path)
	for i in count:
		pool.append(_fresh_instance(scene))


func acquire(scene: PackedScene) -> Node:
	var pool: Array = _pool_for(scene.resource_path)
	var node: Node = pool.pop_back() if not pool.is_empty() else _fresh_instance(scene)
	if node.has_method(&"_pool_reset"):
		node.call(&"_pool_reset")
	return node


func release(node: Node) -> void:
	if not node.has_meta(_META_KEY):
		push_warning("ObjectPool.release() got a node it never created; freeing it: %s" % node)
		node.queue_free()
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	if node.has_method(&"_pool_sleep"):
		node.call(&"_pool_sleep")
	_pool_for(node.get_meta(_META_KEY)).append(node)


func idle_count(scene: PackedScene) -> int:
	return _pool_for(scene.resource_path).size()


func _pool_for(path: String) -> Array:
	if not _pools.has(path):
		_pools[path] = []
	return _pools[path]


func _fresh_instance(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	node.set_meta(_META_KEY, scene.resource_path)
	return node


func _exit_tree() -> void:
	# Idle instances live outside the tree; free them explicitly on shutdown.
	for pool: Array in _pools.values():
		for node: Node in pool:
			node.free()
	_pools.clear()
