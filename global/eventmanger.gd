extends Node
var player
var allenemyboxcount:int = 0
var answering = null
var bullet = null
var powerbar =null
func _ready() -> void:
	randomize()
	enemySpawn.connect(enemySpawnfunc)
	enemydeath.connect(enemydeathfunc)
	answered.connect(addCurrentAmmo)

func enemySpawnfunc(enemynode):
	player.enemy.append(enemynode)
func enemydeathfunc(enemynode):
	# 检查并清理所有无效的敌人引用
	for i in range(player.enemy.size() - 1, -1, -1):
		if not is_instance_valid(player.enemy[i]):
			player.enemy.remove_at(i)
	
	# 移除特定的敌人节点
	if player.enemy.has(enemynode):
		player.enemy.remove_at(player.enemy.find(enemynode))
func reloadAmmofunc():
	player.animation_player.play("reloadAmmo")
func addCurrentAmmo(isanswer:bool):
	if isanswer:
		player.currentAmmo+=1
		

func register_player(player_node):
	player=player_node
	
###第一个变量是为node,第二个变量当调用节点为answering时写true，否则写fales
func setbulletPos(_node,who:bool):
	if who:
		answering = _node
	else :
		bullet = _node
	if answering != null and bullet != null:
		await get_tree().process_frame
		var temp =answering.answerPanlePos()
		bullet.position.y = temp.position.y-bullet.size.y

func setpowerPos(_node,who:bool):
	if who:
		answering = _node
	else :
		powerbar = _node
	if answering != null and powerbar != null:
		await get_tree().process_frame
		var temp =answering.answerPanlePos()
		powerbar.position.y = temp.position.y-powerbar.size.y


@warning_ignore('unused_signal')
signal correctcountchange
@warning_ignore('unused_signal')
signal actionPointUp
@warning_ignore('unused_signal')
signal actionPoinSub

@warning_ignore('unused_signal')
signal playershooting
@warning_ignore('unused_signal')
signal playerShooted
@warning_ignore('unused_signal')
signal playerGotHurt(damage:int)
@warning_ignore('unused_signal')
signal reloadAmmo
@warning_ignore('unused_signal')
signal FinishReloadAmmo
@warning_ignore('unused_signal')
signal playerbulletCount(count:int)
@warning_ignore('unused_signal')
signal parryInvincible()

###玩家数值提升相关
@warning_ignore('unused_signal')
signal playerCdSub()
@warning_ignore('unused_signal')
signal playerBaseDamageUp()
@warning_ignore('unused_signal')
signal playerTrueDamageUp()
@warning_ignore('unused_signal')
signal playerGlobalDammageBonusChange(bonus:int)


signal answered(isanswer:bool)
@warning_ignore('unused_signal')
signal answerFinsh
@warning_ignore('unused_signal')
signal questionSkipped  # 新增跳过信号
@warning_ignore('unused_signal')
signal comboChange

@warning_ignore('unused_signal')
signal enterTreeEnemy
@warning_ignore('unused_signal')
signal exitTreeEnemy
@warning_ignore('unused_signal')
signal enemySpawn(enemynode)
@warning_ignore('unused_signal')
signal enemydeath(enemynode)
@warning_ignore('unused_signal')
signal spawnEnemy(_node)
@warning_ignore('unused_signal')
signal levelOver
@warning_ignore('unused_signal')
signal NextLevel
@warning_ignore('unused_signal')
signal ShowShoping(levelDone:bool)

@warning_ignore('unused_signal')
signal GameStart
@warning_ignore('unused_signal')
signal gameover
@warning_ignore('unused_signal')
signal restartGame
@warning_ignore('unused_signal')
signal saveErrorWord


@warning_ignore('unused_signal')
signal UIHideAll(_node)
@warning_ignore('unused_signal')
signal UIShowAll

##技能触发器
@warning_ignore('unused_signal')
signal twoComboEmit
@warning_ignore('unused_signal')
signal fiveComboEmit
@warning_ignore('unused_signal')
signal onComboEmit
@warning_ignore('unused_signal')
signal brokenComboEmit
@warning_ignore('unused_signal')
signal APGainedEmit
@warning_ignore('unused_signal')
signal APSpentEmit
@warning_ignore('unused_signal')
signal setequidDAta(_node)
@warning_ignore('unused_signal')
signal drag_ended(_node,pos)
@warning_ignore('unused_signal')
signal equidSkill(tiggerName,SkillNode)
@warning_ignore('unused_signal')
signal ShowSkillAssembly

##技能效果
@warning_ignore('unused_signal')
signal ricochetShootUp

@warning_ignore('unused_signal')
signal doubleShootUP
var isQuiting:bool
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if isQuiting:
				return
			isQuiting=true
			get_tree().quit()
