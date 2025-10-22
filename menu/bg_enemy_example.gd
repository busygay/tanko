extends AnimatedSprite2D
var isStartMove:bool=false
var speed = 100
var dir
@onready var bg_player: Node2D


func _ready() -> void:
	speed = randi_range(50,80)
	if bg_player !=null:
		var temp = randi_range(-200,+200)
		if randi()%2:
			var newPos:Vector2= Vector2(position.x+temp,position.y)
			position = newPos
		else:
			var newPos:Vector2= Vector2(position.x,position.y+temp)
			position = newPos
		dir =global_position.direction_to(bg_player.global_position)
	
func _process(delta: float) -> void:
	if isStartMove:
		global_position+= dir *speed*delta
func startMove(_player):
	bg_player = _player
	isStartMove = true
	
