class_name AnimationBase
extends Control

## Duck-typed base for countdown animations.
## Subclasses override apply_animation_props(); the host calls it every frame.

func apply_animation_props(_props: AnimationProps) -> void:
	pass


func on_animation_mounted() -> void:
	pass
