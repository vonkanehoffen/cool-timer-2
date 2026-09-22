class_name SnakePath
extends RefCounted

## Generates a serpentine route that visits every cell in a grid exactly once.

static func build_grid_path(columns: int, rows: int) -> PackedVector2Array:
	var points: PackedVector2Array = []
	if columns <= 0 or rows <= 0:
		return points
	for row in rows:
		if row % 2 == 0:
			for col in columns:
				points.append(Vector2(col, row))
		else:
			for col in range(columns - 1, -1, -1):
				points.append(Vector2(col, row))
	return points


static func sample_path(path: PackedVector2Array, progress: float, cell_size: float, offset: Vector2) -> PackedVector2Array:
	if path.is_empty():
		return PackedVector2Array()
	var clamped := clampf(progress, 0.0, 1.0)
	var target_length := clamped * float(path.size())
	var whole_segments := int(floor(target_length))
	var fraction := target_length - float(whole_segments)
	var result: PackedVector2Array = []
	for i in whole_segments:
		result.append(path[i] * cell_size + offset)
	if fraction > 0.0 and whole_segments < path.size() - 1:
		var start := path[whole_segments] * cell_size + offset
		var end := path[whole_segments + 1] * cell_size + offset
		result.append(start.lerp(end, fraction))
	elif whole_segments < path.size():
		result.append(path[whole_segments] * cell_size + offset)
	return result
