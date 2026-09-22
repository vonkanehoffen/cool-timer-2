extends RigidBody2D

const PHYSICS_LAYER := 1

@onready var cube: Polygon2D = $Cube

var _is_active := false


func is_pooled_inactive() -> bool:
	return not _is_active


func is_pooled_active() -> bool:
	return _is_active


func set_gem_color(color: Color) -> void:
	cube.color = color


func randomize_appearance(rng: RandomNumberGenerator) -> void:
	set_gem_color(Color.from_hsv(rng.randf(), 0.65, 0.92))


func activate_at(spawn_pos: Vector2, impulse: Vector2, rng: RandomNumberGenerator) -> void:
	freeze = true
	sleeping = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	position = spawn_pos
	reset_physics_interpolation()
	collision_layer = PHYSICS_LAYER
	collision_mask = PHYSICS_LAYER
	randomize_appearance(rng)
	visible = true
	_is_active = true
	freeze = false
	sleeping = false
	apply_central_impulse(impulse)
	angular_velocity = rng.randf_range(-1.5, 1.5)


func deactivate() -> void:
	_is_active = false
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	visible = false
	position = Vector2(-10000.0, -10000.0)
	reset_physics_interpolation()
