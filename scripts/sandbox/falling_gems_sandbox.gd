extends Control

@onready var gems_bin: GemsBin = %GemsBin


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	call_deferred("_boot_demo")


func _boot_demo() -> void:
	gems_bin.ensure_layout_ready()
	gems_bin.spawn_random_in_bin()
	gems_bin.spawn_random_in_bin()


func _gui_input(event: InputEvent) -> void:
	var tap_pos := Vector2.INF
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			tap_pos = touch.position
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			tap_pos = click.position
	if tap_pos == Vector2.INF:
		return
	gems_bin.ensure_layout_ready()
	var local_pos := make_canvas_position_local(tap_pos)
	gems_bin.spawn_at_canvas_x(local_pos.x)
	accept_event()
