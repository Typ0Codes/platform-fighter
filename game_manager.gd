extends Node2D

@export var characters: Array[PackedScene]      
@export var character_names: PackedStringArray  
@export var stages: Array[PackedScene]         
@export var stage_names: PackedStringArray     
@export var default_lobby_name := "test_lobby"

@onready var lobby_name_input = $LobbyName
@onready var player_count_input = $PlayerCount
@onready var play_button = $PlayButton
@onready var character_select = get_node_or_null("CharacterSelect")  
@onready var stage_select = get_node_or_null("StageSelect")           


var world: Node2D

var lobby_name := ""
var max_players := 4
var chosen_character := 0
var chosen_stage := 0
var tried_create := false
var spawned := false
var current_stage: Node = null


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)

	play_button.pressed.connect(_on_play_pressed)
	play_button.disabled = true
	play_button.text = "Connecting..."

	_fill_dropdown(character_select, characters, character_names, "Character")
	_fill_dropdown(stage_select, stages, stage_names, "Stage")

	if MatchResult.rejoin:
		MatchResult.rejoin = false
		_restart_match()
		return

	GDSync.start_multiplayer()




func _on_connected() -> void:
	play_button.disabled = false
	play_button.text = "Play"


func _on_connection_failed(_error = null) -> void:
	play_button.text = "Connection failed"   




func _on_play_pressed() -> void:
	lobby_name = lobby_name_input.text.strip_edges()
	if lobby_name.is_empty():
		lobby_name = default_lobby_name
	max_players = int(player_count_input.value)
	chosen_character = character_select.selected if character_select != null else 0
	chosen_stage = stage_select.selected if stage_select != null else 0

	tried_create = false
	play_button.disabled = true
	play_button.text = "Joining..."

	GDSync.lobby_join(lobby_name, "")



func _on_lobby_join_failed(_name = null, _error = null) -> void:
	if tried_create:
		_fail("Couldn't join (full?)")
		return
	tried_create = true
	GDSync.lobby_create(lobby_name, "", true, max_players, {"Stage": chosen_stage})


func _on_lobby_created(_name = null) -> void:
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_creation_failed(_name = null, _error = null) -> void:
	
	GDSync.lobby_join(lobby_name, "")


func _fail(message: String) -> void:
	push_warning(message)
	play_button.text = message
	await get_tree().create_timer(2.0).timeout
	play_button.text = "Play"
	play_button.disabled = false




func _on_lobby_joined(_name = null) -> void:
	if spawned:
		return
	spawned = true

	lobby_name_input.hide()
	player_count_input.hide()
	play_button.hide()
	if character_select != null:
		character_select.hide()
	if stage_select != null:
		stage_select.hide()

	var stage_index: int = await _get_lobby_stage()
	MatchResult.stage_index = stage_index
	MatchResult.character_index = chosen_character
	_load_stage(stage_index)
	_spawn_local_player()



func _restart_match() -> void:
	spawned = true
	lobby_name_input.hide()
	player_count_input.hide()
	play_button.hide()
	if character_select != null:
		character_select.hide()
	if stage_select != null:
		stage_select.hide()

	# Give slower clients a moment to finish loading this scene
	await get_tree().create_timer(0.5).timeout

	chosen_character = MatchResult.character_index
	chosen_stage = MatchResult.stage_index
	_load_stage(chosen_stage)
	_spawn_local_player()


func _get_lobby_stage() -> int:
	for i in 30:   
		var value = GDSync.lobby_get_tag("Stage", -1)
		if value != null and int(value) >= 0:
			return int(value)
		await get_tree().create_timer(0.1).timeout
	push_warning("game_manager: lobby has no 'Stage' tag, using your own selection.")
	return chosen_stage


func _load_stage(index: int) -> void:
	if index < 0 or index >= stages.size() or stages[index] == null:
		push_error("game_manager: stage %d isn't set in 'Stages'. Drag your stage scenes into it in the Inspector." % index)
		return

	var stage = stages[index].instantiate()
	stage.name = "Stage"
	current_stage = stage
	world.add_child(stage)
	world.move_child(stage, 0)   


func _spawn_local_player() -> void:
	var scene: PackedScene = null
	if chosen_character >= 0 and chosen_character < characters.size():
		scene = characters[chosen_character]
	if scene == null:
		push_error("game_manager: 'Characters' is empty (or that slot is). Drag your character scenes into it in the Inspector.")
		return

	var my_id := GDSync.get_client_id()

	var player = GDSync.multiplayer_instantiate(
		scene, world, true, PackedStringArray(), true
	)

	
	GDSync.set_gdsync_owner(player, my_id)
	player.team = my_id
	player.global_position = _get_spawn_position(my_id)



func _get_spawn_position(my_id: int) -> Vector2:
	var points: Array = []

	if current_stage != null:
		var holder = current_stage.get_node_or_null("SpawnPoints")
		if holder != null:
			for child in holder.get_children():
				if child is Node2D:
					points.append(child)

	if points.is_empty():
		points = get_tree().get_nodes_in_group("spawn_points")

	if points.size() > 0:
		return points[my_id % points.size()].global_position
	return Vector2(200 + randi() % 300, 100)




func _fill_dropdown(button, scenes: Array[PackedScene], names: PackedStringArray, fallback: String) -> void:
	if button == null:
		return

	button.clear()
	for i in scenes.size():
		var label := ""
		if i < names.size():
			label = names[i]
		elif scenes[i] != null:
			label = scenes[i].resource_path.get_file().get_basename()
		if label == "":
			label = "%s %d" % [fallback, i + 1]
		button.add_item(label)

	if scenes.size() > 0:
		button.select(0)
