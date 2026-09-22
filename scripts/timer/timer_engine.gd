class_name TimerEngine
extends RefCounted

signal tick(time_remaining_sec: float, progress: float)
signal status_changed(status: String)
signal completed

var total_time_sec: float = TimerConstants.DEFAULT_DURATION_SEC:
	set(value):
		total_time_sec = clampf(value, TimerConstants.MIN_DURATION_SEC, TimerConstants.MAX_DURATION_SEC)

var time_remaining_sec: float = TimerConstants.DEFAULT_DURATION_SEC
var progress: float = 0.0
var status: String = TimerConstants.STATUS_IDLE

var _deadline_msec: int = 0
var _paused_remaining_msec: float = 0.0


func set_duration_from_parts(hours: int, minutes: int, seconds: int) -> bool:
	var requested := float(hours * 3600 + minutes * 60 + seconds)
	if requested < TimerConstants.MIN_DURATION_SEC or requested > TimerConstants.MAX_DURATION_SEC:
		return false
	total_time_sec = requested
	if _is_editable():
		time_remaining_sec = total_time_sec
		progress = 0.0
	return true


func set_duration_seconds(seconds: float) -> bool:
	if seconds < TimerConstants.MIN_DURATION_SEC or seconds > TimerConstants.MAX_DURATION_SEC:
		return false
	total_time_sec = seconds
	if _is_editable():
		time_remaining_sec = total_time_sec
		progress = 0.0
	return true


func start() -> void:
	if status == TimerConstants.STATUS_RUNNING:
		return
	if status == TimerConstants.STATUS_COMPLETED:
		reset()
	if status == TimerConstants.STATUS_PAUSED:
		resume()
		return
	time_remaining_sec = total_time_sec
	progress = 0.0
	_deadline_msec = Time.get_ticks_msec() + int(total_time_sec * 1000.0)
	_set_status(TimerConstants.STATUS_RUNNING)


func pause() -> void:
	if status != TimerConstants.STATUS_RUNNING:
		return
	_sync_from_deadline()
	_paused_remaining_msec = time_remaining_sec * 1000.0
	_set_status(TimerConstants.STATUS_PAUSED)


func resume() -> void:
	if status != TimerConstants.STATUS_PAUSED:
		return
	_deadline_msec = Time.get_ticks_msec() + int(_paused_remaining_msec)
	_set_status(TimerConstants.STATUS_RUNNING)


func reset() -> void:
	time_remaining_sec = total_time_sec
	progress = 0.0
	_paused_remaining_msec = 0.0
	_set_status(TimerConstants.STATUS_IDLE)


func update(_delta: float) -> void:
	if status != TimerConstants.STATUS_RUNNING:
		return
	_sync_from_deadline()
	tick.emit(time_remaining_sec, progress)
	if time_remaining_sec <= 0.0:
		time_remaining_sec = 0.0
		progress = 1.0
		_set_status(TimerConstants.STATUS_COMPLETED)
		completed.emit()


func is_duration_editable() -> bool:
	return _is_editable()


func _is_editable() -> bool:
	return status == TimerConstants.STATUS_IDLE or status == TimerConstants.STATUS_COMPLETED


func _sync_from_deadline() -> void:
	var remaining_msec := float(_deadline_msec - Time.get_ticks_msec())
	time_remaining_sec = maxf(remaining_msec / 1000.0, 0.0)
	if total_time_sec <= 0.0:
		progress = 1.0
	else:
		progress = clampf(1.0 - (time_remaining_sec / total_time_sec), 0.0, 1.0)


func _set_status(next_status: String) -> void:
	if status == next_status:
		return
	status = next_status
	status_changed.emit(status)
