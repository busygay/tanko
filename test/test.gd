extends Node2D
const TURRET = preload('uid://d1t5wfugr4e7j')
@onready var marker_2d: Marker2D = $Marker2D
@onready var character_body_2d: CharacterBody2D = $CharacterBody2D

func _ready() -> void:
	spwan()
	pass
	
func _process(delta: float) -> void:
	character_body_2d.global_position = get_global_mouse_position()
func spwan():
	var temp = TURRET.instantiate()
	temp._setData(10,1,marker_2d.global_position,PI/2,300)
	add_child(temp)
