extends Sprite2D

@onready var buffExa = $buffExa
@onready var spawn_timer: Timer = $spawnTimer

var spawnWith :int = 15
var speed: int = 10
var buffArray :Array = []
signal buffDie

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer.timeout.connect(_spawnBuff)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in buffArray:
		i.position.y -= speed *delta
		if i.position.y <= -50:
			i.position.y = 10
		
	pass

func SetColor(col:Color):
	self.modulate = col
	
func SetLiveTimer(sec:float):
	get_tree().create_timer(sec).timeout.connect(func():
		queue_free()
		
		)

func _spawnBuff():
	if buffArray.size()<10:
		var temp : Node2D= buffExa.duplicate()
		temp.show()
		temp.position = Vector2(randf_range(-1*spawnWith,spawnWith),0)
		self.add_child(temp)
		buffArray.append(temp)
	else:
		spawn_timer.stop()
	pass

func _exit_tree() -> void:
	buffDie.emit()