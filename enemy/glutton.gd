extends "res://enemy/base_enemy.gd"

# 暴食者特殊状态
enum GluttonState {
	NORMAL,     # 正常状态
	OVERLOADED, # 过载状态（受到伤害时体型膨胀、颜色变红）
}

# 暴食者特有属性
var accumulatedDamage: int = 0  # 累计受到的伤害
var originalScale: Vector2     # 原始体型大小
var overloadScaleMultiplier: float = 1.3  # 过载状态体型膨胀倍数
var originalModulate: Color    # 原始颜色
var overloadColor: Color = Color(1.0, 0.3, 0.3)  # 过载状态颜色（红色）

# 特殊机制参数
var aoeExplosionRadius: float = 150.0  # AOE爆炸半径
var aoeDamageMultiplier: float = 3.0   # AOE爆炸伤害倍数（相对于自身最大生命值）

func _ready() -> void:
	baseDir = true
	super()
	attCd = 10  # 10秒攻击间隔
	
	# 设置暴食者基础属性
	speed = 30  # 移动缓慢（比普通敌人慢）
	damage = 4  # 近战物理攻击伤害（普通僵尸的4倍）
	
	# 保存原始外观属性
	if scale != null:
		originalScale = scale
	else:
		originalScale = Vector2(1, 1)
	if modulate != null:
		originalModulate = modulate
	else:
		originalModulate = Color(1, 1, 1, 1)
	
	# 初始化生命值（在initData之后设置）
	await get_tree().create_timer(0.1).timeout
	health = int(health * 2.5)  # 高生命值（普通敌人的2.5倍）

func initData(Mul: float):
	# 调用父类初始化
	super(Mul)
	
	# 根据等级进一步调整属性
	var temp = Level.currentLevel
	var baseHealth = int(temp / 5.0) * 2 + 5
	health = int(baseHealth * 2.5)  # 基础高生命值
	
	# 应用乘法器
	if Mul > 1:
		var healthMul: float = Mul
		var sizeMul: float = Mul
		var speedMul: float = 2.0 - Mul
		
		health = int(health * healthMul)
		self.scale = self.scale * sizeMul
		speed = int(speed * speedMul)
		damage = int(damage * Mul)
	
	# 确保移动速度不会过快
	if speed > 40:
		speed = 40
	
	# 重新保存调整后的原始属性
	originalScale = scale
	originalModulate = modulate

func _enter_state(new_state: state, _last_state: state = state.nothing):
	_last_state = currentState
	if new_state != currentState:
		currentState = new_state
		
		match currentState:
			state.idle:
				animation_player.play("idle")
			state.walk:
				animation_player.play("walk")
			state.att:
				animation_player.play("att")
				timer.start(attCd)
				animation_player.animation_finished.connect(func(_animeName):
					_enter_state(state.idle)
					, CONNECT_ONE_SHOT)
			state.hurt:
				animation_player.play("hurt")
				animation_player.animation_finished.connect(func(_animeName):
					if _last_state != state.nothing:
						_enter_state(_last_state)
					, CONNECT_ONE_SHOT)
			state.death:
				animation_player.play("death")
				animation_player.animation_finished.connect(func(_animeName):
					die()
					, CONNECT_ONE_SHOT)

# 重写getHurt方法，实现过载状态机制
func getHurt(_damage: int):
	# 累计受到伤害
	accumulatedDamage += _damage
	
	# 检查是否进入过载状态
	
	# 检查过载爆破条件（累计伤害 >= 总生命值）
	if accumulatedDamage >= health:
		triggerAOEExplosion()
		return  # AOE爆炸后死亡，不再执行后续逻辑
	
	# 普通受伤逻辑
	health -= _damage
	if health <= 0:
		_enter_state(state.death)
	else:
		_enter_state(state.hurt)


func triggerAOEExplosion():
	# 创建爆炸视觉效果
	createExplosionEffect()
	
	# 对周围敌人造成伤害
	var enemies = get_tree().get_nodes_in_group("enemy")
	var explosionCenter = global_position
	
	for enemy in enemies:
		if enemy == self:
			continue  # 不对自己造成伤害
			
		# 计算距离
		var distance = enemy.global_position.distance_to(explosionCenter)
		
		# 如果在爆炸范围内
		if distance <= aoeExplosionRadius:
			# 计算伤害（距离越近伤害越高）
			var damageRatio = 1.0 - (distance / aoeExplosionRadius)
			var explosionDamage = int(health * aoeDamageMultiplier * damageRatio)
			
			# 确保至少有最低伤害
			if explosionDamage < 10:
				explosionDamage = 10
			
			# 对敌人造成伤害
			if enemy.has_method("getHurt"):
				enemy.getHurt(explosionDamage)
	
	# 播放爆炸音效（如果AudioManager可用且有爆炸音效）
	if AudioManager and AudioManager.has_method("play_sfx"):
		if AudioManager.sfx_library.has("explosion"):
			AudioManager.play_sfx("explosion")
	
	# 自身死亡
	_enter_state(state.death)

# 创建爆炸视觉效果
func createExplosionEffect():
	# 创建爆炸圆圈
	var explosionCircle = ColorRect.new()
	explosionCircle.size = Vector2(aoeExplosionRadius * 2, aoeExplosionRadius * 2)
	explosionCircle.position = Vector2(-aoeExplosionRadius, -aoeExplosionRadius)
	explosionCircle.color = Color(1, 0.5, 0, 0.3)
	explosionCircle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# 添加到场景中
	add_child(explosionCircle)
	
	# 动画效果
	var tween = create_tween()
	tween.tween_property(explosionCircle, "scale", Vector2(0.1, 0.1), 0.5)
	tween.tween_property(explosionCircle, "modulate:a", 0, 0.5)
	tween.tween_callback(explosionCircle.queue_free)

# 重写接触逻辑，实现接触自爆（Bad结局）
func _on_eye_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerbox.append(body)
		
		# 如果还未过载死亡，接触玩家时自爆

func _on_eye_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if playerbox.has(body):
			playerbox.erase(body)

# 触发接触自爆（Bad结局）
func triggerContactExplosion(player_body: Node2D):
	# 创建自爆视觉效果
	createSelfExplosionEffect()
	
	# 对玩家造成极高伤害
	var contactDamage = damage * 4  # 约普通僵尸的4倍伤害
	if player_body.has_method("getHurt"):
		player_body.getHurt(contactDamage)
	
	# 播放爆炸音效（如果AudioManager可用且有爆炸音效）
	if AudioManager and AudioManager.has_method("play_sfx"):
		if AudioManager.sfx_library.has("explosion"):
			AudioManager.play_sfx("explosion")
	
	# 自身死亡
	_enter_state(state.death)

# 创建自爆视觉效果
func createSelfExplosionEffect():
	# 创建爆炸效果
	var explosionEffect = ColorRect.new()
	explosionEffect.size = Vector2(64, 64)
	explosionEffect.position = Vector2(-32, -32)
	explosionEffect.color = Color(1, 0, 0, 0.8)
	explosionEffect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# 添加到场景中
	add_child(explosionEffect)
	
	# 动画效果
	var tween = create_tween()
	tween.tween_property(explosionEffect, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(explosionEffect, "modulate:a", 0, 0.3)
	tween.tween_callback(explosionEffect.queue_free)


# 创建小型爆炸效果
func createSmallExplosionEffect():
	var smallExplosion = ColorRect.new()
	smallExplosion.size = Vector2(48, 48)
	smallExplosion.position = Vector2(-24, -24)
	smallExplosion.color = Color(1, 0.3, 0.3, 0.6)
	smallExplosion.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	add_child(smallExplosion)
	
	var tween = create_tween()
	tween.tween_property(smallExplosion, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(smallExplosion, "modulate:a", 0, 0.2)
	tween.tween_callback(smallExplosion.queue_free)
