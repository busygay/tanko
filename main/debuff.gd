extends Sprite2D

@onready var spawn_timer: Timer = $spawnTimer

@onready var debuff_exa: Node2D = $debuffExa

var debuffArray:Array = []

var speed :int = 30

var spawnWith : int = 15
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer.timeout.connect(_SpawnDebuff)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in debuffArray:
		i.position.y += speed*delta
		if i.position.y >= 10:
			i.position.y = -45

	pass


func _SpawnDebuff():
	if debuffArray.size()<=10:
		var temp = debuff_exa.duplicate()
		self.add_child(temp)
		temp.position = Vector2(randf_range(-1*spawnWith,spawnWith),-45)
		debuffArray.append(temp)
	else:
		spawn_timer.stop()
func SetColor(col:Color):
	self.modulate = col


func SetLiveTime(sec:float):
	get_tree().create_timer(sec).timeout.connect(
		func():
			queue_free()

	)
