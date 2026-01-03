extends Node2D

## 燃烧瓶实体 - 使用 Tween 动画模拟伪3D抛物线投掷
## 这种方案可以精确控制落点，适合技能逻辑

# 导出配置参数
@export var throw_duration: float = 0.6  # 投掷持续时间（秒）
@export var arc_height: float = 150.0    # 抛物线高度（像素）
@export var rotation_speed: float = 720.0  # 旋转速度（度/秒）
@export var shadow_min_scale: float = 0.3  # 阴影最小缩放（最高点时）
@export var shadow_min_alpha: float = 0.2  # 阴影最小透明度（最高点时）

@onready var visual_layer: Node2D = $VisualLayer
@onready var bottle_sprite: Sprite2D = $VisualLayer/Bottle
@onready var shadow_sprite: Sprite2D = $Shadow

var fire_scene: PackedScene = preload("res://globalSkillData/fire.tscn")
var target_pos: Vector2
var start_pos: Vector2
var is_thrown: bool = false

func _ready() -> void:
	# 初始时让瓶子稍微大一点，模拟拿在手里
	visual_layer.scale = Vector2(1.2, 1.2)
	# 阴影初始状态
	shadow_sprite.modulate.a = 0.5
	top_level = true

## 投掷燃烧瓶到目标位置
## @param pos: 目标位置（世界坐标）
## @param _duration: 可选的投掷持续时间
func throw_to(pos: Vector2, _duration: float = -1.0) -> void:
	if _duration > 0:
		throw_duration = _duration
	
	target_pos = pos
	start_pos = global_position
	is_thrown = true
	
	# 重置视觉层位置
	visual_layer.position = Vector2.ZERO
	visual_layer.scale = Vector2(1.2, 1.2)
	bottle_sprite.rotation = 0
	
	# 1. 水平移动（线性 - 保证精确落点）
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, throw_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	
	# 2. 垂直高度模拟（抛物线）
	# 使用 visual_layer 的 position.y 来模拟高度（负值表示向上）
	var height_tween = create_tween()
	# 上升阶段：ease_out 表示开始快、结束慢
	height_tween.tween_property(visual_layer, "position:y", -arc_height, throw_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 下落阶段：ease_in 表示开始慢、结束快（模拟重力）
	height_tween.tween_property(visual_layer, "position:y", 0.0, throw_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# 3. 旋转模拟（空中翻滚）
	var rotate_tween = create_tween()
	rotate_tween.tween_property(bottle_sprite, "rotation", deg_to_rad(rotation_speed * throw_duration), throw_duration).set_trans(Tween.TRANS_LINEAR)
	
	# 4. 阴影效果：同时缩放和改变透明度
	# 高度越高，阴影越小且越淡
	var shadow_tween = create_tween()
	# 上升到最高点：阴影变小变淡
	var shadow_max_scale = Vector2(1.0, 0.6)
	var shadow_min_scale_vec = Vector2(shadow_min_scale, shadow_min_scale * 0.6)
	shadow_tween.tween_property(shadow_sprite, "scale", shadow_min_scale_vec, throw_duration / 2.0)
	shadow_tween.tween_property(shadow_sprite, "modulate:a", shadow_min_alpha, throw_duration / 2.0)
	# 下降到地面：阴影恢复
	shadow_tween.tween_property(shadow_sprite, "scale", shadow_max_scale, throw_duration / 2.0)
	shadow_tween.tween_property(shadow_sprite, "modulate:a", 0.5, throw_duration / 2.0)
	
	# 结束回调：连接水平移动的完成事件
	tween.finished.connect(_on_landed)

## 落地事件处理
func _on_landed() -> void:
	if not is_thrown:
		return
	
	is_thrown = false
	
	# 1. 生成火焰（火区 Area2D）
	_fire_spawn()
	
	# 2. 播放碎瓶音效（如果音频管理器存在）
	_play_break_sound()
	
	# 3. 播放碎裂特效（如果有）
	_play_break_effect()
	
	# 4. 销毁自身
	queue_free()

## 生成火焰
func _fire_spawn() -> void:
	if not fire_scene:
		push_error("Fire scene not loaded!")
		return
	
	var fire = fire_scene.instantiate()
	
	# 需要将火添加到场景中
	var parent = get_parent()
	if not parent:
		queue_free()
		return
	
	parent.add_child(fire)
	fire.global_position = global_position
	
	# 初始化火焰（如果火场景有初始化方法）
	if fire.has_method("initialize"):
		fire.initialize()

## 播放碎瓶音效
func _play_break_sound() -> void:
	# 检查是否有音频管理器
	if get_tree().root.has_node("AudioManager"):
		var audio_manager = get_tree().root.get_node("AudioManager")
		if audio_manager.has_method("play_sfx"):
			# 假设有 molotov_break 音效
			audio_manager.play_sfx("molotov_break")

## 播放碎裂特效
func _play_break_effect() -> void:
	# TODO: 可以添加粒子特效或动画来表现瓶子碎裂
	# 目前使用简单的闪烁效果
	bottle_sprite.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(bottle_sprite, "modulate:a", 0.0, 0.1)
