extends Node2D

@onready var physics_world: GemsPhysicsWorld = $GemsPhysicsWorld
@onready var bin_outline: ReferenceRect = %BinOutline


func _ready() -> void:
	physics_world.ensure_layout_ready()
	_sync_outline()


func _input(event: InputEvent) -> void:
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
	get_viewport().set_input_as_handled()
	physics_world.throw_at_viewport(tap_pos)


func _sync_outline() -> void:
	var rect := physics_world.get_playfield_rect()
	bin_outline.position = rect.position
	bin_outline.size = rect.size


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and is_node_ready():
		physics_world.ensure_layout_ready()
		_sync_outline()
