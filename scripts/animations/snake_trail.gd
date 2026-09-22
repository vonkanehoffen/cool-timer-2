extends AnimationBase

const GRID_COLUMNS := 18
const GRID_ROWS := 24
const SNAKE_WIDTH := 14.0

@onready var grid_background: ColorRect = %GridBackground
@onready var body_line: Line2D = %BodyLine
@onready var head_glow: Polygon2D = %HeadGlow
@onready var complete_overlay: ColorRect = %CompleteOverlay

var _path: PackedVector2Array = PackedVector2Array()
var _cell_size: float = 16.0
var _grid_offset: Vector2 = Vector2.ZERO
var _last_progress: float = -1.0


func on_animation_mounted() -> void:
	_rebuild_path()


func apply_animation_props(props: AnimationProps) -> void:
	if not is_node_ready():
		return
	if absf(props.progress - _last_progress) < 0.0001 and props.status != TimerConstants.STATUS_IDLE:
		if props.status != TimerConstants.STATUS_COMPLETED:
			return
	_last_progress = props.progress
	_update_layout()
	var draw_progress := props.progress
	if props.status == TimerConstants.STATUS_IDLE:
		draw_progress = 0.0
	elif props.status == TimerConstants.STATUS_COMPLETED:
		draw_progress = 1.0
	var sampled := SnakePath.sample_path(_path, draw_progress, _cell_size, _grid_offset)
	body_line.points = sampled
	body_line.width = SNAKE_WIDTH
	if sampled.size() > 0:
		head_glow.position = sampled[sampled.size() - 1]
		head_glow.visible = props.status == TimerConstants.STATUS_RUNNING
	else:
		head_glow.visible = false
	complete_overlay.visible = props.status == TimerConstants.STATUS_COMPLETED
	complete_overlay.modulate.a = 0.25 if props.status == TimerConstants.STATUS_COMPLETED else 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_rebuild_path()


func _rebuild_path() -> void:
	_path = SnakePath.build_grid_path(GRID_COLUMNS, GRID_ROWS)
	_update_layout()


func _update_layout() -> void:
	if not is_node_ready() or grid_background == null:
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var usable := size - Vector2(24, 24)
	_cell_size = minf(usable.x / float(GRID_COLUMNS), usable.y / float(GRID_ROWS))
	var grid_size := Vector2(_cell_size * GRID_COLUMNS, _cell_size * GRID_ROWS)
	_grid_offset = (size - grid_size) * 0.5 + Vector2(0, 0)
	grid_background.size = grid_size
	grid_background.position = _grid_offset - Vector2(4, 4)
	grid_background.size += Vector2(8, 8)
