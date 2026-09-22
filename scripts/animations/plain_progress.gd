extends AnimationBase

@onready var track: ColorRect = %Track
@onready var fill: ColorRect = %Fill
@onready var glow: ColorRect = %Glow
@onready var complete_label: Label = %CompleteLabel


func apply_animation_props(props: AnimationProps) -> void:
	_layout_track()
	var width := track.size.x
	fill.size.x = width * props.progress
	fill.position = track.position
	glow.position = track.position + Vector2(fill.size.x - glow.size.x * 0.5, track.size.y * 0.5 - glow.size.y * 0.5)
	glow.visible = props.status == TimerConstants.STATUS_RUNNING and props.progress < 1.0
	complete_label.visible = props.status == TimerConstants.STATUS_COMPLETED
	complete_label.position = track.position + Vector2(0, track.size.y + 12)
	match props.status:
		TimerConstants.STATUS_IDLE:
			fill.modulate = Color(0.35, 0.85, 0.78, 1.0)
		TimerConstants.STATUS_COMPLETED:
			fill.modulate = Color(0.98, 0.75, 0.25, 1.0)
		_:
			fill.modulate = Color(0.35, 0.85, 0.78, 1.0)


func _layout_track() -> void:
	if not is_node_ready() or track == null:
		return
	var bar_width := clampf(size.x - 48.0, 160.0, 440.0)
	var bar_height := 48.0
	track.custom_minimum_size = Vector2(bar_width, bar_height)
	track.size = Vector2(bar_width, bar_height)
	track.position = Vector2((size.x - bar_width) * 0.5, (size.y - bar_height) * 0.5)
	fill.size.y = bar_height


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_track()
