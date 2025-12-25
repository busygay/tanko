extends Node3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var skeleton_3d: Skeleton3D = $Armature_002/Skeleton3D
const HIDE_MATERIAL = preload("uid://ccpqnk0k6rdya")

signal attackHit 
signal jumpAttFall

func onCharacterAttackHit():
	attackHit.emit()

func JumpAttFallEmit():
	jumpAttFall.emit()
