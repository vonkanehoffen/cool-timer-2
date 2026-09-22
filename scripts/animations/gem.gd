extends RigidBody2D

@onready var cube: Polygon2D = $Cube


func set_gem_color(color: Color) -> void:
	cube.color = color


func randomize_appearance(rng: RandomNumberGenerator) -> void:
	set_gem_color(Color.from_hsv(rng.randf(), 0.65, 0.92))


func activate_at(spawn_pos: Vector2, impulse: Vector2, rng: RandomNumberGenerator) -> void:
	visible = true
	freeze = false
	sleeping = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	position = spawn_pos
	randomize_appearance(rng)
	apply_central_impulse(impulse)
	angular_velocity = rng.randf_range(-1.5, 1.5)


func deactivate() -> void:
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = false
	position = Vector2(-10000.0, -10000.0)
