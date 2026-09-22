extends Control

@onready var stage_host: AnimationHost = %AnimationHost
@onready var time_label: Label = %TimeLabel
@onready var status_label: Label = %StatusLabel
@onready var hours_spin: SpinBox = %HoursSpin
@onready var minutes_spin: SpinBox = %MinutesSpin
@onready var seconds_spin: SpinBox = %SecondsSpin
@onready var duration_feedback: Label = %DurationFeedback
@onready var start_button: Button = %StartButton
@onready var reset_button: Button = %ResetButton
@onready var animation_option: OptionButton = %AnimationOption
@onready var layout_root: BoxContainer = %LayoutRoot
@onready var controls_panel: VBoxContainer = %ControlsPanel
@onready var stage_panel: PanelContainer = %StagePanel
@onready var chime_player: AudioStreamPlayer = %ChimePlayer

var _timer := TimerEngine.new()
var _completion_shown := false


func _ready() -> void:
	_populate_animation_options()
	_set_default_duration()
	_wire_timer()
	_refresh_ui()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _process(_delta: float) -> void:
	_timer.update(_delta)
	_push_animation_props()


func _wire_timer() -> void:
	_timer.tick.connect(_on_timer_tick)
	_timer.status_changed.connect(_on_timer_status_changed)
	_timer.completed.connect(_on_timer_completed)


func _populate_animation_options() -> void:
	animation_option.clear()
	for entry in AnimationRegistry.get_entries():
		animation_option.add_item(entry.name)
		animation_option.set_item_metadata(animation_option.item_count - 1, entry.id)
	animation_option.select(_index_for_animation(AnimationRegistry.DEFAULT_ANIMATION_ID))


func _index_for_animation(animation_id: String) -> int:
	for i in animation_option.item_count:
		if animation_option.get_item_metadata(i) == animation_id:
			return i
	return 0


func _set_default_duration() -> void:
	var total := int(TimerConstants.DEFAULT_DURATION_SEC)
	hours_spin.value = total / 3600
	minutes_spin.value = (total % 3600) / 60
	seconds_spin.value = total % 60
	_apply_duration_from_inputs()


func _apply_duration_from_inputs() -> bool:
	var ok := _timer.set_duration_from_parts(int(hours_spin.value), int(minutes_spin.value), int(seconds_spin.value))
	if not ok:
		duration_feedback.text = "Duration must be between 1 second and 24 hours."
	else:
		duration_feedback.text = ""
	_refresh_time_label()
	return ok


func _refresh_ui() -> void:
	var editable := _timer.is_duration_editable()
	hours_spin.editable = editable
	minutes_spin.editable = editable
	seconds_spin.editable = editable
	hours_spin.modulate.a = 1.0 if editable else 0.55
	minutes_spin.modulate.a = 1.0 if editable else 0.55
	seconds_spin.modulate.a = 1.0 if editable else 0.55
	reset_button.disabled = _timer.status == TimerConstants.STATUS_IDLE
	match _timer.status:
		TimerConstants.STATUS_IDLE:
			start_button.text = "Start"
			status_label.text = "Ready"
			status_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
		TimerConstants.STATUS_RUNNING:
			start_button.text = "Pause"
			status_label.text = "Running"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.82))
		TimerConstants.STATUS_PAUSED:
			start_button.text = "Resume"
			status_label.text = "Paused"
			status_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
		TimerConstants.STATUS_COMPLETED:
			start_button.text = "Start again"
			status_label.text = "Time's up!"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.65))
	_refresh_time_label()
	_push_animation_props()


func _refresh_time_label() -> void:
	time_label.text = TimeDisplayFormatter.format_remaining(_timer.time_remaining_sec)
	if _timer.status == TimerConstants.STATUS_COMPLETED:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35))
	else:
		time_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))


func _push_animation_props() -> void:
	stage_host.apply_props(AnimationProps.from_timer(_timer))


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport_rect().size
	var wide := viewport_size.x > 820.0 and viewport_size.x > viewport_size.y * 0.9
	layout_root.vertical = not wide
	if wide:
		stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_panel.size_flags_stretch_ratio = 1.4
		controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls_panel.size_flags_stretch_ratio = 1.0
	else:
		stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_panel.size_flags_stretch_ratio = 1.0
		controls_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls_panel.size_flags_stretch_ratio = 0.0


func _on_timer_tick(_remaining: float, _progress: float) -> void:
	_refresh_time_label()


func _on_timer_status_changed(_status: String) -> void:
	_refresh_ui()


func _on_timer_completed() -> void:
	if not _completion_shown:
		chime_player.play_chime()
		_completion_shown = true
	_refresh_ui()


func _on_hours_spin_value_changed(_value: float) -> void:
	if _timer.is_duration_editable():
		_apply_duration_from_inputs()


func _on_minutes_spin_value_changed(_value: float) -> void:
	if _timer.is_duration_editable():
		_apply_duration_from_inputs()


func _on_seconds_spin_value_changed(_value: float) -> void:
	if _timer.is_duration_editable():
		_apply_duration_from_inputs()


func _on_start_button_pressed() -> void:
	match _timer.status:
		TimerConstants.STATUS_IDLE, TimerConstants.STATUS_COMPLETED:
			_completion_shown = false
			if _apply_duration_from_inputs():
				_timer.start()
		TimerConstants.STATUS_RUNNING:
			_timer.pause()
		TimerConstants.STATUS_PAUSED:
			_timer.resume()
	_refresh_ui()


func _on_reset_button_pressed() -> void:
	_completion_shown = false
	_timer.reset()
	_refresh_ui()


func _on_animation_option_item_selected(index: int) -> void:
	var animation_id: String = animation_option.get_item_metadata(index)
	stage_host.set_animation(animation_id)
