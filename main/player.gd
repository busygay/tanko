extends CharacterBody2D
class_name players
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot_point_mark: Marker2D = $hand/shootPointMark
@onready var hand: AnimatedSprite2D = $hand
@onready var bodys: AnimatedSprite2D = $body
@onready var baseshoot_cdtimer: Timer = $baseshootCDtimer
@onready var label: Label = $Label
@onready var gun_shoot_player_2d: AudioStreamPlayer2D = $gunShootPlayer2D
##用于设置无敌的timer
@onready var parryInvincibleTimer: Timer = $parryInvincible
@onready var hurtInvincibleTimer: Timer = $hurtInvincible
@onready var sword: Sprite2D = $sword

#用于无敌判断的bool
var is_hurt_invincible := false
var is_parry_invincible := false
var breakInvincibleCount: int

# drain debuff
var drainDebuffLayers: int:
	set(new):
		if drainDebuffLayers >= 10:
			return
		if new > drainDebuffLayers:
			get_tree().create_timer(1).timeout.connect(func():
				drainDebuffLayers -= 1
				)
		drainDebuffLayers = new

@export var MaxHealth: int = 10
@export var baseshootCD: float
@export var baseDamage: float

var health: int
#基础伤害加成变量
var attackBonus: int = 0 # 攻击力加成(百分比，如10表示10%)
var globalDamageBonus: int = 0 # 全局伤害加成(百分比，如20表示20%)
var trueDamageRatio: float = 0.0
var criticalChance: int = 10 # 暴击率(百分比，初始10%)
var criticalRatio: int = 50 # 暴击伤害加成(百分比，初始50%)


var inshootcd: bool = false
var reloading: bool
#子弹数量和最大子弹数
var MaxAmmo = 7
var currentAmmo:
	set(new):
		currentAmmo = new
		Eventmanger.bulletCountChange.emit(currentAmmo)


var enemy: Array[Node2D]

#一个子弹可以发射的次数，类似于doubleShoot的作用数
var bulletCount: int = 1
# 首先，我们定义一个枚举来清晰地表示所有可能的状态
enum State {
	IDLE,
	SHOOT,
	RELOAD,
	NOTHING
}

# 用于管理当前状态的变量
var current_state: State = State.NOTHING

func _ready() -> void:
	Eventmanger.register_player(self)
	##skillSingal
	Eventmanger.playerGlobalDamageBonusChange.connect(func(bonus: int):
		globalDamageBonus = bonus
	)
	Eventmanger.playerCdSub.connect(BaseShootCdSub)
	Eventmanger.playerbulletCount.connect(_bulletCountChangeFunc)
	Eventmanger.playerBaseDamageUp.connect(BaseDamageUp)
	Eventmanger.playerTrueDamageUp.connect(TrueDamageUp)
	Eventmanger.reloadAmmo.connect(reloadAmmofunc)
	Eventmanger.playerGotHurt.connect(getHurt)
	
	#	Drainbuff
	Eventmanger.getCorrectCount.connect(_DrainDebuff)
	
	#无敌信号连接


	# 将动画完成的逻辑连接到一个更具体的处理函数
	animation_player.animation_finished.connect(_on_animation_finished)
	_init()
	# 初始化进入IDLE状态
	_enter_state(State.IDLE)
	

func _init() -> void:
	health = MaxHealth
	currentAmmo = MaxAmmo
	enemy = []

@warning_ignore('unused_parameter')
func _physics_process(delta: float) -> void:
	# 每帧都执行的逻辑，与状态无关或在多数状态下都需要
	lookAtEnemy()
	
	# 使用 match 语句根据当前状态执行不同的逻辑
	# 这比多个 if 语句更清晰，也更容易扩展
	match current_state:
		State.IDLE:
			# 在IDLE状态下，检查是否可以开始射击
			if not enemy.is_empty() and not inshootcd:
				_enter_state(State.SHOOT)
				return
		State.SHOOT:
			# 在SHOOT状态下，如果敌人消失了，返回IDLE
			if enemy.is_empty():
				_enter_state(State.IDLE)
				
		State.RELOAD:
			# 重装弹药状态的逻辑由动画和其回调函数驱动，所以这里不需要做什么
			pass

# 这是一个新的核心函数，用于管理所有状态的转换
# 所有改变状态的操作都应该通过这个函数
func _enter_state(new_state: State) -> void:
	# 如果要进入的状态和当前状态相同，则不执行任何操作
	if new_state == current_state:
		return
	# 根据要进入的新状态，执行相应的“进入”逻辑
	match new_state:
		State.IDLE:
			animation_player.play(&"idle")
		State.SHOOT:
			# 添加保护，比如正在重装时不能射击
			if current_state == State.RELOAD:
				return
			animation_player.play(&"shoot")
			# 进入射击状态时，立即设置CD
			inshootcd = true
			baseshoot_cdtimer.start(baseshootCD)

		State.RELOAD:
			animation_player.play(&"reloadAmmo")
			reloading = true

	# 最后，更新当前状态变量
	current_state = new_state

# --- 以下是你的原始函数，已根据新的状态机进行微调 ---

func baseshoot():
	# 这个函数现在被 animation_player.play(&"shoot") 替代了
	# 为了保持兼容，我们可以保留它，但它现在只在_enter_state中被调用
	# 或者直接在_enter_state中播放动画。这里我们选择后者，此函数可以被视为已弃用。
	# 为了安全起见，我们让它什么都不做，因为逻辑已经移到 _enter_state 中
	pass

func _returnidle():
	# 统一通过状态转换函数返回idle
	_enter_state(State.IDLE)

func baseshootingline():
	# 预先检查并清理无效的敌人引用
	for i in range(enemy.size() - 1, -1, -1):
		if enemy[i] == null or not is_instance_valid(enemy[i]):
			enemy.remove_at(i)
	
	# 在射击前进行最终检查，虽然状态机已经保证了大部分情况
	var tempcount: int
	tempcount = min(bulletCount, enemy.size())
	
	if currentAmmo <= 0 and (not reloading):
		Eventmanger.reloadAmmo.emit()
		return
	if reloading or currentAmmo <= 0:
		return
		
	# 优化：原先的await会阻塞函数，改为为每条线创建一个独立的计时器来销毁
	for i in range(tempcount):
		var line = Line2D.new()
		line.width = 1
		# 确保敌人实例仍然有效
		if not is_instance_valid(enemy[i]):
			continue
		else:
			bulletCount -= 1
		var ends = enemy[i].global_position
		var start = shoot_point_mark.global_position
		line.points = [start, ends]
		get_tree().root.add_child(line)
		# 创建一个计时器来延时删除这条线，避免阻塞
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(line.queue_free)
		var damage = calculate_damage(enemy[i].armor)
		if enemy[i].has_method("getHurt"):
			enemy[i].getHurt(damage)
		Eventmanger.playerShooted.emit(enemy[i], ends, baseDamage)
		
	bulletCount = max(bulletCount, 1)
	#currentAmmo -= 1 ,用播放音效修改子弹数量
	Eventmanger.playershooting.emit(currentAmmo)


func lookAtEnemy():
	if not enemy.is_empty() and is_instance_valid(enemy[0]):
		var temp = enemy[0]
		if temp.global_position.x < self.global_position.x:
			bodys.scale.x = -1
			hand.scale.x = -0.5
		elif temp.global_position.x > self.global_position.x:
			bodys.scale.x = 1
			hand.scale.x = 0.5
			
		if hand.scale.x > 0:
			hand.look_at(temp.global_position)
		else:
			hand.rotation = hand.global_position.direction_to(temp.global_position).angle() + PI

func startshoot():
	# 外部调用此函数时，它会尝试进入射击状态
	if not enemy.is_empty():
		_enter_state(State.SHOOT)

func reloadAmmofunc():
	if get_tree().get_first_node_in_group(&"main").power > 0:
		get_tree().get_first_node_in_group(&"main").power -= 1
		_enter_state(State.RELOAD)
		AudioManager.play_sfx_at_position("Semi22LRReloadFullMP3", shoot_point_mark.global_position)
	else:
		_showTips("无法重新装弹")
		# 确保即使装弹失败也返回IDLE状态，以防万一
		_returnidle()
	
func reloadFinishfunc():
	reloading = false
	currentAmmo = MaxAmmo
	Eventmanger.FinishReloadAmmo.emit()
	Eventmanger.actionPointSub.emit()
	_returnidle()

func _on_baseshoot_c_dtimer_timeout() -> void:
	inshootcd = false

# 新的动画完成处理函数
func _on_animation_finished(anim_name: StringName):
	# 只在"shoot"动画完成时自动返回idle
	# "reloadAmmo"动画的结束逻辑由其最后一帧调用的 reloadFinishfunc() 处理
	# "idle"动画是循环的，通常不会触发这个（除非设置为不循环）
	if anim_name == &"shoot":
		_returnidle()

func _showTips(stext: String):
	var templabel = label.duplicate() as Label
	add_child.call_deferred(templabel)
	await templabel.tree_entered

	templabel.text = stext

	# 1. 获取参考点 (例如：原始 label 的中心)
	var reference_center_pos = label.global_position + (label.size / 2.0)

	# 2. 计算 templabel 的新 position
	# templabel.position 应该是参考点减去 templabel 自身尺寸的一半
	templabel.global_position = reference_center_pos - (templabel.size / 2.0)

	# --- 接下来是你的动画代码 ---
	templabel.pivot_offset = templabel.size / 2.0 # 缩放和旋转的中心
	templabel.modulate = Color(1, 1, 1, 1)
	templabel.scale = Vector2(0, 0)
	templabel.show()

	var newtween = get_tree().create_tween()

	newtween.tween_property(templabel, ^"scale", Vector2(1.6, 1.6), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	newtween.tween_property(templabel, ^"position", templabel.position - Vector2(0, 50), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	newtween.chain().tween_interval(0.7)
	newtween.chain().tween_property(templabel, ^"modulate", Color(1, 1, 1, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	newtween.tween_callback(templabel.queue_free)

func getHurt(damage: int):
	if is_hurt_invincible or is_parry_invincible:
		swordRot()
		if is_hurt_invincible:
			breakInvincibleCount += 1
			print("受击无敌中，剩余时间" + str(hurtInvincibleTimer.time_left - breakInvincibleCount))
			if breakInvincibleCount > int(hurtInvincibleTimer.time_left):
				is_hurt_invincible = false
				breakInvincibleCount = 0
				hurtInvincibleTimer.stop()
				return
		if is_parry_invincible:
			return
			###还未完成
		return
	health -= damage
	if health <= 0:
		Eventmanger.gameover.emit()
		return
	modulate = Color(1.0, 0.0, 0.0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1.0, 1.0, 1.0)
	hurtInvincibleTimer.start()
	is_hurt_invincible = true

func parryInvinclibleFunc():
	if is_parry_invincible or is_hurt_invincible:
		return
	else:
		parryInvincibleTimer.start()
		is_hurt_invincible = true


func gunshootingsounds():
	## 由于声音播放在子弹数量减一后调用，所以这里子弹=0也有射击声音
	if currentAmmo > 0:
		AudioManager.play_sfx_at_position("22LRSingleMP3", shoot_point_mark.global_position)
		currentAmmo -= 1
	elif get_tree().get_first_node_in_group(&'main').power <= 0:
		AudioManager.play_sfx_at_position("Semi22LRCantReloadMP3", shoot_point_mark.global_position)
		
	pass

func _bulletCountChangeFunc(count: int):
	bulletCount += count

func BaseShootCdSub():
	baseshootCD -= 0.1
	
func BaseDamageUp():
	attackBonus += 10 # 将原本对 baseDamage 的复杂计算改为直接增加 attackBonus

func TrueDamageUp():
	# 每次增加0.1的真实伤害系数.
	trueDamageRatio = trueDamageRatio + 0.3

func _on_eye_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		# 检查是否已经存在
		if not enemy.has(body):
			enemy.append(body)
	pass # Replace with function body.

func calculate_damage(enemy_armor: float = 0.0) -> float:
	# 基础伤害计算 
	var attack_bonus = float(attackBonus) / 100.0 # 整数百分比转小数
	var global_damage_bonus = float(globalDamageBonus) / 100.0
	var base_damage = baseDamage * (1.0 + attack_bonus) * (1.0 + global_damage_bonus)
	
	# 真实伤害计算 (修正:使用base_damage而不是baseDamage)
	var true_damage = base_damage * trueDamageRatio
	
	# 普通伤害计算(考虑护甲)
	var normal_damage = base_damage * (1.0 - clampf(enemy_armor, 0.0, 1.0))
	
	# 暴击判定和计算 (使用整数百分比)
	var is_crit = randf() < (float(criticalChance) / 100.0)
	var final_normal_damage = normal_damage
	if is_crit:
		final_normal_damage = normal_damage * (1.0 + float(criticalRatio) / 100.0)
	
	# 最终伤害 = 真实伤害 + 普通伤害(可能暴击)
	var final_damage = true_damage + final_normal_damage
	
	return final_damage
	# 使用示例:
	# var damage = calculate_damage(enemy.armor)


func _on_parry_invincible_timeout() -> void:
	is_parry_invincible = false
	pass # Replace with function body.


func _on_hurt_invincible_timeout() -> void:
	is_hurt_invincible = false
	breakInvincibleCount = 0
	pass # Replace with function body.

func _DrainDebuff():
	if drainDebuffLayers > 0:
		if randi() % 100 < (drainDebuffLayers * 5):
			get_tree().get_first_node_in_group(&"main").Correctcount -= 1
			drainDebuffLayers = int(drainDebuffLayers / 2.0)

func swordRot():
	var swordTemp = sword.duplicate()
	swordTemp.show()
	add_child.call_deferred(swordTemp)
	await swordTemp.tree_entered
	var tween = create_tween().set_parallel(true)
	tween.tween_property(swordTemp, "rotation", swordTemp.rotation + TAU, 0.5)
	tween.tween_property(swordTemp, "modulate", Color(1.0, 1.0, 1.0, 0.784), 0.5)
	tween.chain().tween_callback(swordTemp.queue_free)

func swordBreak():
	pass
