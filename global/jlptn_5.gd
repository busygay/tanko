extends Node

# JLPT N5级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN5_Data: Dictionary

# JLPT N4级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN4_Data: Dictionary

# 单词本文件路径配置，键为单词本名称，值为对应的CSV文件路径
var wordBookPath: Dictionary = {
	"JLPTN5": 'res://word/JLPTN5.csv',
	"JLPTN4": 'res://word/JLPTN4.csv',
	"JLPTN3": 'res://word/JLPTN3.csv',
}

#用于保存错误单词文件路径
var savepath = "user://saveData.json"

# 全局ID映射表，键为唯一ID，值为单词数据引用
var _id_map: Dictionary = {}


# 存储所有已加载的单词数据，键为单词本名称，值为该单词本的所有单词数据
var word_data: Dictionary = {}

# 当前选择的单词本列表，用于确定游戏中使用的单词范围，默认情况下使用JLPT N5级别单词本
var wordBookList: Array = [
	"JLPTN5",
]


# 当前游戏实际使用的单词本列表（用于检测单词本是否发生变化）
var currentWordBookList: Array = []

# 当前游戏中所有可用单词的键列表（随机排序后用于出题）
var allCurrentKeys: Array = []

# 当前游戏中所有可用单词的完整数据字典，键为单词标识，值为单词详细信息
var allCurrentWordData: Dictionary = {}

# 历史累计的所有错误单词单词字典（进入下一个关卡就会将数据累计起来）
var allErrorWord: Dictionary

# 历史累计的所有正确单词字典（进入下一个关卡就会将数据累计起来）
var allcorrectWord: Dictionary

# 当前游戏中的错误单词字典，键为单词假名，值为包含单词数据和错误次数的结构
var errorWord: Dictionary # 存储当前游戏的错误单词，值包含单词数据和错误次数

# 当前游戏中的正确单词字典，键为单词假名，值为单词数据
var correctWord: Dictionary

# 从文件加载的已保存错误单词数组，包含历史错误记录和错误次数
var savedErrorWord: Dictionary # 存储从文件加载的错误单词，包含错误次数

# 已掌握的单词字典，键为单词假名，值为单词数据（错误次数为0且从错题本移除的单词）
var masteredWord: Dictionary # 存储已掌握的单词（错误次数为0且从错题本移除）

# 【新增】假名备份字符常量，用于单词重组时的干扰项
const BACKUP_KANA_CHARS = [
	"あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ",
	"さ", "し", "す", "せ", "そ", "た", "ち", "つ", "て", "と",
	"な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ",
	"ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り",
	"る", "れ", "ろ", "わ", "を", "ん", "が", "ぎ", "ぐ", "げ",
	"ご", "ざ", "じ", "ず", "ぜ", "ぞ", "だ", "ぢ", "づ", "で",
	"ど", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ"
]
const MIN_DISTRACTORS = 5

var needSave: bool = false
func _ready() -> void:
	# 调用方: Godot引擎自动调用
	_loadWord()
	_loadErrorWord() # 加载已保存的错误单词和已掌握单词数据
	Eventmanger.restartGame.connect(_restartGame)
	Eventmanger.saveErrorWord.connect(func():
		needSave = true
		)
	Eventmanger.gameover.connect(_clearWord)


func updateWordCount(word: Dictionary, count_change: int):
	var word_key = word.get("假名", "")
	if word_key.is_empty():
		return
	# 根据count_change的值决定增加或减少错误次数,-1为答对题目需要减少错误次数，3为答错题目需要增加错误次数
	match count_change:
		-1:
			#先将正确的单词加入正确列表
			correctWord.set(word_key, word)

			#按照顺序合并错题本。
			var error_lists = [errorWord, allErrorWord, savedErrorWord]
			# 按优先级检查并更新所有错误单词列表
			for error_list in error_lists:
				if error_list.has(word_key):
					var error_word_data = error_list.get(word_key)
					var tempCount = error_word_data.get("error_count", 1)
					tempCount += count_change
					if tempCount <= 0:
						error_list.erase(word_key)
						masteredWord.set(word_key, word) # 添加到已掌握单词列表
					else:
						error_word_data.set("error_count", tempCount) # 如果错误次数小于等于0，从错误列表中移除
		3:
			#增加错误次数
			#直接添加到当前游戏的错误列表里
			if errorWord.has(word_key):
				var error_word_data = errorWord.get(word_key)
				error_word_data.error_count += count_change
			else:
				var add_data = word.duplicate()
				add_data.set("error_count", count_change)
				errorWord.set(word_key, add_data)


##有点问题。应该会和_updataErrorWordCount重复添加数据
func _clearWord():
	# 调用方: Eventmanger.gameover信号触发 (第26行), main/UI/word_confirm.gd (第22行)
	# 功能: 游戏结束时清理当前游戏的单词数据，将正确和错误单词保存到历史记录
	#对于正确单词直接合并。
	allcorrectWord.assign(correctWord)
	#对于错误的单词需要计算错误次数后再合并。
	
	for word_key in errorWord.keys():
		#如果allErrorWord中有相同错误单词就合并错误次数
		if allErrorWord.has(word_key):
			var tempErrorWord = allErrorWord.get(word_key)

			var tempCount = errorWord.get(word_key).get("error_count") + allErrorWord.get(word_key).get("error_count")
			tempErrorWord.set("error_count", tempCount)
			allErrorWord.set(word_key, tempErrorWord)
		else:
			#如果是新的错误单词就直接添加进allErrorWord中。
			allErrorWord.set(word_key, errorWord.get(word_key))


	errorWord.clear()
	correctWord.clear()


func _restartGame():
	# 调用方: Eventmanger.restartGame信号触发 (第24行)
	# 功能: 重置游戏状态，清空所有单词记录
	_saveErrorWord()
	needSave = false
	allcorrectWord.clear()
	allErrorWord.clear()
	pass


func _saveErrorWord():
	# 调用方: Eventmanger.saveErrorWord信号触发 (第25行)
	# 功能: 保存错误单词和已掌握单词到统一文件 (ID Based)
	# 1. 先合并allErrorWord到savedErrorWord (确保拥有最新数据)
	for tempWordKey in allErrorWord:
		var cheackWord = savedErrorWord.get(tempWordKey, null)
		var needSaveWord = allErrorWord.get(tempWordKey)
		# 如果该单词重复则累加错误次数
		if cheackWord:
			var tempcount = cheackWord.get("error_count", 3) + needSaveWord.get("error_count", 3)
			cheackWord.set("error_count", tempcount)
		else:
			# 如果是新的错误单词则直接添加进SavedErrorWord
			savedErrorWord.set(tempWordKey, needSaveWord)

	# 2. 构建保存数据结构 (仅保存ID和必要状态)
	var save_data = {
		"error": {}, # ID -> error_count
		"mastered": [] # List of IDs
	}

	# 处理错误单词
	for key in savedErrorWord:
		var word = savedErrorWord[key]
		var uid = word.get("id")
		if uid:
			save_data["error"][uid] = word.get("error_count", 3)
		else:
			push_warning("单词缺少ID, 无法保存: " + str(key))

	# 处理已掌握单词
	for key in masteredWord:
		var word = masteredWord[key]
		var uid = word.get("id")
		if uid:
			save_data["mastered"].append(uid)
		else:
			push_warning("已掌握单词缺少ID, 无法保存: " + str(key))

	# 3. 写入文件
	var file = FileAccess.open(savepath, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data, "\t")
		file.store_string(json_str)
		print("保存完成。错误单词: %d, 已掌握单词: %d" % [save_data["error"].size(), save_data["mastered"].size()])
		file.close()
	else:
		push_error("保存文件失败")


func _loadErrorWord():
	# 调用方: menu/menu.gd (第104行)
	# 功能: 从文件加载ID数据并还原单词对象
	if not FileAccess.file_exists(savepath):
		print("存档文件不存在，跳过加载")
		return

	var file = FileAccess.open(savepath, FileAccess.READ)
	if not file:
		push_error("无法打开存档文件")
		return

	var json_text = file.get_as_text()
	var save_data = JSON.parse_string(json_text)
	file.close()

	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("存档格式错误")
		return

	# 还原错误单词
	savedErrorWord.clear()
	var error_ids = save_data.get("error", {})
	if typeof(error_ids) == TYPE_DICTIONARY:
		for uid in error_ids:
			if _id_map.has(uid):
				var temp_word_data = _id_map[uid].duplicate()
				temp_word_data["error_count"] = error_ids[uid]
				var word_key = temp_word_data.get("假名", "")
				if word_key:
					savedErrorWord[word_key] = temp_word_data
			else:
				print("ID未找到(可能词库已更新): " + str(uid))

	# 还原已掌握单词
	masteredWord.clear()
	var mastered_ids = save_data.get("mastered", [])
	if typeof(mastered_ids) == TYPE_ARRAY:
		for uid in mastered_ids:
			if _id_map.has(uid):
				var temp_word_data = _id_map[uid].duplicate()
				temp_word_data["error_count"] = 0 # 确保已掌握也是0错误
				var word_key = temp_word_data.get("假名", "")
				if word_key:
					masteredWord[word_key] = temp_word_data
			else:
				print("ID未找到(可能词库已更新): " + str(uid))
	
	print("加载完成。恢复错误单词: %d, 已掌握单词: %d" % [savedErrorWord.size(), masteredWord.size()])

	
func _loadWord():
	# 调用方: _ready()函数 (第23行)
	# 功能: 从CSV文件加载单词数据到内存
	for y in wordBookPath:
		var tempWordData: Dictionary
		var file = FileAccess.open(wordBookPath.get(y), FileAccess.READ)
		if file == null:
			push_error(y + "单词csv文件读取失败，by:jlptn_5.gd")
			continue
		else:
			var headers = file.get_csv_line()
			if not "中文翻译" in headers:
				file.close()
				push_error("文件异常，没有中文翻译，无法使用这一行作为唯一id，by:jlptn_5.gd,002")
				continue
			var _index = 0
			while not file.eof_reached():
				var line_Data = file.get_csv_line()
				if line_Data.size() <= 1 and line_Data[0] == "":
					continue
				if line_Data.size() != headers.size():
					continue
				var row_dir = {}
				for i in range(headers.size()):
					var head = headers[i]
					var temp = line_Data[i]
					#如果项目是空，不为空项目设置key和值
					if temp == "":
						continue
					row_dir[head] = temp
				
				# 生成唯一ID: 词库名_序号
				var unique_id = "%s_%d" % [y, _index]
				row_dir["id"] = unique_id
				_id_map[unique_id] = row_dir
				_index += 1

				if row_dir.get("假名"):
					tempWordData[row_dir["假名"]] = row_dir
			file.close()
			word_data.set(y, tempWordData)
			print(y + "单词加载完毕共载入单词", tempWordData.size(), "个。by：jlpt_n5.gd")


func sendWordData():
	# 调用方: _gameStart()函数 (第278行)
	# 功能: 根据当前单词本列表返回合并后的单词数据
	var tempdata: Dictionary = {}
	for i in wordBookList:
		if not word_data.has(i):
			push_error("单词本" + str(i) + "无法加载")
			continue
		tempdata.merge(word_data.get(i))
	return tempdata

func _setWordBookList(list: Array):
	# 调用方: menu/menu.gd (第58行)
	# 功能: 设置当前使用的单词本列表
	wordBookList.clear()
	wordBookList = list.duplicate()


func getNextQuestion(type: int = 0) -> Dictionary:
	var questionData: Dictionary = {}
	
	# 【修复】初始化变量，防止 null 引用崩溃
	var tiltle: Dictionary = {}
	var correctData: Array = []
	var selectErrorWordData: Array = []
	var errorButtonCount: int = 0
	var selectErrorKeys: Array = []
	# 错误单词库集合
	var allErrorWordDataDic: Array = [
		errorWord,
		allErrorWord,
		savedErrorWord,
	]
	var uesDic: Dictionary = {}

	# --- 逻辑检查与类型回退 (保持原有逻辑并增强) ---
	if type == 1:
		for i in allErrorWordDataDic:
			if not i.is_empty():
				uesDic = i
				break
		if uesDic.is_empty():
			type = 0
	
	# 检查 Type 2 的前置条件
	if type == 2:
		if masteredWord.is_empty():
			type = 1
			for i in allErrorWordDataDic:
				if not i.is_empty():
					uesDic = i
					break
			if uesDic.is_empty():
				type = 0

	match type:
		0:
			# 设置题目
			# 【修复】防止数组越界和 pop_back 导致的崩溃
			var selectTilteKey
			if allCurrentKeys.size() >= 4:
				# 注意：pop_back 会永久删除数据，请确保这是你想要的效果（即出过题就不再出）
				# 如果 allCurrentKeys 数量很少，这里需要处理逻辑，而不是 pass
				selectTilteKey = allCurrentKeys.pop_back()
				tiltle = allCurrentWordData.get(selectTilteKey, {})
			else:
				print("题目不足，需重新加载")
				questionData.set("isNotEnoughWord", true)
				return questionData

			# 【修复】增加判空，防止 tiltle 为空时崩溃
			if tiltle.is_empty():
				return {}

			# 将正确选项放入 correctData
			if tiltle.get("日语汉字", null):
				if randi() % 2 >= 1:
					correctData.append(tiltle.get("日语汉字"))
				else:
					correctData.append(tiltle.get("假名"))
			else:
				correctData.append(tiltle.get("假名"))

			# 获取干扰选项
			for i in range(3):
				var tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
				
				# 【修复】死循环保护：增加最大尝试次数
				var max_attempts = 30
				while (selectErrorKeys.has(tempkey) or tempkey == selectTilteKey) and max_attempts > 0:
					tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
					max_attempts -= 1
				# 只有不重复才添加
				if not selectErrorKeys.has(tempkey):
					selectErrorKeys.append(tempkey)

			# 填充干扰内容
			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i, {})
				var errorWordStr: String
				
				if tempWordData.get("日语汉字", null):
					if randi() % 2 >= 1:
						errorWordStr = tempWordData.get("日语汉字")
					else:
						errorWordStr = tempWordData.get("假名")
				else:
					errorWordStr = tempWordData.get("假名", "")

				selectErrorWordData.append(errorWordStr)

			var temp = tiltle.get("容易混淆的单词", null)
			if temp:
				selectErrorWordData.append(temp)
			errorButtonCount = 3
		
		1:
			# 设置错题题目
			var tempKeys = uesDic.keys()
			# 【修复】除以零保护
			if tempKeys.size() == 0:
				questionData.set("isNotEnoughWord", true)
				return questionData

			var random_key = tempKeys[randi() % tempKeys.size()]
			var tempTiltle = uesDic.get(random_key, null)
			
			if tempTiltle:
				# 使用 duplicate 避免修改原始数据中的 error_count
				tiltle = tempTiltle.duplicate()
				tiltle.erase("error_count")
			else:
				print("无法设置题目")
				questionData.set("isNotEnoughWord", true)
				return questionData
			
			# 正确选项逻辑 (同上)
			if tiltle.get("日语汉字", null):
				if randi() % 2 >= 1:
					correctData.append(tiltle.get("日语汉字"))
				else:
					correctData.append(tiltle.get("假名"))
			else:
				correctData.append(tiltle.get("假名"))
			
			# 干扰选项逻辑 (同 type 0，增加安全检查)

			# 当前题库小于 4题时，提示题目不足
			if allCurrentKeys.size() < 4:
				questionData.set("isNotEnoughWord", true)
				return questionData

			for i in range(3):
				var tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
				var max_attempts = 30
				while (selectErrorKeys.has(tempkey) or tempkey == random_key) and max_attempts > 0:
					tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
					max_attempts -= 1
					
				if not selectErrorKeys.has(tempkey):
						selectErrorKeys.append(tempkey)

			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i, {})
				var tempErrorWord: String
				if tempWordData.get("日语汉字", null):
					if randi() % 2 >= 1:
						tempErrorWord = tempWordData.get("日语汉字")
					else:
						tempErrorWord = tempWordData.get("假名")
				else:
					tempErrorWord = tempWordData.get("假名", "")
				selectErrorWordData.append(tempErrorWord)

			var temp = tiltle.get("容易混淆的单词", null)
			if temp:
				selectErrorWordData.append(temp)
			errorButtonCount = 3
			
		2:
			# 单词重组
			var tempKeys = masteredWord.keys()
			if tempKeys.size() == 0:
				questionData.set("isNotEnoughWord", true)
				return questionData # 安全检查

			var tempTiltle = masteredWord.get(tempKeys[randi() % tempKeys.size()], null)
			if tempTiltle:
				tiltle = tempTiltle
			else:
				questionData.set("isNotEnoughWord", true)
				return questionData

			var targetWord: String
			if tiltle.get("日语汉字", null):
				if randi() % 2 != 0: # 修正写法
					targetWord = tiltle.get("日语汉字")
				else:
					targetWord = tiltle.get("假名")
			else:
				targetWord = tiltle.get("假名", "")
			
			# 拆分正确答案
			for i in range(targetWord.length()):
				correctData.append(targetWord.substr(i, 1))

			# 获取干扰项
			#题库小于4时提示题目不足
			if allCurrentKeys.size() < 4:
				questionData.set("isNotEnoughWord", true)
				return questionData
			
			# 修正循环逻辑
			var available_distractors = allCurrentKeys.size()
			if available_distractors > 0:
				for i in range(min(3, available_distractors)):
					var tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
					var max_attempts = 10
					while selectErrorKeys.has(tempkey) and max_attempts > 0:
						tempkey = allCurrentKeys[randi() % allCurrentKeys.size()]
						max_attempts -= 1
					
					# 【重要修复】之前这里漏掉了 append，导致干扰项永远为空
					if not selectErrorKeys.has(tempkey):
						selectErrorKeys.append(tempkey)
			
			# 【修复】显式初始化数组
			var tempWordArray: Array = []
			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i, {})
				var tempErrorWord: String
				if tempWordData.get("日语汉字", null):
					if randi() % 2 >= 1:
						tempErrorWord = tempWordData.get("日语汉字")
					else:
						tempErrorWord = tempWordData.get("假名")
				else:
					tempErrorWord = tempWordData.get("假名", "")
				tempWordArray.append(tempErrorWord)
			
			# 拆分干扰字符
			for i in tempWordArray:
				for y in range(i.length()):
					var tempStr = i.substr(y, 1)
					selectErrorWordData.append(tempStr)
			
			# 移除与正确答案重复的字符
			for i in correctData:
				while selectErrorWordData.has(i):
					selectErrorWordData.erase(i)

			#如果生成的错误选项不够，就听见假名库内的单词。
			if selectErrorWordData.size() < MIN_DISTRACTORS:
				# 【新增】使用假名备份字符确保足够的干扰项
				var backup_chars = BACKUP_KANA_CHARS.duplicate()
				# 也排除目标单词中的字符
				for i in correctData:
					while backup_chars.has(i):
						backup_chars.erase(i)
				backup_chars.shuffle()
				while selectErrorWordData.size() < MIN_DISTRACTORS and not backup_chars.is_empty():
					selectErrorWordData.append(backup_chars.pop_front())
			errorButtonCount = max(1, int(selectErrorWordData.size() * 0.8))

	questionData = {
		"type": type,
		"tiltle": tiltle,
		"correctData": correctData,
		"selectErrorWordData": selectErrorWordData,
		"errorButtonCount": errorButtonCount,

	}
	return questionData


func _gameStart(force: bool = false):
	# 调用方: main/UI/answering.gd (第21行)
	# 功能: 游戏开始时初始化单词数据
	if force or currentWordBookList != wordBookList:
		currentWordBookList = wordBookList
		allCurrentWordData = sendWordData()
		allCurrentKeys = allCurrentWordData.keys()
		allCurrentKeys.shuffle()
