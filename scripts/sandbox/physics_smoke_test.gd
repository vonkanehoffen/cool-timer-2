extends SceneTree

## Headless acceptance checks: fall, pile, 100-tap stability.


func _initialize() -> void:
	_run_tests()


func _run_tests() -> void:
	var sandbox: Node2D = load("res://scenes/sandbox/falling_gems_sandbox.tscn").instantiate()
	root.add_child(sandbox)
	for _i in 8:
		await process_frame

	var world: Node2D = sandbox.get_node("GemsPhysicsWorld")
	world.call("ensure_layout_ready")
	var rect: Rect2 = world.call("get_playfield_rect")
	var floor_zone_y: float = rect.position.y + rect.size.y * 0.88

	world.call("throw_at_viewport", Vector2(rect.size.x * 0.5, 80.0))
	for _i in 5:
		await process_frame
	var cube := _first_active(world)
	if cube == null:
		push_error("physics_smoke_test FAIL: no cube after first throw")
		quit(1)
		return

	var start_y: float = cube.position.y
	for _i in 260:
		await process_frame
	if cube.position.y < start_y + 200.0:
		push_error(
			"physics_smoke_test FAIL: cube did not fall (start=%s end=%s)"
			% [start_y, cube.position.y]
		)
		quit(1)
		return
	if cube.position.y < floor_zone_y:
		push_error(
			"physics_smoke_test FAIL: cube did not reach floor zone (y=%s need>=%s)"
			% [cube.position.y, floor_zone_y]
		)
		quit(1)
		return

	for i in 20:
		world.call("throw_at_viewport", Vector2(80.0 + float(i) * 28.0, 80.0))
		for _j in 4:
			await process_frame
	for _i in 120:
		await process_frame
	var active_count: int = world.call("get_active_cube_count")
	if active_count < 10:
		push_error(
			"physics_smoke_test FAIL: expected pile of cubes, active=%d"
			% active_count
		)
		quit(1)
		return

	for i in 100:
		world.call("throw_at_viewport", Vector2(60.0 + float(i % 36) * 16.0, 70.0))
	for _i in 200:
		await process_frame

	print("physics_smoke_test PASS active=%d floor_y=%s" % [world.call("get_active_cube_count"), cube.position.y])
	quit()


func _first_active(world: Node2D) -> RigidBody2D:
	for cube in world.get("_pool"):
		if cube.has_method("is_pooled_active") and cube.is_pooled_active():
			return cube
	return null
