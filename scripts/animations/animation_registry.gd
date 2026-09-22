class_name AnimationRegistry
extends RefCounted

const DEFAULT_ANIMATION_ID := "plain-progress"

static var _entries: Array[Dictionary] = [
	{
		"id": "plain-progress",
		"name": "Plain Progress",
		"description": "Simple fill bar — reference animation for reduced motion and debugging.",
		"scene_path": "res://scenes/animations/plain_progress.tscn",
		"reduced_motion_safe": true,
	},
	{
		"id": "snake-trail",
		"name": "Neon Snake",
		"description": "A glowing snake winds through the grid until it fills the stage.",
		"scene_path": "res://scenes/animations/snake_trail.tscn",
		"reduced_motion_safe": false,
	},
	{
		"id": "falling-gems",
		"name": "Falling Gems",
		"description": "Colorful gems drop and stack until the bin is full.",
		"scene_path": "res://scenes/animations/falling_gems.tscn",
		"reduced_motion_safe": false,
	},
]


static func get_entries() -> Array[Dictionary]:
	return _entries


static func find_animation(id: String) -> Dictionary:
	for entry in _entries:
		if entry.id == id:
			return entry
	return {}


static func get_animation(id: String) -> Dictionary:
	var entry := find_animation(id)
	if entry.is_empty():
		push_error("Unknown animation id: %s" % id)
		return find_animation(DEFAULT_ANIMATION_ID)
	return entry


static func get_reduced_motion_animation_id() -> String:
	for entry in _entries:
		if entry.get("reduced_motion_safe", false):
			return entry.id
	return DEFAULT_ANIMATION_ID
