@tool
class_name Hurtbox2D
extends Area2D
## Saltmire Hitbox Lite — the thing that CAN BE HURT (free, MIT).
##
## Drop a Hurtbox2D (with a CollisionShape2D child) onto anything that can take
## damage. Give it a `team`, then listen for one signal:
##
##   func _ready() -> void:
##       $Hurtbox2D.hurt.connect(_on_hurt)
##   func _on_hurt(damage: float, source: Node, knockback: Vector2) -> void:
##       hp -= damage
##       velocity += knockback
##
## You never touch collision layers or masks — the component wires them so a
## Hitbox2D of a DIFFERENT team detects this hurtbox and nothing else. Optional
## invincibility frames stop the same hit landing twice.
##
## PRO adds damage types, crits, resistances, animation-frame binding and a
## runtime debug overlay → https://saltmire.itch.io

## Fires when a Hitbox2D of another team overlaps this hurtbox and lands a hit.
signal hurt(damage: float, source: Node, knockback: Vector2)
## Fires when invincibility ends (handy for flashing the sprite, etc.).
signal invincibility_ended

## Faction id. Hitboxes only hurt hurtboxes with a DIFFERENT team.
@export var team: int = 0
## Seconds of invincibility after a hit (0 = can be hit every frame).
@export var invincible_time: float = 0.0
## Shared physics bit the whole pack uses to see each other (1–32). Change only
## if it clashes with your project's layers — Hitbox2D must use the same bit.
@export_range(1, 32) var detection_bit: int = 20

var _invincible: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(detection_bit, true)
	monitorable = true
	monitoring = false


## Called by Hitbox2D. Returns true if the hit landed (false if invincible).
func receive(damage: float, source: Node, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _invincible:
		return false
	hurt.emit(damage, source, knockback)
	if invincible_time > 0.0:
		_invincible = true
		var t := get_tree().create_timer(invincible_time)
		t.timeout.connect(_end_invincibility)
	return true


func is_invincible() -> bool:
	return _invincible


func _end_invincibility() -> void:
	_invincible = false
	invincibility_ended.emit()
