class_name GemsPhysicsWorld
extends Node2D

## Node2D physics playfield — cubes, walls, and pooling. Never parent bodies under Control.

const GEM_SCENE := preload("res://scenes/animations/gem.tscn")
const PHYSICS_LAYER := 1
const DEFAULT_MAX_GEMS := 36
const DEFAULT_POOL_SIZE := 36
const WALL_THICKNESS := 12.0
const FLOOR_THICKNESS := 16.0

@onready var gems_container: Node2D = $GemsContainer
@onready var floor_body: StaticBody2D = $Floor
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall

@export var max_gems: int = DEFAULT_MAX_GEMS
@export var edge_margin: float = 24.0
@export var use_full_viewport: bool = true
@export var use_object_pool: bool = false
@export var pool_size: int = DEFAULT_POOL_SIZE

var _rng := RandomNumberGenerator.new()
var _pool: Array[RigidBody2D] = []
var _playfield_size := Vector2.ZERO


func _ready() -> void:
	_rng.randomize()
	_configure_static_body(floor_body)
	_configure_static_body(left_wall)
	_configure_static_body(right_wall)
	_ensure_collision_shapes()
	if use_object_pool:
		_build_pool()
	call_deferred("ensure_layout_ready")


func _configure_static_body(body: StaticBody2D) -> void:
	body.collision_layer = PHYSICS_LAYER
	body.collision_mask = PHYSICS_LAYER


func _build_pool() -> void:
	var count := maxi(pool_size, max_gems)
	for _i in count:
		var gem: RigidBody2D = GEM_SCENE.instantiate()
		gems_container.add_child(gem)
		gem.call("deactivate")
		_pool.append(gem)


func ensure_layout_ready() -> void:
	_playfield_size = get_viewport_rect().size
	if _playfield_size.x <= 1.0 or _playfield_size.y <= 1.0:
		_playfield_size = Vector2(720.0, 1280.0)
	_update_walls()


func clear_gems() -> void:
	if use_object_pool:
		for cube in _pool:
			cube.call("deactivate")
	else:
		for child in gems_container.get_children():
			child.queue_free()


func get_playfield_rect() -> Rect2:
	if use_full_viewport:
		return Rect2(Vector2.ZERO, _playfield_size)
	var margin := Vector2(edge_margin, edge_margin)
	var rect := Rect2(margin, _playfield_size - margin * 2.0)
	rect.size.y = minf(rect.size.y, rect.size.x * 1.2)
	return rect


func throw_at_viewport(viewport_pos: Vector2) -> RigidBody2D:
	ensure_layout_ready()
	return _throw_at_x(viewport_pos.x)


func throw_cube_at_local(_local_pos: Vector2) -> RigidBody2D:
	ensure_layout_ready()
	return _throw_at_x(_local_pos.x)


func spawn_at_viewport_position(viewport_pos: Vector2) -> void:
	throw_at_viewport(viewport_pos)


func spawn_at_canvas_x(canvas_x: float) -> void:
	_throw_at_x(canvas_x)


func spawn_random_in_bin() -> void:
	ensure_layout_ready()
	var rect := get_playfield_rect()
	var spawn_x := _rng.randf_range(rect.position.x + 18.0, rect.position.x + rect.size.x - 18.0)
	_throw_at_x(spawn_x)


func get_active_cube_count() -> int:
	var count := 0
	for cube in _pool:
		if cube.has_method("is_pooled_active") and cube.is_pooled_active():
			count += 1
	return count


func _throw_at_x(spawn_x: float) -> RigidBody2D:
	var rect := get_playfield_rect()
	spawn_x = clampf(spawn_x, rect.position.x + 16.0, rect.position.x + rect.size.x - 16.0)
	var spawn_y := rect.position.y + 36.0
	var spawn_pos := Vector2(spawn_x, spawn_y)
	var target := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.75)
	var to_target := target - spawn_pos
	if to_target.length_squared() < 1.0:
		to_target = Vector2(0.0, 1.0)
	var impulse := to_target.normalized() * _rng.randf_range(40.0, 90.0)
	impulse.y += _rng.randf_range(80.0, 140.0)
	return _launch_cube(spawn_pos, impulse)


func _launch_cube(spawn_pos: Vector2, impulse: Vector2) -> RigidBody2D:
	if use_object_pool:
		return _launch_pooled(spawn_pos, impulse)
	return _launch_instant(spawn_pos, impulse)


func _launch_pooled(spawn_pos: Vector2, impulse: Vector2) -> RigidBody2D:
	var cube := _acquire_pooled_cube()
	if cube == null:
		return null
	cube.call("activate_at", spawn_pos, impulse, _rng)
	return cube


func _acquire_pooled_cube() -> RigidBody2D:
	if _pool.is_empty():
		return null
	for cube in _pool:
		if cube.has_method("is_pooled_inactive") and cube.is_pooled_inactive():
			return cube
	var settled: Array[RigidBody2D] = []
	for cube in _pool:
		if not cube.has_method("is_pooled_active") or not cube.is_pooled_active():
			continue
		if cube.sleeping or cube.linear_velocity.length() < 10.0:
			settled.append(cube)
	if not settled.is_empty():
		settled.sort_custom(func(a: RigidBody2D, b: RigidBody2D) -> bool:
			return a.position.y > b.position.y
		)
		return settled[0]
	var fallback: RigidBody2D = _pool[0]
	for cube in _pool:
		if cube.position.y > fallback.position.y:
			fallback = cube
	return fallback


func _launch_instant(spawn_pos: Vector2, impulse: Vector2) -> RigidBody2D:
	while gems_container.get_child_count() >= max_gems:
		gems_container.get_child(0).queue_free()
	var gem: RigidBody2D = GEM_SCENE.instantiate()
	gems_container.add_child(gem)
	gem.call("activate_at", spawn_pos, impulse, _rng)
	return gem


func _ensure_collision_shapes() -> void:
	for wall in [left_wall, right_wall, floor_body]:
		if wall == null:
			continue
		var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
		if shape_node.shape == null:
			shape_node.shape = RectangleShape2D.new()


func _update_walls() -> void:
	if not is_node_ready():
		return
	var rect := get_playfield_rect()
	var floor_y := rect.position.y + rect.size.y - FLOOR_THICKNESS * 0.5
	floor_body.position = Vector2(rect.position.x + rect.size.x * 0.5, floor_y)
	var wall_height := rect.size.y
	left_wall.position = Vector2(rect.position.x + WALL_THICKNESS * 0.5, rect.position.y + wall_height * 0.5)
	right_wall.position = Vector2(rect.position.x + rect.size.x - WALL_THICKNESS * 0.5, rect.position.y + wall_height * 0.5)
	for wall in [left_wall, right_wall]:
		var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
		if shape_node.shape is RectangleShape2D:
			(shape_node.shape as RectangleShape2D).size = Vector2(WALL_THICKNESS, wall_height)
	var floor_shape: CollisionShape2D = floor_body.get_node("CollisionShape2D")
	if floor_shape.shape is RectangleShape2D:
		(floor_shape.shape as RectangleShape2D).size = Vector2(rect.size.x, FLOOR_THICKNESS)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		ensure_layout_ready()
