extends Sprite2D

# 加速Buff属性
@export var speed_multiplier: float = 1.5  # 速度倍数
@export var duration: float = 5.0  # 持续时间（秒）
@export var buff_color: Color = Color.GREEN  # Buff视觉效果颜色

@onready var buffExa = $buffExa
@onready var spawn_timer: Timer = $spawnTimer
@onready var lifetime_timer: Timer = $lifetimeTimer

var spawnWith: int = 15
var speed: int = 20
var buffArray: Array = []
signal buffDie
signal buffApplied
signal buffRemoved

# 当前Buff实例
var currentBuffInstance = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer.timeout.connect(_spawnBuff)
	# 设置生命周期定时器
	lifetime_timer.wait_time = duration
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	# 设置Buff颜色
	SetColor(buff_color)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in buffArray:
		i.position.y -= speed * delta
		if i.position.y <= -50:
			i.position.y = 10
	pass

# 应用Buff到目标
func applyBuff(target) -> bool:
	if not is_instance_valid(target):
		return false
	
	# 检查目标是否有Buff系统支持
	if not target.has_method("apply_buff"):
		push_warning("目标不支持Buff系统:", target.name)
		return false
	
	# 创建Buff实例数据
	var buffInstance = {
		"type": "speed",
		"multiplier": speed_multiplier,
		"duration": duration,
		"source": self
	}
	
	currentBuffInstance = buffInstance
	target.apply_buff(buffInstance)
	buffApplied.emit(buffInstance)
	
	# 隐藏视觉元素，但保持逻辑存在
	self.hide()
	return true

# Buff生命周期结束
func _on_lifetime_timeout() -> void:
	if currentBuffInstance and is_instance_valid(currentBuffInstance.get("source", null)):
		# 通知目标移除Buff
		var target = get_tree().get_first_node_in_group("enemy")
		if target and target.has_method("remove_buff"):
			target.remove_buff(currentBuffInstance)
	
	buffRemoved.emit(currentBuffInstance)
	queue_free()

func SetColor(col: Color):
	self.modulate = col
	
func SetLiveTimer(sec: float):
	get_tree().create_timer(sec).timeout.connect(func():
		queue_free()
	)

func _spawnBuff():
	if buffArray.size() < 10:
		var temp: Node2D = buffExa.duplicate()
		temp.show()
		temp.position = Vector2(randf_range(-1 * spawnWith, spawnWith), 0)
		self.add_child(temp)
		buffArray.append(temp)
	else:
		spawn_timer.stop()
	pass

func _exit_tree() -> void:
	buffDie.emit()