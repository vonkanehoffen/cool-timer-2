extends RigidBody2D

@onready var outline: Polygon2D = $Outline
@onready var polygon: Polygon2D = $Polygon2D
@onready var highlight: Polygon2D = $Highlight
@onready var sparkle: Polygon2D = $Sparkle


func set_gem_color(color: Color) -> void:
	polygon.color = color
	outline.color = color.darkened(0.45)
	highlight.color = color.lightened(0.4)
	sparkle.color = color.lightened(0.55)


func randomize_appearance(rng: RandomNumberGenerator) -> void:
	var hue := rng.randf()
	var saturation := rng.randf_range(0.55, 0.78)
	var value := rng.randf_range(0.82, 0.98)
	set_gem_color(Color.from_hsv(hue, saturation, value))
	scale = Vector2.ONE * rng.randf_range(0.88, 1.12)
