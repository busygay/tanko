extends Node2D


@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var eye: Area2D = $eye
@onready var marker_2d: Marker2D = $Marker2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D



###3D模型部分
@onready var turret: Node3D = $SubViewportContainer/SubViewport/Node3D/Turret
@onready var swivels: MeshInstance3D = $SubViewportContainer/SubViewport/Node3D/Turret/Swivel
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/Node3D/Camera3D
@onready var marker_3d: Marker3D = $SubViewportContainer/SubViewport/Node3D/Turret/Swivel/Marker3D
@onready var pos: Node3D = $SubViewportContainer/SubViewport/Node3D/Turret/Swivel/pos
@onready var spawn: AnimationPlayer = $SubViewportContainer/SubViewport/Node3D/spawn

var gPosition:Vector2

const example = preload('uid://c4877mqotbwnh')
var health
var damage:float
var targetArray:Array
var attCd:float = 0.15
var shootReloading:bool = false
var shootCount:int =4
var soundsPlaying:bool =false
var rotationSpeed:float 
enum state{
	spawn,
	idle,
	aim,
	att,
	die,
	broken,
	nothing,
	
}
var currentState=state.nothing
var swivelPos:Vector2

func _ready() -> void:
	enterState(state.spawn)
	await get_tree().process_frame
	$Timer.start()
func _process(delta: float) -> void:
	var tempPos = sub_viewport_container.global_position+camera_3d.unproject_position(marker_3d.global_position)*scale
	marker_2d.global_position = tempPos
	swivelPos = sub_viewport_container.global_position+camera_3d.unproject_position(pos.global_position)*scale
	gpu_particles_2d.global_position = marker_2d.global_position
	gpu_particles_2d.global_rotation = swivels.rotation.y*-1
	eye.global_position = marker_2d.global_position
	eye.rotation = -swivels.rotation.y
	match currentState:
		state.idle:
			state_logic_idle(delta)
		state.aim:
			state_logic_aim()
		state.att:
			state_logic_att()

func state_logic_spawn():
	pass
func state_logic_idle(delta):
	if not targetArray.is_empty():
		enterState(state.aim)
	swivels.rotation.y -=rotationSpeed*delta
	swivels.rotation.y =wrapf(swivels.rotation.y,-PI,PI)
	
	if not targetArray.is_empty():
		enterState(state.aim)
		
func state_logic_aim():
	if targetArray.is_empty():
		enterState(state.idle)
		return
	var target = targetArray[0]
	
	var targetDir = (target.global_position-swivelPos)
	var targetAngle =targetDir.angle()*-1
	
	swivels.rotation.y = lerp_angle(swivels.rotation.y,targetAngle,0.02)
	swivels.rotation.y = wrapf(swivels.rotation.y,-PI,PI)
	var angleDif = angle_difference(targetAngle,swivels.rotation.y)
	if abs(angleDif)  <= PI/20:
		enterState(state.att)

func state_logic_att():
	if targetArray.is_empty():
		enterState(state.idle)
		return

	
	if shootCount >0:
		if soundsPlaying:
			pass
		else:
			AudioManager.play_sfx_at_position("762x54rSprayIsolatedMP3",marker_2d.global_position,0.5)
			soundsPlaying = true
			shooting()
	elif not shootReloading:
		shootReloading = true
		get_tree().create_timer(0.5).timeout.connect(func():
			shootCount = 4
			soundsPlaying = false
			shootReloading = false
			,CONNECT_ONE_SHOT)
	var target = targetArray[0]
	
	var targetDir = (target.global_position-swivelPos)
	var targetAngle =targetDir.angle()*-1
	swivels.rotation.y = lerp_angle(swivels.rotation.y,targetAngle,0.02)
	swivels.rotation.y = wrapf(swivels.rotation.y,-PI,PI)

func shooting():
	shootCount -=1
	var temp = example.instantiate()
	var rand:Vector2 =Vector2( randf_range(-10,+10),randf_range(-10,+10))
	var shockScale = Vector3(randf_range(0.95,1.05),randf_range(0.95,1.05),randf_range(0.95,1.05))
	turret.scale = shockScale
	#get_tree().get_first_node_in_group("main").add_child(temp)
	get_parent().add_child(temp)
	temp._setdata(damage,marker_2d.global_position+rand,swivels.rotation.y)
	temp.show()
	gpu_particles_2d.emitting =true
	if shootCount >0:
		get_tree().create_timer(attCd).timeout.connect(shooting.bind())

	
func enterState(newState:state):
	var _lastState = currentState
	if newState != currentState:
		currentState = newState
		match currentState:
			state.spawn:
				$SubViewportContainer/SubViewport/Node3D/spawnNode3d.show()
				var tween = get_tree().create_tween()
				tween.tween_property(self,"global_position",gPosition,0.3)
				tween.finished.connect(func():
					spawn.play(&'spawn')
					spawn.animation_finished.connect(func(_nothing):
						enterState(state.idle)
						)
					)
			state.idle:
				turret.scale = Vector3.ONE
				gpu_particles_2d.emitting = false
				pass
			state.aim:
				turret.scale = Vector3.ONE
				gpu_particles_2d.emitting = false
			state.att:
				pass
			state.die:
				queue_free()
			state.broken:
				queue_free()

func _setData(_health:int,_damage:float,_pos:Vector2,_rotSpeed:float,liveTime:float):
	health = _health
	damage =_damage
	gPosition = _pos
	var tempPos = _pos-Vector2(300,300)
	global_position = tempPos
	rotationSpeed = _rotSpeed
	$Timer.wait_time = liveTime
	



func _on_eye_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		targetArray.append(body)
	pass # Replace with function body.



func _on_eye_body_exited(body: Node2D) -> void:
	if targetArray.has(body):
		targetArray.erase(body)
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	enterState(state.die)
	pass # Replace with function body.
