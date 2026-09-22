class_name TimerConstants
extends RefCounted

const MIN_DURATION_SEC := 1.0
const MAX_DURATION_SEC := 86400.0 # 24 hours
const DEFAULT_DURATION_SEC := 300.0 # 5 minutes

const STATUS_IDLE := "idle"
const STATUS_RUNNING := "running"
const STATUS_PAUSED := "paused"
const STATUS_COMPLETED := "completed"
