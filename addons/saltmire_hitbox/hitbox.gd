@tool
class_name Hitbox2D
extends Area2D
## Saltmire Hitbox Lite — the thing that DEALS damage (free, MIT).
##
## Drop a Hitbox2D (with a CollisionShape2D child) onto an attack: a sword swing,
## a bullet, a stomp zone. Set `damage`, `team` and (optionally) `knockback` in
## the inspector. When it overlaps a Hurtbox2D of a DIFFERENT team it lands a hit
## automatically — no layer/mask setup.
##
##   $Hitbox2D.activate()   # start a swing (also hits targets already overlapping)
##   $Hitbox2D.deactivate() # end the swing
##   $Hitbox2D.reset()      # re-arm so previously-hit targets can be hit again
##
## PRO adds damage types, crits, resistances, animation-frame binding and a
## runtime debug overlay → https://saltmire.itch.io

## Fires whenever this hitbox successfully damages a hurtbox.
signal hit(hurtbox: Hurtbox2D, damage: float)

## Damage dealt per landed hit.
@export var damage: float = 1.0
## Faction id. Only hurtboxes with a DIFFERENT team are hit.
@export var team: int = 0
## Impulse magnitude pushed away from the hitbox centre (0 = none).
@export var knockback: float = 0.0
## If true, each hurtbox is hit at most once until reset() is called.
@export var one_shot: bool = true
## Enable the hitbox. Turn off to hold a swing between active frames.
@export var active: bool = true
## Shared physics bit the pack uses (1–32). Must match the Hurtbox2D's bit.
@export_range(1, 32) var detection_bit: int = 20

var _already_hit: Array = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(detection_bit, true)
	monitoring = true
	monitorable = false
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


## Turn the hitbox on and immediately resolve hurtboxes it is ALREADY overlapping
## (area_entered only fires on new overlaps, so a melee swing that toggles on top
## of a target would otherwise never land). Call this at the start of each swing.
func activate() -> void:
	active = true
	reset()
	for area in get_overlapping_areas():
		_try_hit(area)


## Turn the hitbox off between swings.
func deactivate() -> void:
	active = false


func _try_hit(area: Area2D) -> void:
	if not active:
		return
	var hurtbox := area as Hurtbox2D
	if hurtbox == null or hurtbox.team == team:
		return
	if one_shot and _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	var dir := Vector2.ZERO
	if knockback > 0.0:
		dir = (hurtbox.global_position - global_position)
		dir = (dir.normalized() if dir.length() > 0.0 else Vector2.RIGHT) * knockback
	if hurtbox.receive(damage, self, dir):
		hit.emit(hurtbox, damage)


## Re-arm the hitbox so previously-hit hurtboxes can be hit again (next swing).
func reset() -> void:
	_already_hit.clear()
