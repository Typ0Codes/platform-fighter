extends Node2D
## Saltmire Hitbox Lite — playable demo.
## Blue (you): Arrow keys move, Space to attack.
## Red (AI): chases and swings on its own. Watch damage, knockback, i-frame ring.
## Nobody configures a collision layer anywhere — the components handle it.

const FighterScript := preload("res://demo/fighter.gd")

var player: Node2D
var enemy: Node2D
var _enemy_cd: float = 0.0
var _reset_in: float = 0.0


func _ready() -> void:
	player = _make_fighter(0, Color(0.35, 0.62, 1.0), Vector2(430, 380))
	enemy = _make_fighter(1, Color(1.0, 0.42, 0.42), Vector2(850, 380))


func _make_fighter(team: int, color: Color, pos: Vector2) -> Node2D:
	var f := Node2D.new()
	f.set_script(FighterScript)
	add_child(f)
	f.position = pos
	f.setup(team, color)
	return f


func _process(delta: float) -> void:
	if _reset_in > 0.0:
		_reset_in -= delta
		if _reset_in <= 0.0:
			player.position = Vector2(430, 380); player.reset_full()
			enemy.position = Vector2(850, 380); enemy.reset_full()
		return

	var mv := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	if mv.length() > 0:
		player.position += mv.normalized() * 260.0 * delta
		player.face(mv.x)
	if Input.is_action_just_pressed("ui_accept"):
		player.attack()

	_enemy_cd = maxf(0.0, _enemy_cd - delta)
	var to_player: Vector2 = player.position - enemy.position
	enemy.face(to_player.x)
	if to_player.length() > 78.0:
		enemy.position += to_player.normalized() * 190.0 * delta
	elif _enemy_cd <= 0.0:
		enemy.attack()
		_enemy_cd = 1.1

	if not player.alive() or not enemy.alive():
		_reset_in = 1.4
