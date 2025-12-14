extends "res://skill/scene/skill.gd"
const TURRET_BT_7270 = preload('uid://d1t5wfugr4e7j')

var currentTurret: Node2D = null
var baseHealth: int = 10
var baseRotSpeed: float = PI / 2
var baseliveTime: float = 10
var damageMultiplier: float = 1.0
var upgrade_count: int = 0

func _ready() -> void:
	super ()
	Eventmanger.bt7270UP.connect(bt7270UpFunc)

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	spwanTurret(_dic)

func spwanTurret(_dic: Dictionary = {}):
	var turretHealth: int = baseHealth
	var turretDamage: float = 0.0
	var turretRotSpeed: float = baseRotSpeed
	var turretLiveTime: float = baseliveTime
	
	
	var player = get_tree().get_first_node_in_group("player")
	var inner_radius = 50
	var outer_radius = 200.0
	var random_angle = randf_range(0, 2 * PI)
	var random_radius = randf_range(inner_radius, outer_radius)
	var offset = Vector2.RIGHT.rotated(random_angle) * random_radius
	var spawn_position = player.global_position + offset
	var turret_instance = TURRET_BT_7270.instantiate()
	if currentTurret != null:
		turretDamage += currentTurret.damage * (0.2 + damageMultiplier)
		currentTurret.enterState(4)
		await currentTurret.spawn.animation_finished
	else:
		turretDamage += 0
	#turretDamage += player.baseDamage * 0.1 * damageMultiplier
	
	if _dic.has("fiveCombo"):
		turretLiveTime += turretLiveTime * 5
		turretDamage += turretDamage
	
	turret_instance._setData(turretHealth, turretDamage, spawn_position, turretRotSpeed, turretLiveTime)
	get_tree().get_first_node_in_group("main").add_child(turret_instance)
	currentTurret = turret_instance

func bt7270UpFunc():
	damageMultiplier += 0.05
	upgrade_count += 1
