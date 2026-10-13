@tool
extends EditorPlugin
## Saltmire Hitbox registers two global node types — Hitbox2D and Hurtbox2D —
## via their `class_name` declarations, so there is no autoload and nothing to
## configure. This plugin exists only so the pack shows up in Project Settings →
## Plugins and can be toggled on/off cleanly.

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
