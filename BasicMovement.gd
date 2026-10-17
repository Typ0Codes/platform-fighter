extends CharacterBody2D

@export var speed = 150
@export var jump_speed = -350
@export var acceleration = 15
@export var friction = 16
@export var team = 1

@export var dummy = false

@export var health = 0

var coyote_frames = 6
var coyote = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_floor = false
var jumping = false
var dead = false

var doublejumped = false

var attackFreeze = false

var facing = 1

var attacked = false

var jabbing = false


func _ready():
	$CoyoteTimer.wait_time = coyote_frames / 60.0
	
	$Heavy1HitBox.team = team
	$JabHitBox.team = team
	$Hurtbox2D.team = team
	$DSpecialHitBox.team = team
	$UJabHitBox.team = team
	$RecoveryHitbox.team = team

func get_input(delta):
	var direction = Input.get_axis("Left", "Right")

	if direction != 0 and not attackFreeze and not attacked:
		set_facing(sign(direction))

	var busy = attackFreeze or jabbing

	if Input.is_action_just_pressed("LightAttack") and Input.is_action_pressed("Up") and not busy:
		jabbing = true
		$AnimatedSprite2D.play("UpJab")
		$UJabHitBox.activate()   # was $JabHitBox, matches the deactivate below
		
	elif Input.is_action_just_pressed("Attac") and Input.is_action_pressed("Up") and not busy:
		jabbing = true
		$AnimatedSprite2D.play("Recovery")
		$RecoveryHitbox.activate()
		velocity.y = -500
		
	elif Input.is_action_just_pressed("Attac") and Input.is_action_pressed("Down") and not busy:
		attackFreeze = true
		$AnimatedSprite2D.play("DownSpecial")
		$DSpecialHitBox.activate()
	elif Input.is_action_just_pressed("Attac") and not busy:
		attackFreeze = true
		$AnimatedSprite2D.play("Heavy")
		$Heavy1HitBox.activate()
	elif Input.is_action_just_pressed("LightAttack") and not busy:
		jabbing = true
		$AnimatedSprite2D.play("kill")
		$JabHitBox.activate()

	# Re-evaluate after possible attack start
	busy = attackFreeze or jabbing

	if not attacked:
		if attackFreeze:
			velocity.x = move_toward(velocity.x, 0.0, speed * 10 * delta)
		elif jabbing:
			velocity.x = lerp(velocity.x, 0.0, clamp(friction * delta, 0.0, 1.0))
		elif direction and not dummy:
			velocity.x = lerp(velocity.x, direction * speed, clamp(acceleration * delta, 0.0, 1.0))
			if not jumping:
				$AnimatedSprite2D.play("walk")
		else:
			velocity.x = lerp(velocity.x, 0.0, clamp(friction * delta, 0.0, 1.0))
			if not jumping:
				$AnimatedSprite2D.play("default")

	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote) and not dummy:
		velocity.y = jump_speed
		jumping = true
	elif Input.is_action_just_pressed("jump") and not doublejumped and not dummy:
		velocity.y = jump_speed
		jumping = true
		doublejumped = true

	# Only play air animations when not attacking
	if jumping and not busy:
		if velocity.y < 0:
			$AnimatedSprite2D.play("Jarona!")
		else:
			$AnimatedSprite2D.play("ImFalling!")
		
	
	
func _physics_process(delta):
	
	$Label.text = str(health)
	
	velocity.y += gravity * delta
	if dead:
		print("Dead")
		return
	get_input(delta)
	move_and_slide()
	for i in get_slide_collision_count():
		var c = get_slide_collision(i).get_collider()
		var n = get_slide_collision(i).get_normal()
		if c.is_in_group("pushable"):
			c.apply_central_impulse(-n * 5)
#			c.set_axis_velocity(-n * 10)
	if is_on_floor() and jumping:
		jumping = false
		
	if !is_on_floor() and last_floor and !jumping:
		coyote = true
		$CoyoteTimer.start()
	
	last_floor = is_on_floor()
	
	if is_on_floor() and doublejumped:
		doublejumped = false


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


func _on_hurtbox_2d_hurt(damage: float, source: Node, knockback: Vector2) -> void:
	var magnitude = knockback.length() * (1.0 + health * 0.05) + 200.0
	velocity = knockback.normalized() * magnitude
	velocity.y = min(velocity.y, -100) 

	health += damage
	attacked = true
	$AttackTimer.start()
	
	jabbing = false
	attackFreeze = false
	$JabHitBox.deactivate()
	$UJabHitBox.deactivate()
	$Heavy1HitBox.deactivate()
	$DSpecialHitBox.deactivate()
	
	
func set_facing(dir: float) -> void:
	facing = dir
	$AnimatedSprite2D.flip_h = dir < 0
	
	for box in [$Heavy1HitBox, $JabHitBox, $Hurtbox2D, $DSpecialHitBox, $UJabHitBox]:
		box.position.x = abs(box.position.x) * dir
		box.scale.x = dir


func _on_attack_timer_timeout() -> void:
	attacked = false
