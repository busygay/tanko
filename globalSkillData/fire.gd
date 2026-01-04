extends Node2D

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var baseRatio = 0.8
var upRatio = 1.0

var tween: Tween
var player_node: players
var is_active = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取玩家引用
	player_node = get_tree().get_first_node_in_group("player")
	
	# 初始化粒子ratio为0，然后tween到baseRatio
	gpu_particles_2d.amount_ratio = 0.0
	
	tween = create_tween()
	tween.tween_property(gpu_particles_2d, "amount_ratio", baseRatio, 0.3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	is_active = false
	queue_free()
	pass # Replace with function body.


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	
	# 检查是否是敌人
	if body.is_in_group("enemy"):
		# 将粒子ratio设置到upRatio
		if tween and tween.is_valid():
			tween.kill()
		gpu_particles_2d.amount_ratio = upRatio
		
		# 对敌人造成伤害（玩家伤害的0.5倍）
		if player_node and body.has_method("getHurt"):
			var damage = player_node.calculate_damage(body.armor) * 0.5
			body.getHurt(damage)
		
		# 0.5秒后恢复到baseRatio
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_active:
				if tween and tween.is_valid():
					tween.kill()
				tween = create_tween()
				tween.tween_property(gpu_particles_2d, "amount_ratio", baseRatio, 0.3)
		)


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
