class_name TimeDisplayFormatter
extends RefCounted

## Formats remaining seconds for display. Seconds round up so zero only appears at completion.

static func format_remaining(seconds: float) -> String:
	var total_seconds := int(ceil(maxf(seconds, 0.0)))
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var secs := total_seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]
