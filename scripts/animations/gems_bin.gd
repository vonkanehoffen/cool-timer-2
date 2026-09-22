class_name GemsBin
extends Control

## Cube bin with floor/walls. Supports object pooling for the web sandbox.

const GEM_SCENE := preload("res://scenes/animations/gem.tscn")
const DEFAULT_MAX_GEMS := 36
const DEFAULT_POOL_SIZE := 36

@onready var bin_outline: ReferenceRect = %BinOutline
@onready var gems_container: Node2D = %GemsContainer
@onready var floor_body: StaticBody2D = %Floor
@onready var left_wall: StaticBody2D = %LeftWall
@onready var right_wall: StaticBody2D = %RightWall

@export var max_gems: int = DEFAULT_MAX_GEMS
@export var edge_margin: float = 24.0
@export var show_outline: bool = true
@export var use_full_viewport: bool = false
@export var use_object_pool: bool = false
@export var pool_size: int = DEFAULT_POOL_SIZE

var _rng := RandomNumberGenerator.new()
var _pool: Array[RigidBody2D] = []
var _pool_cursor: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	if bin_outline != null:
		bin_outline.visible = show_outline
		bin_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if show_outline:
			bin_outline.border_color = Color(0.45, 0.55, 0.72, 0.85)
			bin_outline.border_width = 2.0
		else:
			bin_outline.border_width = 0.0
	_ensure_collision_shapes()
	if use_object_pool:
		_build_pool()
	ensure_layout_ready()


func _build_pool() -> void:
	var count := maxi(pool_size, max_gems)
	for _i in count:
		var gem: RigidBody2D = GEM_SCENE.instantiate()
		gems_container.add_child(gem)
		if gem.has_method("deactivate"):
			gem.call("deactivate")
		_pool.append(gem)
	_pool_cursor = 0


func ensure_layout_ready() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		var parent_control := get_parent_control()
		if parent_control != null and parent_control.size.x > 1.0:
			size = parent_control.size
		else:
			size = get_viewport_rect().size
	_update_bin_layout()


func clear_gems() -> void:
	if use_object_pool:
		for cube in _pool:
			if cube.has_method("deactivate"):
				cube.call("deactivate")
		_pool_cursor = 0
	else:
		for child in gems_container.get_children():
			child.queue_free()


func get_gem_count() -> int:
	if use_object_pool:
		return mini(_pool_cursor, _pool.size())
	return gems_container.get_child_count()


func get_playfield_size() -> Vector2:
	var area := size
	if area.x <= 1.0 or area.y <= 1.0:
		area = get_viewport_rect().size
	return area


func get_bin_rect() -> Rect2:
	var area := get_playfield_size()
	if use_full_viewport:
		return Rect2(Vector2.ZERO, area)
	var margin := Vector2(edge_margin, edge_margin)
	var rect := Rect2(margin, area - margin * 2.0)
	rect.size.y = minf(rect.size.y, rect.size.x * 1.2)
	return rect


func throw_cube_at_local(local_pos: Vector2) -> void:
	ensure_layout_ready()
	var rect := get_bin_rect()
	var spawn_x := clampf(local_pos.x, rect.position.x + 14.0, rect.position.x + rect.size.x - 14.0)
	var spawn_y := rect.position.y + 20.0
	var target := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.65)
	_launch_cube(Vector2(spawn_x, spawn_y), target)


func spawn_at_viewport_position(viewport_pos: Vector2) -> void:
	ensure_layout_ready()
	throw_cube_at_local(make_canvas_position_local(viewport_pos))


func spawn_at_canvas_x(canvas_x: float) -> void:
	ensure_layout_ready()
	var rect := get_bin_rect()
	throw_cube_at_local(Vector2(canvas_x, rect.position.y + 20.0))


func spawn_random_in_bin() -> void:
	ensure_layout_ready()
	var rect := get_bin_rect()
	var spawn_x := _rng.randf_range(rect.position.x + 18.0, rect.position.x + rect.size.x - 18.0)
	var target := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.65)
	_launch_cube(Vector2(spawn_x, rect.position.y + 20.0), target)


func _launch_cube(spawn_pos: Vector2, target: Vector2) -> void:
	var to_target := target - spawn_pos
	if to_target.length_squared() < 1.0:
		to_target = Vector2(0.0, 1.0)
	var impulse := to_target.normalized() * _rng.randf_range(100.0, 170.0)
	impulse.y += _rng.randf_range(30.0, 80.0)
	if use_object_pool:
		_launch_pooled(spawn_pos, impulse)
	else:
		_launch_instant(spawn_pos, impulse)


func _launch_pooled(spawn_pos: Vector2, impulse: Vector2) -> void:
	if _pool.is_empty():
		return
	var cube := _pool[_pool_cursor % _pool.size()]
	_pool_cursor += 1
	if cube.has_method("activate_at"):
		cube.call("activate_at", spawn_pos, impulse, _rng)


func _launch_instant(spawn_pos: Vector2, impulse: Vector2) -> void:
	while gems_container.get_child_count() >= max_gems:
		gems_container.get_child(0).queue_free()
	var gem: RigidBody2D = GEM_SCENE.instantiate()
	gems_container.add_child(gem)
	if gem.has_method("activate_at"):
		gem.call("activate_at", spawn_pos, impulse, _rng)
	else:
		gem.position = spawn_pos
		gem.apply_central_impulse(impulse)


func _ensure_collision_shapes() -> void:
	if not is_node_ready():
		return
	for wall in [left_wall, right_wall, floor_body]:
		if wall == null:
			continue
		var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
		if shape_node.shape == null:
			shape_node.shape = RectangleShape2D.new()


func _update_bin_layout() -> void:
	if not is_node_ready() or bin_outline == null or floor_body == null:
		return
	var rect := get_bin_rect()
	bin_outline.position = rect.position
	bin_outline.size = rect.size
	var floor_y := rect.position.y + rect.size.y - 8.0
	floor_body.position = Vector2(rect.position.x + rect.size.x * 0.5, floor_y)
	var wall_height := rect.size.y
	left_wall.position = Vector2(rect.position.x + 6.0, rect.position.y + wall_height * 0.5)
	right_wall.position = Vector2(rect.position.x + rect.size.x - 6.0, rect.position.y + wall_height * 0.5)
	for wall in [left_wall, right_wall]:
		var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
		if shape_node.shape is RectangleShape2D:
			(shape_node.shape as RectangleShape2D).size = Vector2(12.0, wall_height)
	var floor_shape: CollisionShape2D = floor_body.get_node("CollisionShape2D")
	if floor_shape.shape is RectangleShape2D:
		(floor_shape.shape as RectangleShape2D).size = Vector2(rect.size.x, 16.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		ensure_layout_ready()
