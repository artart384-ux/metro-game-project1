extends StaticBody2D

var max_hp: int = 100
var hp: int = 100

func take_damage(damage: int) -> void:
	hp -= damage
	hp = max(hp, 0)

	print("Enemy took ", damage, " damage! 💥")
	print("Enemy HP: ", hp, "/", max_hp)

	# เอฟเฟกต์กระพริบสีขาว/ส้มเมื่อโดนดาเมจ
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.8, 0.3, 0.85, 1.0), 0.15)

	if hp <= 0:
		die()

func die() -> void:
	print("Enemy defeated! 💀 (ศัตรูถูกกำจัด)")
	queue_free()

