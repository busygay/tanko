extends "res://enemy/base_enemy.gd"
@onready var death: Node2D = $death

var idleTween: Tween

func _ready() -> void:
	baseDir = true
	super ()
	attCd = 1
	death.hide()


func idleAnime():
	if idleTween and idleTween.is_valid():
		idleTween.kill()
		
	idleTween = get_tree().create_tween()
	idleTween.set_loops()
	idleTween.bind_node(self)
	
	# 获取当前 scale 的符号，确保目标 scale 与当前符号一致
	# 避免 Godot 将 (-x, +y) 自动转换为 (+x, -y) + rotation 180°
	var sign_x = sign(scale.x)
	var sign_y = sign(scale.y)
	
	var scaleOne: Vector2 = baseScale * Vector2(1.05, 0.95)
	scaleOne.x *= sign_x
	scaleOne.y *= sign_y
	var scaleTw0: Vector2 = baseScale * Vector2(0.95, 1.105)
	scaleTw0.x *= sign_x
	scaleTw0.y *= sign_y
	
	idleTween.tween_property(self, ^"scale", scaleOne, 0.3)
	idleTween.tween_property(self, ^"scale", scaleTw0, 0.3)
	
func resetScale():
	if idleTween:
		idleTween.kill()
		idleTween = get_tree().create_tween()
		
		# 用当前 scale 的符号来确保目标值与当前符号一致
		var targetScale = baseScale
		targetScale.x *= sign(scale.x)
		targetScale.y *= sign(scale.y)
			
		idleTween.tween_property(self, ^"scale", targetScale, 0.1)
	
func _enter_state(new_state: state, _last_state: state = state.nothing):
	_last_state = currentState
	if new_state != currentState:
		currentState = new_state
		match currentState:
			state.idle:
				animation_player.play("idle")
				idleAnime()
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
		match _last_state:
			state.idle:
				pass
				resetScale()
