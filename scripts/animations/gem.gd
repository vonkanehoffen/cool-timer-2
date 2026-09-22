extends RigidBody2D

@onready var cube: Polygon2D = $Cube


func set_gem_color(color: Color) -> void:
	cube.color = color


func randomize_appearance(rng: RandomNumberGenerator) -> void:
	set_gem_color(Color.from_hsv(rng.randf(), 0.65, 0.92))
