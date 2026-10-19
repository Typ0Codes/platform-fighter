extends Node2D

func _ready() -> void:
	var world = get_parent()
	world.child_entered_tree.connect(_on_world_child_added)

	# players that already exist (e.g. if you drop a player into the stage in the editor)
	for node in world.get_children():
		_check_node(node)


func _on_world_child_added(node: Node) -> void:
	_check_node(node)


func _check_node(node: Node) -> void:
	if not node.has_method("apply_hit"):   # only players have this
		return
	await get_tree().process_frame         # wait for the owner to be assigned
	_setup_player(node)


func _setup_player(p: Node) -> void:
	
	p.modulate = Color()

	
