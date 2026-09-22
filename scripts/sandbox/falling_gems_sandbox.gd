extends Control

@onready var gems_bin: GemsBin = %GemsBin
@onready var hint_label: Label = %HintLabel

var _has_spawned := false


func _ready() -> void:
	hint_label.text = "Tap to drop a gem"


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
	if not tapped:
		return
	gems_bin.spawn_at_viewport_position(tap_pos)
	_hide_hint()


func _hide_hint() -> void:
	if _has_spawned:
		return
	_has_spawned = true
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.35)
