class_name GemsBin
extends Control

## Reusable gem bin with floor/walls physics. Used by the timer animation and sandbox.

const GEM_SCENE := preload("res://scenes/animations/gem.tscn")
const DEFAULT_MAX_GEMS := 100

@onready var bin_outline: ReferenceRect = %BinOutline
@onready var gems_container: Node2D = %GemsContainer
@onready var floor_body: StaticBody2D = %Floor
@onready var left_wall: StaticBody2D = %LeftWall
@onready var right_wall: StaticBody2D = %RightWall

@export var max_gems: int = DEFAULT_MAX_GEMS
@export var edge_margin: float = 24.0
@export var show_outline: bool = true
@export var use_full_viewport: bool = false

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	if bin_outline != null:
		bin_outline.visible = show_outline
		bin_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not show_outline:
			bin_outline.border_width = 0.0
	_ensure_collision_shapes()
	ensure_layout_ready()


func ensure_layout_ready() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		var parent_control := get_parent_control()
		if parent_control != null and parent_control.size.x > 1.0:
			size = parent_control.size
		else:
			size = get_viewport_rect().size
	_update_bin_layout()


func clear_gems() -> void:
	for child in gems_container.get_children():
		child.queue_free()


func get_gem_count() -> int:
	return gems_container.get_child_count()


func get_bin_rect() -> Rect2:
	var area := size
	if area.x <= 1.0 or area.y <= 1.0:
		area = get_viewport_rect().size
	if use_full_viewport:
		return Rect2(Vector2.ZERO, area)
	var margin := Vector2(edge_margin, edge_margin)
	var rect := Rect2(margin, size - margin * 2.0)
	rect.size.y = minf(rect.size.y, rect.size.x * 1.2)
	return rect


func spawn_at_viewport_position(viewport_pos: Vector2) -> void:
	ensure_layout_ready()
	var local_x := make_canvas_position_local(viewport_pos).x
	spawn_at_canvas_x(local_x)


func spawn_at_canvas_x(canvas_x: float) -> void:
	ensure_layout_ready()
	var rect := get_bin_rect()
	var spawn_x := clampf(canvas_x, rect.position.x + 18.0, rect.position.x + rect.size.x - 18.0)
	_spawn_gem(spawn_x, rect)


func spawn_random_in_bin() -> void:
	ensure_layout_ready()
	var rect := get_bin_rect()
	var spawn_x := _rng.randf_range(rect.position.x + 18.0, rect.position.x + rect.size.x - 18.0)
	_spawn_gem(spawn_x, rect)


func _spawn_gem(spawn_x: float, bin_rect: Rect2) -> void:
	_enforce_cap()
	var gem: RigidBody2D = GEM_SCENE.instantiate()
	gems_container.add_child(gem)
	var spawn_y := bin_rect.position.y - 20.0 - _rng.randf_range(0.0, 80.0)
	if use_full_viewport:
		spawn_y = minf(spawn_y, -16.0 - _rng.randf_range(0.0, 40.0))
	gem.position = Vector2(spawn_x, spawn_y)
	gem.apply_central_impulse(Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(20.0, 120.0)))
	gem.angular_velocity = _rng.randf_range(-4.0, 4.0)
	if gem.has_method("randomize_appearance"):
		gem.call("randomize_appearance", _rng)


func _enforce_cap() -> void:
	while gems_container.get_child_count() >= max_gems:
		var oldest := gems_container.get_child(0)
		oldest.queue_free()


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
		_update_bin_layout()
