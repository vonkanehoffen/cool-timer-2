extends Control

@onready var gems_bin: GemsBin = %GemsBin


func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	var tap_pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			tapped = true
			tap_pos = touch.position
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			tapped = true
			tap_pos = click.position
	if tapped:
		gems_bin.spawn_at_viewport_position(tap_pos)
