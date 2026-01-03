extends Area2D

@export var damage: float = 20.0
@export var explosion_radius: float = 100.0
@export var knockback_force: float = 200.0
@export var trigger_delay: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_triggered: bool = false

## 地雷图片和skillcard地雷用了同一个素材.

func _ready() -> void:
	# 设置检测半径
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 20.0 # 触发半径较小

func _on_area_entered(area: Area2D) -> void:
	if _is_triggered:
		return
		
	if area.is_in_group("enemy") or area.get_parent().is_in_group("enemy"):
		_trigger_landmine()

func _trigger_landmine() -> void:
	_is_triggered = true
	# 播放触发音效或动画（可选）
	# flash effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, trigger_delay / 2.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, trigger_delay / 2.0)
	await tween.finished
	_explode()

func _explode() -> void:
	# 真正的爆炸伤害逻辑
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is Node2D:
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= explosion_radius:
				_apply_damage(enemy)
	
	# 爆炸视觉效果（临时使用缩放和粒子，如果有的话）
	# TODO: 播放爆炸粒子效果
	queue_free()

func _apply_damage(enemy: Node) -> void:
	if enemy.has_method("getHurt"):
		# 假设敌人有 getHurt(damage, dir) 方法
		var dir = (enemy.global_position - global_position).normalized()
		enemy.getHurt(damage, dir * knockback_force)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(damage)
