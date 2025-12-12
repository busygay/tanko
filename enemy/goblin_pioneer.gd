extends "res://enemy/base_enemy.gd"

# 哥布林工兵的行为模式
enum GoblinMode {
	NORMAL, # 普通模式，只会攻击
	BUILDER # 建造者模式，会尝试建造图腾
}

# 哥布林工兵特有的变量
@onready var pioneer_effect: Node2D = $pioneer_effect if has_node("pioneer_effect") else null
var mode: GoblinMode = GoblinMode.NORMAL # 当前工兵的行为模式

# Build（献祭）相关变量
var is_building: bool = false  # 是否正在build（献祭）
var build_timer: Timer = null  # build计时器
var build_duration: float = 4.0  # build所需时间（默认4秒）两轮动画
var totem_scene: PackedScene = null  # 图腾场景引用
var min_level_for_build: int = 5  # 可触发build的最低等级（默认5级）
@export var builder_chance: float = 0.5 # 成为建造者模式的概率
@export var setPx: float = 150.0 # 必定触发建造的距离
@export var max_build_trigger_distance: float = 500.0 # 开始尝试触发建造的最大距离
var build_check_timer: Timer = null # 用于周期性检查是否建造的计时器

func _ready() -> void:
	baseDir = true  # 设置初始朝向为右
	super()
	# 设置哥布林工兵的属性
	speed = 65  # 中等速度，比基础敌人快一些
	attCd = 3   # 攻击冷却时间，平衡的攻击频率
	damage = 2  # 中等攻击力
	
	# 初始化build相关组件
	_init_build_components()

# 重写initData函数以调整哥布林工兵的基础属性
func initData(Mul:float):
	super(Mul)
	# 哥布林工兵的基础生命值调整
	var temp = Level.currentLevel
	health = int(temp/4.0)*2 + 8  # 稍微更高的基础生命值
	
	# 根据等级倍数调整属性
	if Mul > 1:
		var healthMul:float = Mul * 0.9  # 生命值倍率稍微降低，保持平衡
		var sizeMul:float = Mul * 0.8   # 体型倍率稍微降低
		var speedMul:float = 2.0 - Mul * 0.7  # 速度倍率调整，保持中等速度
		var damageMul:float = Mul * 0.9  # 伤害倍率稍微降低
		
		health = int(health * healthMul)
		self.scale = self.scale * sizeMul
		speed = int(speed * speedMul)
		damage = int(damage * damageMul)
	
	# 在出生时随机确定行为模式
	if randf() < builder_chance:
		self.mode = GoblinMode.BUILDER
	else:
		self.mode = GoblinMode.NORMAL
	
	# 确保移动速度在合理范围内
	if speed < 30:
		speed = 30
	if speed > 120:
		speed = 120

# 可以重写att函数以实现工兵特有的攻击方式
func att():
	if playerbox.is_empty():
		return
	var i = 0
	var temp = playerbox[i] as Node2D
	var maxcount = playerbox.size() - 1
	while not temp.has_method("getHurt"):
		i += 1
		if i > maxcount:
			return
		temp = playerbox[i]
	
	# 工兵攻击 - 造成标准伤害
	temp.getHurt(damage)
	
	# 可以在这里添加工兵特有的攻击效果
	# 例如：短暂降低玩家移动速度或攻击速度
	print("哥布林工兵攻击造成 ", damage, " 点伤害")

# 重写getHurt函数以处理build被打断的逻辑
func getHurt(_damage):
	# 如果在build过程中被攻击，打断build
	if is_building:
		print("哥布林工兵build被打断")
		is_building = false
		if build_timer and build_timer.is_stopped() == false:
			build_timer.stop()
	
	# 调用父类的getHurt函数处理伤害和状态转换
	super.getHurt(_damage)

# 重写_enter_state函数以处理工兵特有的状态逻辑
func _enter_state(new_state:state, _last_state:state = state.nothing):
	_last_state = currentState
	if new_state != currentState or (new_state == state.hurt and _last_state == state.hurt):
		currentState = new_state
		
		# 根据新状态和模式管理build检查计时器
		if mode == GoblinMode.BUILDER and new_state == state.walk:
			if build_check_timer and build_check_timer.is_stopped():
				build_check_timer.start()
		else:
			if build_check_timer and not build_check_timer.is_stopped():
				build_check_timer.stop()

		match currentState:
			state.idle:
				animation_player.play("idle")
			state.walk:
				animation_player.play("walk")
			state.att:
				animation_player.play("att")
				timer.start(attCd)
				# 在动画中途触发攻击伤害
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
			state.nothing:
				# 特殊状态，不播放动画
				pass

# 处理build状态（哥布林工兵特有）
func _enter_build_state():
	print("哥布林工兵进入build状态")
	animation_player.play("build")
	build_timer.start(build_duration)
	# 在build动画完成后继续build流程
	animation_player.animation_finished.connect(func(_animeName):
		# 动画播放完成，等待计时器完成
		pass
		, CONNECT_ONE_SHOT)

# 初始化build相关组件
func _init_build_components():
	# 创建build计时器
	build_timer = Timer.new()
	build_timer.wait_time = build_duration
	build_timer.one_shot = true
	build_timer.timeout.connect(_on_build_complete)
	add_child(build_timer)
	
	# 创建用于周期性检查建造的计时器
	build_check_timer = Timer.new()
	build_check_timer.wait_time = 1.0 # 每秒检查一次
	build_check_timer.timeout.connect(check_build_trigger_by_distance)
	add_child(build_check_timer)
	
	# 预加载图腾场景
	totem_scene = preload("res://globalSkillData/totem.tscn")
	print("哥布林工兵build组件初始化完成")

# 根据与玩家的距离检查是否触发build（仅用于建造者模式）
func check_build_trigger_by_distance():
	# 如果不是建造者模式、或正在建造、或等级不够、或玩家不在范围内，则不触发
	if mode != GoblinMode.BUILDER or is_building or Level.currentLevel < min_level_for_build or playerbox.is_empty():
		return

	# 获取玩家位置并计算距离
	var tempPlayer = get_tree().get_first_node_in_group(&"player")
	var distance_to_player = self.global_position.distance_to(tempPlayer.global_position)

	var should_build = false
	# 距离小于等于setPx，100%触发
	if distance_to_player <= setPx:
		should_build = true
		print("哥布林工兵（建造者）距离过近，强制触发build")
	# 在最大距离和最小距离之间，概率触发
	elif distance_to_player <= max_build_trigger_distance:
		# 距离越近，概率越高（线性插值）
		var probability = 1.0 - (distance_to_player - setPx) / (max_build_trigger_distance - setPx)
		if randf() < probability:
			should_build = true
			print("哥布林工兵（建造者）概率触发build，距离: ", int(distance_to_player), " 概率: ", round(probability * 100), "%")

	if should_build:
		start_build()


# 开始build流程
func start_build():
	is_building = true
	# 切换到idle状态以停止移动，然后播放build动画
	_enter_state(state.idle)
	print("哥布林工兵开始build，持续时间：", build_duration, "秒")
	_enter_build_state()

# build完成时的回调
func _on_build_complete():
	if not is_building:
		return
	
	print("哥布林工兵build完成，生成图腾")
	
	# 在当前位置生成图腾
	if totem_scene:
		var totem = totem_scene.instantiate()
		if totem:
			totem.global_position = self.global_position
			get_tree().current_scene.add_child(totem)
			print("成功生成图腾在位置：", self.global_position)
	
	# build完成后工兵死亡
	is_building = false
	# 确保计时器停止
	if build_timer and build_timer.is_stopped() == false:
		build_timer.stop()
	
	# 延迟一帧后死亡，确保所有清理工作完成
	await get_tree().process_frame
	_enter_state(state.death)
