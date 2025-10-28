extends "res://enemy/base_enemy.gd"
@onready var death: Node2D = $death

var idleTween:Tween

func _ready() -> void:

	super()
	attCd = 1
	death.hide()
	baseDir= true
	if player.position.x - self.position.x <0:
		death.scale = Vector2(-1,1)


func idleAnime():
	if idleTween and idleTween.is_valid():
		idleTween.kill()
		
	idleTween =get_tree().create_tween()
	idleTween.set_loops()
	idleTween.bind_node(self)
	var scaleOne:Vector2 = baseScale * Vector2(1.05,0.95)
	var scaleTw0:Vector2 = baseScale * Vector2(0.95,1.105)
	idleTween.tween_property(self,^"scale",scaleOne,0.3)
	idleTween.tween_property(self,^"scale",scaleTw0,0.3)
	
func resetScale():
	if idleTween:
		idleTween.kill()
		idleTween =get_tree().create_tween()
		idleTween.tween_property(self,^"scale",baseScale,0.1)
	
func _enter_state(new_state:state,_last_state:state = state.nothing):
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
		match _last_state:
			state.idle:
				resetScale()
