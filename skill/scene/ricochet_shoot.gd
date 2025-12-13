extends "res://skill/scene/skill.gd"

var baseRicochet: int = 1
var upgrade_count: int = 0 # 记录升级次数
var lock: bool = true
var player: players
var ricochetBonus: int = 0
func _ready() -> void:
	super ()
	Eventmanger.playerShooted.connect(ricoChet)
	Eventmanger.ricochetShootUp.connect(_on_ricochet_shoot_up)
	player = get_tree().get_first_node_in_group("player")

func _on_ricochet_shoot_up():
	ricochetBonus += 1
	upgrade_count += 1

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	if _dic.has("fiveCombo"):
		baseRicochet = 5
		lock = false
	else:
		baseRicochet = 1
		lock = false
func ricoChet(enemy, pos: Vector2, baseDamage: float):
	if lock:
		return
	else:
		lock = true
		var line
		var start
		var selectTarget: Array
		var count
		var allenemys: Array
		allenemys = player.enemy.duplicate()
		if is_instance_valid(enemy):
			start = enemy.position
			selectTarget.append(enemy)
			if allenemys.has(enemy):
				allenemys.erase(enemy)
				
			count = min(allenemys.size(), baseRicochet + ricochetBonus)
		else:
			start = pos
			count = min(allenemys.size(), baseRicochet + ricochetBonus)
		for i in range(count):
			line = Line2D.new()
			line.width = 1
			var y: int = 0
			while selectTarget.has(allenemys[y]) or (not is_instance_valid(allenemys[y])):
				y += 1
				if y > allenemys.size() - 1:
					return
			selectTarget.append(allenemys[y])
			var ends = allenemys[y].position
			line.points = [start, ends]
			start = ends
			get_tree().root.add_child(line)
			var time = get_tree().create_timer(0.1)
			time.timeout.connect(func():
				line.queue_free()
				)
			enemy = allenemys[y]
			if enemy.has_method("gotHurt"):
				enemy.gotHurt(baseDamage)
