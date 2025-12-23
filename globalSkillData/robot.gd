extends Node2D

# 机器人状态枚举 (对齐 base_enemy.gd)
enum state { spawn, idle, walk, att, jumpAtt, death}

@export var lightningScene: PackedScene # 雷电链效果场景 (camelCase)

const EMP_SCENE = preload("res://globalSkillData/EMP.tscn")

@onready var robot: Node3D = $SubViewportContainer/SubViewport/Node3D/robot
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/Node3D/Camera3D
@onready var attArea2D: Area2D = $attArea2D
@onready var liveTimer: Timer = $liveTimer
@onready var attTimer: Timer = $attTimer
@onready var animationPlayer: AnimationPlayer

# 基础属性 (camelCase)

var speed: float = 100.0 

var rotationSpeed: float = 10.0

var liveTime: float = 15.0 

var damage: float = 10.0 

var targetEnemy: Node2D = null 

var hasPulse: bool = false 

var currentState: state = state.idle
var death_flag: bool = false # 死亡标志位

var master :Node2D #用于获取父级 BT-7271


# 常量定义

const ATT_RANGE = 100.0 

const ATT_CD = 1.0 

const PULSE_RADIUS = 200.0 

const THUNDER_MARK_DURATION = 5.0 

const THUNDER_MARK_SLOW = 0.3 

const THUNDER_MARK_DAMAGE_BONUS = 0.25 



# 初始化机器人

func _ready() -> void:

	getRobotAimationPlayer()

	_setup_timers()

	_enter_state(state.spawn)  # 从 spawn 状态开始

	

	if hasPulse:

		call_deferred("_trigger_pulse")

	robot.attackHit.connect(func():
		_execute_att()
		)

func getRobotAimationPlayer():

	animationPlayer = robot.get_node("AnimationPlayer")

	



# 设置机器人数据,由BT-7271调用

func initData(_dic:Dictionary,_master:Node2D):

	if "fiveCombo" in _dic or "APSpent" in _dic:
		speed = 125

	damage = _calculate_damage()
	master = _master
	_setup_timers()



# 计算基于玩家攻击力的伤害值

func _calculate_damage() -> float:

	var player = get_tree().get_first_node_in_group(&"player")

	if player and player.has_method(&"calculate_damage"):

		return player.calculate_damage(0.0)*0.5

	return 10.0



# 设置计时器

func _setup_timers():

	if liveTimer:

		liveTimer.wait_time = liveTime

		# 不在这里启动 liveTimer，等待 spawn 状态结束后启动

	if attTimer:

		attTimer.wait_time = ATT_CD

		attTimer.one_shot = true



# 物理帧处理

func _physics_process(delta: float) -> void:

	robotRotation(delta)

	match currentState:

		state.spawn:
			# spawn 状态不需要物理逻辑处理
			pass

		state.idle:

			_state_logic_idle()

		state.walk:

			_state_logic_walk(delta)

		state.att, state.jumpAtt:

			pass



# --- 状态逻辑处理 (对齐 base_enemy.gd 风格) ---



func _state_logic_idle():

	_update_target()

	if is_instance_valid(targetEnemy):

		_enter_state(state.walk)



func _state_logic_walk(delta: float):

	_update_target()

	if not is_instance_valid(targetEnemy):

		_enter_state(state.idle)

		return

	var distance = global_position.distance_to(targetEnemy.global_position)

	if distance <= ATT_RANGE:

		if attTimer.is_stopped():

			_enter_state(state.att)

		else:

			_enter_state(state.idle)

	else:

		var direction = global_position.direction_to(targetEnemy.global_position)

		global_position += direction * speed * delta



# 更新目标敌人

func _update_target():

	if is_instance_valid(targetEnemy):

		var dist = global_position.distance_to(targetEnemy.global_position)

		if dist <= ATT_RANGE * 1.2:

			return



	var enemies = get_tree().get_nodes_in_group(&"enemy")

	var min_dist = INF

	targetEnemy = null

	

	for enemy in enemies:

		if not is_instance_valid(enemy): continue

		# 跳过拥有雷霆标记的敌人

		if _has_thunder_mark(enemy): continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist < min_dist:

			min_dist = dist

			targetEnemy = enemy



# --- 状态转换处理 ---



func _enter_state(new_state: state):

	if currentState == new_state and new_state != state.att:

		return

	currentState = new_state

	match currentState:

		state.spawn:
			_play_anim(&"self/spawn")
			# spawn 动画结束后启动 liveTimer 并进入 idle 状态
			if animationPlayer and animationPlayer.has_animation(&"self/spawn"):
				animationPlayer.animation_finished.connect(_on_spawn_animation_finished, CONNECT_ONE_SHOT)
			else:
				# 如果没有 spawn 动画，直接进入 idle 状态并启动 timer
				_on_spawn_animation_finished()

		state.idle:
			_play_anim(&"walk")
			# 检查死亡标志位
			_check_death_flag()

		state.walk:
			_play_anim(&"walk")
			# 检查死亡标志位
			_check_death_flag()

		state.att:
			_play_anim(&"att")
			# 使用 CONNECT_ONE_SHOT 处理动画完成逻辑 (对齐 base_enemy.gd)
			if animationPlayer and animationPlayer.has_animation(&"att"):
				animationPlayer.animation_finished.connect(func(_a): _enter_state(state.idle), CONNECT_ONE_SHOT)
			else:
				_enter_state(state.idle)

		state.jumpAtt:
			_play_anim(&"jumpAtt")
			# 创建 emp 场景
			_spawn_emp()
			if animationPlayer and animationPlayer.has_animation(&"jumpAtt"):
				animationPlayer.animation_finished.connect(func(_a): _enter_state(state.idle), CONNECT_ONE_SHOT)

		state.death:
			_play_anim(&"self/death")
			# 机器人死亡后直接移除
			if animationPlayer and animationPlayer.has_animation(&"death"):
				animationPlayer.animation_finished.connect(func(_a): queue_free(), CONNECT_ONE_SHOT)
			else:
				queue_free()


# 辅助播放动画

func _play_anim(anim_name: StringName):

	if animationPlayer and animationPlayer.has_animation(anim_name):

		animationPlayer.play(anim_name)

	else:

		push_warning("Robot: AnimationPlayer missing or animation not found: %s" % anim_name)


# spawn 动画结束后的回调函数

func _on_spawn_animation_finished() -> void:
	# 启动 liveTimer
	if liveTimer:
		liveTimer.start()
	# 进入 idle 状态
	_enter_state(state.idle)



# --- 业务逻辑 ---



func _execute_att():

	if not is_instance_valid(targetEnemy):

		return

	

	# 调用对齐 base_enemy 的 getHurt

	if targetEnemy.has_method(&"getHurt"):

		targetEnemy.getHurt(damage)

	

	_apply_thunder_mark(targetEnemy)

	attTimer.start()



# 施加雷霆标记

func _apply_thunder_mark(enemy: Node2D):
	
	master.call_deferred("AddToLightningBuffManger", enemy)




# 触发雷霆脉冲

func _trigger_pulse():

	_enter_state(state.jumpAtt)


# 创建 emp 场景
func _spawn_emp():
	var emp_instance = EMP_SCENE.instantiate()
	if emp_instance.has_method("set_master"):
		emp_instance.set_master(master)
	get_parent().add_child(emp_instance)
	emp_instance.global_position = global_position






# 检查敌人是否有雷霆标记

func _has_thunder_mark(enemy: Node2D) -> bool:

	if master and is_instance_valid(master) and enemy in master.lightningBuffManger:

		return true

	return false




# 生存时间结束回调
func _on_live_timer_timeout() -> void:
	# 如果当前处于 idle 或 walk 状态，可以直接进入死亡状态
	if currentState == state.idle or currentState == state.walk:
		_enter_state(state.death)
	else:
		# 如果处于其他状态（spawn、att、jumpAtt），设置死亡标志位等待状态结束
		death_flag = true




# 机器人旋转瞄准逻辑 (基于 2D 到 3D 投射)

func robotRotation(delta: float) -> void:
	if not is_instance_valid(targetEnemy):
		return
		
	var swivelPos = self.global_position
	var targetDir = (targetEnemy.global_position - swivelPos)
	var targetAngle = targetDir.angle() * -1
	
	robot.rotation.y = lerp_angle(robot.rotation.y, targetAngle+PI/2.0, rotationSpeed * delta)


# 检查死亡标志位
func _check_death_flag() -> void:
	if death_flag:
		death_flag = false
		_enter_state(state.death)
