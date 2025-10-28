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
var baseDir:bool = true #true为朝右，false为朝左
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
	if direction.x != 0:
		var targetDir = direction.x >0
		var flip_multiplier = 1 - 2 * int(targetDir != baseDir)
		#self.scale.x = flip_multiplier
		animated_sprite_2d.scale.x = flip_multiplier
		#animated_sprite_2d.flip_h = (targetDir != baseDir)
		
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
