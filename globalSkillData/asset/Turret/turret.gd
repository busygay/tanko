extends Node3D
@onready var swivel: MeshInstance3D = $Swivel
@onready var marker_3d: Marker3D = $Swivel/Marker3D
@onready var camera_3d: Camera3D = $'../Camera3D'
@onready var swivels: MeshInstance3D = $Swivel

var targetPos:Vector2


func _process(_delta: float) -> void:
	if targetPos !=null:
		var dir:Vector2 =Vector2(swivels.global_position.x - targetPos.x,swivels.global_position.z-targetPos.y) 
		var targetAngle = atan2(dir.x,dir.y)
		swivels.rotation.y= targetAngle
	
func putMarkerPos():
	var temp =marker_3d.global_position
	return temp

func _setTargetPos(_pos):
	targetPos=_pos
