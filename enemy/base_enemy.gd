class_name baseEnemy extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $eye
@onready var timer: Timer = $Timer


var armor:float = 0.0
var speed:int = 50
var baseScale:Vector2
var attCd:int = 10
var damage:int =1
var health:int
var player
var playerbox:Array
var currentFacingDir:bool = true # 当前面朝的方向，避免频繁翻转
var baseDir :bool  # 初始面朝的方向，true为右，false为左
enum state{
	idle,
	walk,
	att,
	hurt,
	death,
	nothing,
	
}
var currentState=state.idle

func _ready() -> void:
	Eventmanger.enterTreeEnemy.emit()
	# 获取玩家引用
	baseScale = self.scale
	player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		push_error("找不到player节点，敌人将无法行动！")
		set_physics_process(false) # 禁用 _physics_process
		return
	
	# 根据敌人相对玩家的初始位置设置朝向
	var initialDirection = global_position.direction_to(player.global_position)
	var targetDir = initialDirection.x > 0
	if baseDir != true:
		currentFacingDir = targetDir
		if currentFacingDir:
			# 初始朝右
			scale.x = -baseScale.x
		else:
			# 初始朝左
			scale.x = baseScale.x
	else:
		currentFacingDir = targetDir
		if currentFacingDir:
			# 初始朝右
			scale.x = baseScale.x
		else:
			# 初始朝左
			scale.x = -baseScale.x
	_enter_state(state.walk)

func initData(Mul:float):
	var temp = Level.currentLevel
	health = int( temp/5.0)*2+5
	var tempRandf:float = randf_range(0.8,1.2)
	speed = int ( speed *tempRandf)
	
	
	if Mul >1:
		var healthMul:float = Mul
		var sizeMul:float = Mul
		var speedMul:float = 2.0-Mul
		var damageMul:float = Mul
		health = int( health*healthMul)
		self.scale = self.scale *sizeMul
		speed = int (speed *speedMul)
		damage = int (damage*damageMul)
	
	# 限制最小移动速度
	if speed < 25:
		speed = 25
	
func _physics_process(_delta: float) -> void:
	match currentState:
		state.idle:
			_state_logic_idle()
		state.walk:
			_state_logic_walk()
		state.att:
			_state_logic_att()
		state.hurt:
			return
			
func _state_logic_walk():
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	#确保 图像纹理朝向已经被设置
	if baseDir == null :
		return
	if direction.x != 0:
		var targetDir = direction.x >0 #大于0朝右，小于0朝左
		# 只有当朝向真正改变时才翻转
		if targetDir != currentFacingDir: 
			currentFacingDir = targetDir 
			# 简化逻辑：直接根据目标朝向设置缩放
			if targetDir:
				# 目标朝右
				scale.x = baseScale.x
			else:
				# 目标朝左
				scale.x = -baseScale.x

	if not playerbox.is_empty():
		_enter_state(state.att,)
		
func _enter_state(new_state:state,):
	var  _last_state = currentState
	if new_state != currentState or (new_state ==state.hurt and _last_state == state.hurt):
		currentState = new_state
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
					,CONNECT_ONE_SHOT)
			state.hurt:
				animation_player.play("hurt")
				animation_player.animation_finished.connect(func(_animeName):
					if _last_state != state.nothing:
						_enter_state(_last_state)
					,CONNECT_ONE_SHOT)
			state.death:
				animation_player.play("death")
				animation_player.animation_finished.connect(func(_animeName):
					die()
					,CONNECT_ONE_SHOT)
			
				
func _state_logic_att():
	velocity = Vector2.ZERO
	move_and_slide()
	pass
	
func _state_logic_idle():
	velocity = Vector2.ZERO
	move_and_slide()
	
func _on_timer_timeout() -> void:
	if currentState == state.idle and (not playerbox.is_empty()):
		_enter_state(state.att)

#通常通过animationplayer调用，对于攻击动画简单的也可以直接在状态机调用。
func att():
	if playerbox.is_empty():
		return
	var i =0
	var temp  = playerbox[i] as Node2D
	var maxcount = playerbox.size()-1
	while not  temp.has_method("getHurt"):
		i +=1
		if i >maxcount:
			return
		temp = playerbox[i]
	temp.getHurt(damage)

	


func getHurt(_damage):
	health -= _damage
	if health <= 0:
		_enter_state(state.death)
	else:
		_enter_state(state.hurt)

func die():
	self.hide()
	queue_free()
	
func _on_eye_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerbox.append(body)
	pass # Replace with function body.

func _exit_tree() -> void:
	Eventmanger.exitTreeEnemy.emit()
	Eventmanger.enemydeath.emit(self)
