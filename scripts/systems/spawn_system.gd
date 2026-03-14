extends Node

func spawn(scene: PackedScene, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	var instance := scene.instantiate()
	if instance is Node2D:
		(instance as Node2D).global_position = position
	parent.add_child(instance)
	return instance
