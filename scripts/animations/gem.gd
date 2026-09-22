extends RigidBody2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var highlight: Polygon2D = $Highlight


func set_gem_color(color: Color) -> void:
	polygon.color = color
	highlight.color = color.lightened(0.35)
