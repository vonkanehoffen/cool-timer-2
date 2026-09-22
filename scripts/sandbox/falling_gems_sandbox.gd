extends Node2D

@onready var physics_world: GemsPhysicsWorld = $GemsPhysicsWorld
@onready var input_catcher: Control = $OverlayLayer/InputCatcher

var _last_tap_frame := -1


func _ready() -> void:
	input_catcher.gui_input.connect(_on_gui_tap)
	call_deferred("_sync_layout")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"(function(){var c=document.getElementById('canvas');if(c){c.tabIndex=0;c.focus();}})();",
			true
		)


func _input(event: InputEvent) -> void:
	_process_tap_event(event)


func _on_gui_tap(event: InputEvent) -> void:
	if _process_tap_event(event):
		input_catcher.accept_event()


func _process_tap_event(event: InputEvent) -> bool:
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
		return false
	var frame := Engine.get_process_frames()
	if frame == _last_tap_frame:
		return true
	_last_tap_frame = frame
	physics_world.ensure_layout_ready()
	physics_world.throw_at_viewport(tap_pos)
	get_viewport().set_input_as_handled()
	return true


func _sync_layout() -> void:
	if not is_inside_tree():
		return
	physics_world.ensure_layout_ready()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_sync_layout")
