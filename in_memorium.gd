extends Node2D

func _ready() -> void:
	$DEAD.texture = MatchResult.loser_texture
	var year = Time.get_datetime_dict_from_system().year
	$Label.text = "%s (2026-%d)" % [MatchResult.loser_name, year]

	GDSync.expose_func(_go_to_stage)
	$GridContainer/PlayAgainButton.pressed.connect(_on_play_again_pressed)
	$GridContainer/PlayAgainButton.visible = GDSync.is_host()  # optional: host only

func _on_play_again_pressed() -> void:
	GDSync.call_func(_go_to_stage)  # everyone else
	_go_to_stage()                  # this client

func _go_to_stage() -> void:
	MatchResult.loser_name = ""
	MatchResult.loser_texture = null
	MatchResult.rejoin = true
	get_tree().change_scene_to_file("res://LobbyJoinPage.tscn")
