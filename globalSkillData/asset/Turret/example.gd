extends Line2D

var damage:float
var speed =3000
@onready var marker_2d: Marker2D = $'../Marker2D'
@onready var att_area_2d: Area2D = $attArea2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:

	global_position += speed *delta * Vector2.from_angle(rotation)
	
func _setdata(_damage:float,pos:Vector2,rot:float):
	damage = _damage
	global_position = pos
	global_rotation = rot *-1
	att_area_2d.monitorable = true
	att_area_2d.monitoring = true
	

func _on_att_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.getHurt(damage)
	pass # Replace with function body.
