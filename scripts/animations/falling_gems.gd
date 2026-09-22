extends AnimationBase

const MAX_GEMS := 120
const GEM_SCENE := preload("res://scenes/animations/gem.tscn")

@onready var bin_outline: ReferenceRect = %BinOutline
@onready var gems_container: Node2D = %GemsContainer
@onready var floor_body: StaticBody2D = %Floor
@onready var left_wall: StaticBody2D = %LeftWall
@onready var right_wall: StaticBody2D = %RightWall
@onready var complete_flash: ColorRect = %CompleteFlash

var _spawned_count := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_collision_shapes()
	_update_bin_layout()


func on_animation_mounted() -> void:
	_reset_gems()


func _ensure_collision_shapes() -> void:
	if not is_node_ready():
		return
	for wall in [left_wall, right_wall, floor_body]:
		if wall == null:
			continue
		var shape_node: CollisionShape2D = wall.get_node("CollisionShape2D")
		if shape_node.shape == null:
			shape_node.shape = RectangleShape2D.new()


func apply_animation_props(props: AnimationProps) -> void:
	if not is_node_ready():
		return
	_update_bin_layout()
	var target_count := 0
	match props.status:
		TimerConstants.STATUS_IDLE:
			if _spawned_count > 0:
				_reset_gems()
			target_count = 0
		TimerConstants.STATUS_COMPLETED:
			target_count = MAX_GEMS
		_:
			target_count = int(round(props.progress * float(MAX_GEMS)))
	_reconcile_gems(target_count)
	complete_flash.visible = props.status == TimerConstants.STATUS_COMPLETED


func _reset_gems() -> void:
	for child in gems_container.get_children():
		child.queue_free()
	_spawned_count = 0


func _reconcile_gems(target_count: int) -> void:
	target_count = clampi(target_count, 0, MAX_GEMS)
	while _spawned_count < target_count:
		_spawn_gem()
		_spawned_count += 1


func _spawn_gem() -> void:
	var gem: RigidBody2D = GEM_SCENE.instantiate()
	gems_container.add_child(gem)
	var bin_rect := _get_bin_rect()
	var spawn_x := _rng.randf_range(bin_rect.position.x + 18.0, bin_rect.position.x + bin_rect.size.x - 18.0)
	gem.position = Vector2(spawn_x, bin_rect.position.y - 20.0 - _rng.randf_range(0.0, 80.0))
	gem.apply_central_impulse(Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(20.0, 120.0)))
	gem.angular_velocity = _rng.randf_range(-4.0, 4.0)
	var hue := _rng.randf()
	gem.set_gem_color(Color.from_hsv(hue, 0.65, 0.95))


func _update_bin_layout() -> void:
	if not is_node_ready() or bin_outline == null or floor_body == null:
		return
	var rect := _get_bin_rect()
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


func _get_bin_rect() -> Rect2:
	var margin := Vector2(24, 24)
	var rect := Rect2(margin, size - margin * 2.0)
	rect.size.y = minf(rect.size.y, rect.size.x * 1.2)
	return rect


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_bin_layout()
