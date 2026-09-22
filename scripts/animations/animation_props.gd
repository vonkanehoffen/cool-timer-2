class_name AnimationProps
extends RefCounted

## Shared contract passed from the host to every animation.
## Mirrors Cool Timer's AnimationProps: total/remaining time, progress, status.

var total_time_sec: float = TimerConstants.DEFAULT_DURATION_SEC
var time_remaining_sec: float = TimerConstants.DEFAULT_DURATION_SEC
var progress: float = 0.0
var status: String = TimerConstants.STATUS_IDLE


static func from_timer(timer: TimerEngine) -> AnimationProps:
	var props := AnimationProps.new()
	props.total_time_sec = timer.total_time_sec
	props.time_remaining_sec = timer.time_remaining_sec
	props.progress = to_progress(timer.total_time_sec, timer.time_remaining_sec)
	props.status = timer.status
	return props


static func to_progress(total_sec: float, remaining_sec: float) -> float:
	if total_sec <= 0.0:
		return 1.0
	return clampf(1.0 - (remaining_sec / total_sec), 0.0, 1.0)
