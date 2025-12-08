extends Node

# AudioManager.gd


# 预加载你所有可能需要一次性播放的音效
# 这样做比每次都 load() 效率高得多
var sfx_library = {
	"22LRSingleMP3": preload('res://sounds/22LRSingleMP3.mp3'),
	"Semi22LRReloadFullMP3":preload('res://sounds/Semi22LRReloadFullMP3.mp3'),
	"Semi22LRCantReloadMP3":preload('res://sounds/Semi22LRCantReloadMP3.mp3'),
	"762x54rSprayIsolatedMP3":preload('uid://bsnnskomqvgqj')
	# "explosion": preload('res://sounds/explosion.mp3')  # 文件不存在，暂时注释掉
}

# 播放非空间化音效（如UI）
func play_sfx(sound_name: String):
	var player = AudioStreamPlayer.new()
	player.stream = sfx_library.get(sound_name)
	add_child(player) # 将其添加到管理器下
	player.play()
	# 当播放完成时，自动销毁
	player.finished.connect(player.queue_free)

# --- 这是关键：播放空间化音效 ---
func play_sfx_at_position(sound_name: String, position: Vector2,_DB:float=1.0):
	var player:AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	player.volume_linear = _DB
	player.stream = sfx_library.get(sound_name)
	# 把它添加到主场景树的根节点，这样它的位置才是世界坐标
	get_tree().root.add_child(player)
	player.global_position = position
	player.play()
	# 同样，播放完后自动销毁
	player.finished.connect(player.queue_free)
