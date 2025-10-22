extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $damageArea

@export var speed:int
var damage:int
enum state{
	idle,
	att,
	nothing,
}
var target
var targetPos
var targetDir
var Group
var currentState = state.nothing
func _ready() -> void:
	
	enterState(state.idle)
	
func _physics_process(_delta: float) -> void:
	match currentState:
		state.idle:
			_state_logic_idle(_delta)
		state.att:
			pass
			
func enterState(newState:state,_lastState:state=state.nothing):
	if newState != currentState:
		currentState = newState
	match currentState:
		state.idle:
			animated_sprite_2d.play(&'idle')
			var tween = get_tree().create_tween()
			tween.tween_property(self,"scale",Vector2(1.0,1.0),0.2)
		state.att:
			animated_sprite_2d.play(&'att')
			var temp:Array
			temp =damage_area.get_overlapping_bodies()
			for i in temp:
				if i.is_in_group(Group) and i.has_method("getHurt"):
					i.getHurt(damage)
					
			animated_sprite_2d.animation_finished.connect(func():
				self.hide()
				queue_free()
				,CONNECT_ONE_SHOT)
				
func initData(_target,selfpos:Vector2,_speed:int,_damage:int):
	self.position = selfpos
	target=_target
	speed = _speed
	damage = _damage
	if _target.is_in_group("player"):
		Group = "player"
		pass
	elif _target.is_in_group("enemy"):
		Group = "enemy"
		pass
	
	targetPos = _target.position
	targetDir = self.position.direction_to(targetPos)
	self.look_at(targetPos)
	
func _state_logic_idle(_delta):
	if targetPos != null:
		position += targetDir * speed *_delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Group):
		enterState(state.att)
	pass # Replace with function body.
