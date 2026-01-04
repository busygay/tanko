extends Area2D

## 地雷实体 - 使用 Tween 动画模拟伪3D抛物线投掷
## 落地后变成静止地雷，等待敌人触发爆炸

# 导出配置参数
@export var damage: float = 20.0
@export var explosion_radius: float = 100.0
@export var knockback_force: float = 200.0
@export var trigger_delay: float = 0.5

# 投掷相关参数
@export var throw_duration: float = 0.6  # 投掷持续时间（秒）
@export var arc_height: float = 120.0    # 抛物线高度（像素）
@export var shadow_min_scale: float = 0.3  # 阴影最小缩放（最高点时）
@export var shadow_min_alpha: float = 0.2  # 阴影最小透明度（最高点时）

@onready var visual_layer: Node2D = $VisualLayer
@onready var sprite: Sprite2D = $VisualLayer/Sprite2D
@onready var shadow_sprite: Sprite2D = $Shadow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_triggered: bool = false
var _is_landed: bool = false
var start_pos: Vector2

## 地雷图片和skillcard地雷用了同一个素材.

func _ready() -> void:
	# 设置检测半径
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 20.0 # 触发半径较小
	
	# 阴影初始状态
	shadow_sprite.modulate.a = 0.5
	top_level = true

## 投掷地雷到目标位置
## @param pos: 目标位置（世界坐标）
## @param _duration: 可选的投掷持续时间
func throw_to(pos: Vector2, _duration: float = -1.0) -> void:
	if _duration > 0:
		throw_duration = _duration
	
	start_pos = global_position
	
	# 禁用碰撞检测直到落地
	collision_shape.disabled = true
	
	# 1. 水平移动（线性 - 保证精确落点）
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, throw_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	
	# 2. 垂直高度模拟（抛物线）
	# 使用 visual_layer 的 position.y 来模拟高度（负值表示向上）
	var height_tween = create_tween()
	# 上升阶段：ease_out 表示开始快、结束慢
	height_tween.tween_property(visual_layer, "position:y", -arc_height, throw_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 下落阶段：ease_in 表示开始慢、结束快（模拟重力）
	height_tween.tween_property(visual_layer, "position:y", 0.0, throw_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# 3. 旋转模拟（地雷不需要像燃烧瓶那样旋转太多）
	var rotate_tween = create_tween()
	rotate_tween.tween_property(visual_layer, "rotation", PI, throw_duration).set_trans(Tween.TRANS_LINEAR)
	
	# 4. 阴影效果：同时缩放和改变透明度
	# 高度越高，阴影越小且越淡
	var shadow_tween = create_tween()
	var shadow_max_scale = Vector2(1.0, 0.6)
	var shadow_min_scale_vec = Vector2(shadow_min_scale, shadow_min_scale * 0.6)
	shadow_tween.tween_property(shadow_sprite, "scale", shadow_min_scale_vec, throw_duration / 2.0)
	shadow_tween.tween_property(shadow_sprite, "modulate:a", shadow_min_alpha, throw_duration / 2.0)
	shadow_tween.tween_property(shadow_sprite, "scale", shadow_max_scale, throw_duration / 2.0)
	shadow_tween.tween_property(shadow_sprite, "modulate:a", 0.5, throw_duration / 2.0)
	
	# 结束回调
	tween.finished.connect(_on_landed)

## 落地事件处理
func _on_landed() -> void:
	_is_landed = true
	
	# 恢复视觉层位置
	visual_layer.position = Vector2.ZERO
	visual_layer.rotation = 0
	
	# 启用碰撞检测
	collision_shape.disabled = false
	
	# 播放落地音效（可选）
	_play_land_sound()

## 播放落地音效
func _play_land_sound() -> void:
	# 检查是否有音频管理器
	if get_tree().root.has_node("AudioManager"):
		var audio_manager = get_tree().root.get_node("AudioManager")
		if audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("mine_land")

func _on_area_entered(area: Area2D) -> void:
	if _is_triggered:
		return
	
	if not _is_landed:
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
