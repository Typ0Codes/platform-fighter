extends Node2D
## A tiny self-contained fighter for the Saltmire Hitbox demo: a coloured body,
## a Hurtbox2D that can be hurt, and a Hitbox2D it swings when attacking. Shows
## an HP bar, a white hit-flash, and reacts to knockback. Purely for the demo —
## the shippable product is the two components in addons/saltmire_hitbox/.

const SIZE := Vector2(52, 68)

var team: int = 0
var color: Color = Color.WHITE
var max_hp: float = 100.0
var hp: float = 100.0

var velocity: Vector2 = Vector2.ZERO
var _flash: float = 0.0
var _swing: float = 0.0          # seconds left in current attack swing
var _body: Polygon2D
var hitbox: Hitbox2D
var hurtbox: Hurtbox2D


func setup(p_team: int, p_color: Color) -> void:
	team = p_team
	color = p_color
	hp = max_hp

	# body
	_body = Polygon2D.new()
	var h := SIZE * 0.5
	_body.polygon = PackedVector2Array([-h, Vector2(h.x, -h.y), h, Vector2(-h.x, h.y)])
	_body.color = color
	add_child(_body)

	# hurtbox (can be hit)
	hurtbox = Hurtbox2D.new()
	hurtbox.team = team
	hurtbox.invincible_time = 0.4
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new(); hr.size = SIZE
	hs.shape = hr
	hurtbox.add_child(hs)
	add_child(hurtbox)
	hurtbox.hurt.connect(_on_hurt)

	# hitbox (deals damage) — sits in front, only active mid-swing
	hitbox = Hitbox2D.new()
	hitbox.team = team
	hitbox.damage = 12.0
	hitbox.knockback = 340.0
	hitbox.active = false
	var cs := CollisionShape2D.new()
	var cr := RectangleShape2D.new(); cr.size = Vector2(48, 46)
	cs.shape = cr
	cs.position = Vector2(46, 0)
	hitbox.add_child(cs)
	add_child(hitbox)


func attack() -> void:
	if _swing > 0.0:
		return
	_swing = 0.16
	hitbox.activate()


func face(dir: float) -> void:
	# flip the hitbox to the side we're facing
	if hitbox.get_child_count() > 0:
		var cs := hitbox.get_child(0) as CollisionShape2D
		cs.position.x = 46.0 * signf(dir if dir != 0.0 else 1.0)


func _on_hurt(damage: float, _source: Node, knockback: Vector2) -> void:
	hp = maxf(0.0, hp - damage)
	velocity += knockback
	_flash = 0.14


func alive() -> bool:
	return hp > 0.0


func reset_full() -> void:
	hp = max_hp
	velocity = Vector2.ZERO


func _process(delta: float) -> void:
	# movement + knockback with damping, clamped to the arena
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	position.x = clampf(position.x, 90, 1190)
	position.y = clampf(position.y, 150, 620)

	if _swing > 0.0:
		_swing -= delta
		if _swing <= 0.0:
			hitbox.active = false
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)

	_body.color = Color.WHITE if _flash > 0.0 else color
	queue_redraw()


func _draw() -> void:
	# HP bar above the head
	var w := 64.0
	var top := Vector2(-w * 0.5, -SIZE.y * 0.5 - 20)
	draw_rect(Rect2(top, Vector2(w, 8)), Color(0, 0, 0, 0.5))
	var pct := hp / max_hp
	var col := Color(0.4, 0.9, 0.4) if team == 0 else Color(0.95, 0.5, 0.4)
	draw_rect(Rect2(top, Vector2(w * pct, 8)), col)
	# a faint marker when invincible (i-frames)
	if hurtbox.is_invincible():
		draw_arc(Vector2.ZERO, SIZE.x * 0.75, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0)
