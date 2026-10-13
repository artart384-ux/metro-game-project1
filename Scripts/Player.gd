extends CharacterBody2D

# --- การเคลื่อนไหวพื้นฐาน ---
const SPEED: float = 250.0
const JUMP_VELOCITY: float = -420.0
const GRAVITY: float = 1100.0

# --- ระบบ Dash ---
const DASH_SPEED: float = 650.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.4

var facing_direction: float = 1.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var can_air_dash: bool = true

# --- ระบบต่อสู้ & คูลดาวน์ ---
const LIGHT_ATTACK_COOLDOWN: float = 0.25
const HEAVY_ATTACK_COOLDOWN: float = 0.65

var attack_cooldown_timer: float = 0.0
var attack_damage: int = 0
var attack_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea

func _physics_process(delta: float) -> void:
	# อัปเดต Cooldown ของการโจมตี
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	# อัปเดต Cooldown ของ Dash
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# คืนค่าแอร์แดช (Air Dash) เมื่อเท้าสัมผัสพื้น
	if is_on_floor():
		can_air_dash = true

	# 1. จัดการสถานะขณะ Dash
	if is_dashing:
		dash_timer -= delta
		velocity.y = 0.0 # ต้านแรงโน้มถ่วงขณะพุ่งกลางอากาศ
		
		# เมื่อหมดเวลา Dash
		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x = facing_direction * SPEED
			if sprite:
				sprite.scale = Vector2(1.0, 1.0)
		
		move_and_slide()
		return

	# 2. เพิ่มแรงโน้มถ่วงเมื่ออยู่กลางอากาศ
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 3. รับคำสั่งเดินซ้ายและขวา + อัปเดต Hitbox ตามทิศทาง
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing_direction = direction
		# ย้าย Hitbox ไปตามทิศที่ตัวละครหัน
		if attack_area:
			attack_area.position.x = 35.0 * facing_direction
		if sprite:
			sprite.flip_h = (facing_direction < 0.0)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)

	# 4. กระโดดเมื่อกดปุ่ม Space
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 5. ตรวจสอบการกดปุ่ม Dash (Shift)
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		if is_on_floor() or can_air_dash:
			start_dash(direction)

	# 6. คืนสเกลของ Sprite อย่างนุ่มนวล
	if sprite and not is_dashing:
		sprite.scale = sprite.scale.move_toward(Vector2(1.0, 1.0), 5.0 * delta)

	# คำนวณการเคลื่อนที่และการชน
	move_and_slide()

## เริ่มต้นการ Dash
func start_dash(input_dir: float) -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	
	if not is_on_floor():
		can_air_dash = false
	
	var dash_dir: float = input_dir if input_dir != 0.0 else facing_direction
	facing_direction = dash_dir
	
	if attack_area:
		attack_area.position.x = 35.0 * facing_direction
	if sprite:
		sprite.flip_h = (facing_direction < 0.0)
		sprite.scale = Vector2(1.3, 0.75)
		
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0.0

## ฟังก์ชันโจมตีและตรวจจับ Hitbox
func perform_attack(damage: int) -> void:
	attack_damage = damage
	attack_active = true

	# เอฟเฟกต์กระตุกฟันดาบเล็กน้อย (Visual Juice)
	if sprite:
		sprite.scale = Vector2(1.2, 0.9)

	var hit_count := 0
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)
				hit_count += 1

	if hit_count == 0:
		print("Swung sword but hit nothing! (วืด)")

	attack_active = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if attack_cooldown_timer <= 0.0:
			print("LIGHT ATTACK! 🗡️")
			perform_attack(20)
			attack_cooldown_timer = LIGHT_ATTACK_COOLDOWN

	elif event.is_action_pressed("heavy_attack"):
		if attack_cooldown_timer <= 0.0:
			print("HEAVY ATTACK! 💥")
			perform_attack(40)
			attack_cooldown_timer = HEAVY_ATTACK_COOLDOWN

	elif event.is_action_pressed("parry"):
		print("PARRY! 🛡️")
