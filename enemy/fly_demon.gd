extends "res://enemy/base_enemy.gd"
const fireBall:PackedScene = preload('uid://bvagk68wcdq0f')
@onready var marker_2d: Marker2D = $AnimatedSprite2D/Marker2D
@onready var collision_shape_2d: CollisionShape2D = $eye/CollisionShape2D

func _ready() -> void:
	super()
	var tempshape = collision_shape_2d.shape.duplicate() as CircleShape2D
	tempshape.radius = randf_range(400,550 ) /  abs (self.scale.x)
	collision_shape_2d.shape = tempshape
	baseDir = false

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
	fireBallShoot(temp)
	
func fireBallShoot(_target):
	var temp = fireBall.instantiate()
	temp.initData(_target,marker_2d.global_position,1)
	get_tree().root.add_child(temp)
