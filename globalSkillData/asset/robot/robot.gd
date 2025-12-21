extends Node3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

signal attackHit 

func onCharacterAttackHit():
	attackHit.emit()


func deathAnim():
	mesh_instance_3d.show()
	pass
	
