extends Node2D
# Put this on the root node of your level scene. Every client runs the exact same
# script: connect -> join the lobby (or create it if it doesn't exist) -> spawn own player.

@export var player_scene: PackedScene   # drag your player .tscn in here
@export var lobby_name := "test_lobby"
@export var max_players := 4

var spawned := false


func _ready() -> void:
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)

	GDSync.start_multiplayer()


func _on_connected() -> void:
	# Try to join first; if nobody made the lobby yet, join fails and we create it.
	GDSync.lobby_join(lobby_name, "")


func _on_connection_failed(error: int) -> void:
	push_error("GD-Sync connection failed: %s" % error)


func _on_lobby_join_failed(_name: String, _error: int) -> void:
	GDSync.lobby_create(lobby_name, "", true, max_players, {})


func _on_lobby_created(_name: String) -> void:
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_creation_failed(_name: String, _error: int) -> void:
	# Two clients raced to create it and the other one won, so just join.
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_joined(_name: String) -> void:
	if spawned:
		return
	spawned = true
	_spawn_local_player()


func _spawn_local_player() -> void:
	var my_id := GDSync.get_client_id()

	# Spawns on every client in the lobby, and (replicate_on_join = true) on
	# anyone who joins later. `self` is the parent, so this node must exist at the
	# same path on every client.
	var player = GDSync.multiplayer_instantiate(
		player_scene, self, true, PackedStringArray(), true
	)

	# These are all set in the same frame as the spawn, so sync_starting_changes
	# copies them to the other clients automatically.
	GDSync.set_gdsync_owner(player, my_id)
	player.team = my_id
	player.global_position = Vector2(500 + randi() % 300, 100)
