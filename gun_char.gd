extends CharacterBody2D

@export var speed = 150
@export var jump_speed = -350
@export var acceleration = 15
@export var friction = 16

@export var character_name := "Gun"

@export var team = 1:
	set(value):
		team = value
		if is_node_ready():
			_apply_team()

@export var dummy = false
@export var health = 0

@export_group("Knockback")
@export var kb_scale := 1.5       # multiplies the hitbox's own knockback
@export var kb_flat := 150.0      # launch speed added even at 0%
@export var kb_growth := 0.04     # linear gain per % damage
@export var kb_curve := 0.0004    # extra gain that ramps up at high %
@export var kb_max := 3000.0      # speed cap
@export_group("")


@export var local_testing = false

@export var projectile_scene: PackedScene

var coyote_frames = 6
var coyote = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_floor = false
var jumping = false
var dead = false

var _startpos_set = false

var stocks = 3

var doublejumped = false
var recovery_used = false   
var attackFreeze = false
var attacked = false
var jabbing = false

const SYNC_INTERVAL := 0.05 
var _sync_timer := 0.0
var _target_pos := Vector2.ZERO
var _has_state := false

var startpos 

var _owner_id := -1

var facing = 1:
	set(value):
		facing = value
		if is_node_ready():
			_apply_facing()


func _ready():
	
	
	$CoyoteTimer.wait_time = coyote_frames / 60.0
	_apply_team()
	if facing != 1:
		_apply_facing()


	GDSync.expose_func(apply_hit)
	GDSync.expose_func(_receive_state)
	GDSync.expose_func(_end_match)
	
	GDSync.client_left.connect(_on_client_left)


	GDSync.connect_gdsync_owner_changed(self, _on_owner_changed)
	_on_owner_changed(GDSync.get_gdsync_owner(self))


func _on_owner_changed(new_owner: int) -> void:
	if new_owner > 0:
		_owner_id = new_owner
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.enabled = not dummy and (local_testing or GDSync.is_gdsync_owner(self))
		
func _on_client_left(client_id: int) -> void:
	if dummy or local_testing:
		return
	if client_id == _owner_id:
		queue_free()


func _is_authority() -> bool:
	if local_testing:
		return true
	if dummy:
		return GDSync.is_host()
	return GDSync.is_gdsync_owner(self)


func _apply_team() -> void:
	$Heavy1HitBox.team = team
	$JabHitBox.team = team
	$Hurtbox2D.team = team
	$DSpecialHitBox.team = team
	$UJabHitBox.team = team
	$RecoveryHitbox.team = team
	$DJabHitBox.team = team

func _play(anim: StringName) -> void:
	var sprite = $AnimatedSprite2D
	if sprite.animation == anim and sprite.is_playing():
		return
	sprite.play_synced(anim)


func get_input(delta):
	var direction = 0.0 if dummy else Input.get_axis("Left", "Right")

	if direction != 0 and not attackFreeze and not attacked:
		set_facing(sign(direction))

	var busy = attackFreeze or jabbing
	var can_attack = not dummy and not busy

	if Input.is_action_just_pressed("LightAttack") and Input.is_action_pressed("Up") and can_attack:
		jabbing = true
		_play("UpJab")
		$UJabHitBox.activate()
		
		_spawn_projectile(Vector2.UP)
		
	elif Input.is_action_just_pressed("LightAttack") and Input.is_action_pressed("Down") and can_attack:
		jabbing = true
		_play("DJab")
		$DJabHitBox.activate()

	elif Input.is_action_just_pressed("Attac") and Input.is_action_pressed("Up") and can_attack:
		
		if is_on_floor() or not recovery_used:
			jabbing = true
			_play("Recovery")
			$RecoveryHitbox.activate()
			velocity.y = -500
			_spawn_projectile(Vector2.DOWN)
			if not is_on_floor():
				recovery_used = true
				
			

	elif Input.is_action_just_pressed("Attac") and Input.is_action_pressed("Down") and can_attack:
		attackFreeze = true
		_play("DownSpecial")
		$DSpecialHitBox.activate()

	elif Input.is_action_just_pressed("Attac") and can_attack:
		attackFreeze = true
		_play("Heavy")
		$Heavy1HitBox.activate()
		_spawn_projectile(Vector2(facing, 0),$Marker2D)
		

	elif Input.is_action_just_pressed("LightAttack") and can_attack:
		jabbing = true
		_play("kill")
		$JabHitBox.activate()

	busy = attackFreeze or jabbing

	if not attacked:
		if attackFreeze:
			velocity.x = move_toward(velocity.x, 0.0, speed * 10 * delta)
		elif jabbing:
			velocity.x = lerp(velocity.x, 0.0, clamp(friction * delta, 0.0, 1.0))
		elif direction and not dummy:
			velocity.x = lerp(velocity.x, direction * speed, clamp(acceleration * delta, 0.0, 1.0))
			if not jumping:
				_play("walk")
		else:
			velocity.x = lerp(velocity.x, 0.0, clamp(friction * delta, 0.0, 1.0))
			if not jumping:
				_play("default")

	if not dummy:
		if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote):
			velocity.y = jump_speed
			jumping = true
			coyote = false   
		elif Input.is_action_just_pressed("jump") and not doublejumped:
			velocity.y = jump_speed
			jumping = true
			doublejumped = true

	if jumping and not busy:
		if velocity.y < 0:
			_play("Jarona!")
		else:
			_play("ImFalling!")


func _physics_process(delta):
	$Label.text = str(int(health)) + "%"
	
	$Label2.text = str(stocks) + "/3"


	if not _is_authority():
		if _has_state:
			if position.distance_to(_target_pos) > 200.0:
				position = _target_pos
			else:
				position = position.lerp(_target_pos, clamp(delta * 20.0, 0.0, 1.0))
		return
		
	if not _startpos_set:
		startpos = position
		_startpos_set = true


	if not local_testing:
		_sync_timer += delta
		if _sync_timer >= SYNC_INTERVAL:
			_sync_timer = 0.0
			GDSync.call_func(_receive_state, position, facing, health, stocks)

	velocity.y += gravity * delta
	if dead:
		return
	get_input(delta)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i).get_collider()
		var n = get_slide_collision(i).get_normal()
		if c.is_in_group("pushable"):
			if c.has_method("apply_central_impulse_synced"):
				c.apply_central_impulse_synced(-n * 5)
			else:
				c.apply_central_impulse(-n * 5)

	if is_on_floor() and jumping:
		jumping = false

	if !is_on_floor() and last_floor and !jumping:
		coyote = true
		$CoyoteTimer.start()

	last_floor = is_on_floor()

	
	if is_on_floor():
		doublejumped = false
		recovery_used = false


func _on_coyote_timer_timeout():
	coyote = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "kill":
		jabbing = false
		$JabHitBox.deactivate()

	if $AnimatedSprite2D.animation == "UpJab":
		jabbing = false
		$UJabHitBox.deactivate()

	if $AnimatedSprite2D.animation == "Heavy":
		attackFreeze = false
		$Heavy1HitBox.deactivate()

	if $AnimatedSprite2D.animation == "DownSpecial":
		attackFreeze = false
		$DSpecialHitBox.deactivate()

	if $AnimatedSprite2D.animation == "Recovery":
		jabbing = false
		$RecoveryHitbox.deactivate()
		
	if $AnimatedSprite2D.animation == "DJab":
		jabbing = false
		$DJabHitBox.deactivate()


func _on_hurtbox_2d_hurt(damage: float, source: Node, knockback: Vector2) -> void:
	if _is_authority():
		apply_hit(damage, knockback)
	else:
		GDSync.call_func(apply_hit, damage, knockback)


func apply_hit(damage: float, knockback: Vector2) -> void:
	if not _is_authority():
		return

	health += damage   # this hit's damage counts toward its own launch
	var magnitude = _calc_knockback(knockback)
	velocity = knockback.normalized() * magnitude
	velocity.y = min(velocity.y, -100)

	attacked = true
	# harder hits = longer stun, so friction doesn't kill the launch early
	$AttackTimer.start(clamp(magnitude / 2000.0, 0.2, 0.9))

	jabbing = false
	attackFreeze = false
	$JabHitBox.deactivate()
	$UJabHitBox.deactivate()
	$Heavy1HitBox.deactivate()
	$DSpecialHitBox.deactivate()
	$RecoveryHitbox.deactivate()
	$DJabHitBox.deactivate()


func _calc_knockback(knockback: Vector2) -> float:
	var p = health
	var multiplier = 1.0 + p * kb_growth + p * p * kb_curve
	return min((knockback.length() * kb_scale + kb_flat) * multiplier, kb_max)


func set_facing(dir: float) -> void:
	facing = dir


func _apply_facing() -> void:
	$AnimatedSprite2D.flip_h = facing < 0

	for box in [$Heavy1HitBox, $JabHitBox, $Hurtbox2D, $DSpecialHitBox, $UJabHitBox, $RecoveryHitbox,$DJabHitBox]:
		box.position.x = abs(box.position.x) * facing
		box.scale.x = facing
		
	for point in [$Marker2D]:
		point.position.x = abs(point.position.x) * facing


func _receive_state(pos: Vector2, face: float, hp: float, stk: int) -> void:
	if _is_authority():
		return
	if not _has_state:
		position = pos         
		_has_state = true
	_target_pos = pos
	facing = face
	health = hp
	stocks = stk


func _on_attack_timer_timeout() -> void:
	attacked = false


func _spawn_projectile(dir: Vector2, spawn_point: Marker2D = null) -> void:
	if projectile_scene == null:
		return

	dir = dir.normalized()

	var proj: Node
	if local_testing:
		proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
	else:
		proj = GDSync.multiplayer_instantiate(projectile_scene, get_parent(), true)

	if spawn_point:
		proj.global_position = spawn_point.global_position
	else:
		proj.global_position = global_position + dir * 20

	proj.rotation = dir.angle()

	if "direction" in proj:
		proj.direction = dir
	if "team" in proj:
		proj.team = team



func _on_death_plane_hit_box_area_entered(area: Area2D) -> void:
	if not _is_authority():
		return
	if area.is_in_group("KillPlane"):
		stocks -= 1
		if stocks <= 0:
			if not local_testing:
				GDSync.call_func(_end_match)  # every other client
			_end_match()                      # this client
			return
		position = startpos
		velocity = Vector2.ZERO
		doublejumped = false
		recovery_used = false
		
func _end_match() -> void:
	var frames: SpriteFrames = $AnimatedSprite2D.sprite_frames
	MatchResult.loser_name = character_name
	MatchResult.loser_texture = frames.get_frame_texture("default", 0)
	get_tree().change_scene_to_file("res://InMemorium.tscn")
	
