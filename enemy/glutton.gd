extends "res://enemy/base_enemy.gd"

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
# 暴食者特有属性
var accumulatedDamage: int = 0  # 累计受到的伤害
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


func initData(Mul: float):
	# 根据等级进一步调整属性
	var temp = Level.currentLevel
	health =min(1, int(temp / 3.0))
	var tempRandf:float = randf_range(0.8,1.2)
	speed = int ( speed *tempRandf)
	
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
				animation_player.animation_finished.connect(func(_animeName):
					die()
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

func die():
	animated_sprite_2d.hide()
	gpu_particles_2d.restart()

	await gpu_particles_2d.finished
	super()


func getHurt(_damage: int):
	# 累计受到伤害
	accumulatedDamage += _damage	

	health -= 1
	if health <= 0:
		_enter_state(state.death)
	else:
		_enter_state(state.hurt)

func BoomColorStart(_type = 1):
	if _type ==1:
		#红色
		animated_sprite_2d.modulate = Color(1.0, 0.0, 0.0, 1.0)
		_type = 0
	else:
		#白色
		animated_sprite_2d.modulate= Color(1.0, 1.0, 1.0, 0.6)
		_type =1
	await get_tree().create_timer(0.1).timeout
	
	BoomColorStart(_type)
