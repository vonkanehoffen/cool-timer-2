class_name AnimationHost
extends Control

signal animation_changed(animation_id: String)

@export var default_animation_id: String = AnimationRegistry.DEFAULT_ANIMATION_ID

var current_animation_id: String = ""
var _active_animation: Node = null
var _last_props: AnimationProps = null


func _ready() -> void:
	set_animation(default_animation_id)


func set_animation(animation_id: String) -> void:
	if animation_id == current_animation_id and _active_animation != null:
		return
	var entry := AnimationRegistry.get_animation(animation_id)
	if entry.is_empty():
		return
	_clear_active()
	current_animation_id = entry.id
	var scene: PackedScene = load(entry.scene_path)
	if scene == null:
		push_error("Failed to load animation scene: %s" % entry.scene_path)
		return
	_active_animation = scene.instantiate()
	add_child(_active_animation)
	animation_changed.emit(current_animation_id)
	_when_animation_ready(_run_mount_and_sync)


func apply_props(props: AnimationProps) -> void:
	_last_props = props
	_when_animation_ready(_sync_props)


func _when_animation_ready(callback: Callable) -> void:
	if _active_animation == null or not is_instance_valid(_active_animation):
		return
	if _active_animation.is_node_ready():
		callback.call()
	else:
		_active_animation.ready.connect(callback, CONNECT_ONE_SHOT)


func _run_mount_and_sync() -> void:
	if _active_animation == null or not is_instance_valid(_active_animation):
		return
	if _active_animation is AnimationBase:
		(_active_animation as AnimationBase).on_animation_mounted()
	_sync_props()


func _sync_props() -> void:
	if _active_animation == null or _last_props == null:
		return
	if _active_animation.has_method("apply_animation_props"):
		_active_animation.call("apply_animation_props", _last_props)


func _clear_active() -> void:
	if _active_animation != null and is_instance_valid(_active_animation):
		_active_animation.queue_free()
	_active_animation = null
