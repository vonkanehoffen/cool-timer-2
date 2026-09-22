extends AnimationBase

const MAX_GEMS := 120

@onready var physics_world: GemsPhysicsWorld = %GemsPhysicsWorld
@onready var complete_flash: ColorRect = %CompleteFlash

var _spawned_count := 0


func on_animation_mounted() -> void:
	_reset_gems()


func apply_animation_props(props: AnimationProps) -> void:
	if not is_node_ready():
		return
	var target_count := 0
	match props.status:
		TimerConstants.STATUS_IDLE:
			if _spawned_count > 0:
				_reset_gems()
			target_count = 0
		TimerConstants.STATUS_COMPLETED:
			target_count = MAX_GEMS
		_:
			target_count = int(round(props.progress * float(MAX_GEMS)))
	_reconcile_gems(target_count)
	complete_flash.visible = props.status == TimerConstants.STATUS_COMPLETED


func _reset_gems() -> void:
	physics_world.clear_gems()
	_spawned_count = 0


func _reconcile_gems(target_count: int) -> void:
	target_count = clampi(target_count, 0, MAX_GEMS)
	physics_world.max_gems = MAX_GEMS
	while _spawned_count < target_count:
		physics_world.spawn_random_in_bin()
		_spawned_count += 1
