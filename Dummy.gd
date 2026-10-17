extends CharacterBody2D

@export var speed = 150
@export var jump_speed = -350
@export var acceleration = 15
@export var friction = 16
@export var team = 1

var coyote_frames = 6
var coyote = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_floor = false
var jumping = false
var dead = false

var doublejumped = false

var attacking = false

var facing = 1

var attacked = false


func _ready():
	$CoyoteTimer.wait_time = coyote_frames / 60.0
	
	$Heavy1HitBox.team = team
	$Hurtbox2D.team = team

func get_input(delta):
	var direction = Input.get_axis("Left", "Right")

	if direction != 0 and not attacking:
		set_facing(sign(direction))

	if Input.is_action_just_pressed("Attac") and not attacking:
		attacking = true
		$AnimatedSprite2D.play("kill")
		$Heavy1HitBox.activate()

	if attacking:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
	elif direction:
		#velocity.x = lerp(velocity.x, direction * speed, acceleration * delta)
		$AnimatedSprite2D.play("walk")
	elif not attacked:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		$AnimatedSprite2D.play("default")


	if jumping:
		if velocity.y < 0:
			print("jump up ani")
		elif velocity.y > 0:
			print("jump down ani")

	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote):
		#velocity.y = jump_speed
		jumping = true
	elif Input.is_action_just_pressed("jump") and not doublejumped:
		velocity.y = jump_speed
		jumping = true
		doublejumped = true
		
	
	
func _physics_process(delta):
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
		attacking = false
		$Heavy1HitBox.deactivate()


func _on_hurtbox_2d_hurt(damage: float, source: Node, knockback: Vector2) -> void:
	velocity.y = 5
	velocity += knockback * 500
	attacked = true
	await get_tree().create_timer(0.05).timeout  
	get_tree().paused = true   
	await get_tree().create_timer(0.1).timeout   
	get_tree().paused = false   
	$AttackTimer.start()
	
func set_facing(dir: float) -> void:
	facing = dir
	$AnimatedSprite2D.flip_h = dir < 0
	for box in [$Heavy1HitBox, $Hurtbox2D]:
		box.position.x = abs(box.position.x) * dir
		box.scale.x = dir


func _on_attack_timer_timeout() -> void:
	attacked = false
