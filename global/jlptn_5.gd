extends Node

# JLPT N5级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN5_Data:Dictionary

# JLPT N4级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN4_Data:Dictionary

# 单词本文件路径配置，键为单词本名称，值为对应的CSV文件路径
var wordBookPath:Dictionary={
	"JLPTN5":'res://word/JLPTN5.csv',
	"JLPTN4":'res://word/JLPTN4.csv'
}

# 存储所有已加载的单词数据，键为单词本名称，值为该单词本的所有单词数据
var word_data:Dictionary={}

# 当前选择的单词本列表，用于确定游戏中使用的单词范围
var wordBookList:Array=[
	"JLPTN5",
]

# 当前游戏实际使用的单词本列表（用于检测单词本是否发生变化）
var currentWordBookList:Array=[]

# 当前游戏中所有可用单词的键列表（随机排序后用于出题）
var allCurrentKeys:Array=[]

# 当前游戏中所有可用单词的完整数据字典，键为单词标识，值为单词详细信息
var allCurrentWordData:Dictionary={}

# 历史累计的所有错误单词数组（每次游戏结束时将当前错误单词添加到此数组）
var allErrorWord:Array

# 历史累计的所有正确单词数组（每次游戏结束时将当前正确单词添加到此数组）
var allcorrectWord:Array

# 当前游戏中的错误单词字典，键为单词假名，值为包含单词数据和错误次数的结构
var errorWord:Dictionary  # 存储当前游戏的错误单词，值包含单词数据和错误次数

# 当前游戏中的正确单词字典，键为单词假名，值为单词数据
var correctWord:Dictionary

# 从文件加载的已保存错误单词数组，包含历史错误记录和错误次数
var savedErrorWord:Array  # 存储从文件加载的错误单词，包含错误次数

# 已掌握的单词字典，键为单词假名，值为单词数据（错误次数为0且从错题本移除的单词）
var masteredWord:Dictionary  # 存储已掌握的单词（错误次数为0且从错题本移除）
func _ready() -> void:
	# 调用方: Godot引擎自动调用
	_loadWord()
	Eventmanger.restartGame.connect(_restartGame)
	Eventmanger.saveErrorWord.connect(_saveErrorWord)
	Eventmanger.gameover.connect(_clearWord)

func _addErrorWord(sword:Dictionary):
	# 调用方: main/UI/answerButton.gd (第45行)
	# 功能: 将答错的单词添加到错误单词列表，初始错误次数为3
	# 创建包含错误次数的数据结构
	var error_word_data = {
		"word_data": sword,
		"error_count": 3  # 新加入的错误单词初始错误次数为3
	}
	errorWord.set(sword.get("假名"), error_word_data)
	
func _addCorrectWord(sword:Dictionary):
	# 调用方: main/UI/answerButton.gd (第34行)
	# 功能: 将答对的单词添加到正确单词列表
	correctWord.set(sword.get("假名"),sword)

func _updateErrorWordCount(word:Dictionary, count_change:int):
	# 调用方: main/main.gd (第90行, 第101行), main/UI/answerButton.gd (第41行, 第52行)
	# 功能: 更新单词的错误次数，支持增加或减少错误次数
	# 逻辑问题: 当count_change为负数且单词不在错误列表中时，函数不会添加新条目，这是正确的
	var word_key = word.get("假名", "")
	if word_key.is_empty():
		return
	
	# 检查单词是否在当前错误列表中
	if errorWord.has(word_key):
		var error_word_data = errorWord.get(word_key)
		error_word_data.error_count += count_change
		
		# 如果错误次数小于等于0，从错误列表中移除
		if error_word_data.error_count <= 0:
			errorWord.erase(word_key)
			print("单词 '%s' 错误次数已降为0，从错误列表中移除" % word.get("日语汉字", word_key))
		else:
			print("单词 '%s' 错误次数更新为: %d" % [word.get("日语汉字", word_key), error_word_data.error_count])
	else:
		# 如果单词不在错误列表中且是增加错误次数，则添加新条目
		if count_change > 0:
			var error_word_data = {
				"word_data": word,
				"error_count": count_change
			}
			errorWord.set(word_key, error_word_data)
			print("新单词 '%s' 加入错误列表，错误次数: %d" % [word.get("日语汉字", word_key), count_change])

func _clearWord():
	# 调用方: Eventmanger.gameover信号触发 (第26行), main/UI/word_confirm.gd (第22行)
	# 功能: 游戏结束时清理当前游戏的单词数据，将正确和错误单词保存到历史记录
	allcorrectWord.append_array(correctWord.values())
	
	# 处理错误单词，只添加错误次数大于0的
	for word_key in errorWord.keys():
		var error_word = errorWord.get(word_key)
		if error_word.error_count > 0:
			allErrorWord.append(error_word)
		else:
			# 错误次数为0的单词加入已掌握单词库
			masteredWord.set(word_key, error_word.word_data)
	
	errorWord.clear()
	correctWord.clear()

func _getCurrentTitleWord():  # 获取当前题目单词，用于更新错误次数
	# 调用方: main/main.gd (第74行), main/UI/answerButton.gd (第39行, 第50行)
	# 逻辑问题: 此函数会调用_getNextWordData()并从allCurrentKeys中移除一个元素，可能导致题目顺序混乱
	var temp_Tiltle:Dictionary = _getNextWordData()
	if temp_Tiltle.is_empty():
		return null
	var temp_key = temp_Tiltle.keys()[0]
	return temp_Tiltle.get(temp_key)

func _restartGame():
	# 调用方: Eventmanger.restartGame信号触发 (第24行)
	# 功能: 重置游戏状态，清空所有单词记录
	allcorrectWord.clear()
	allErrorWord.clear()
	masteredWord.clear()
	pass


func _saveErrorWord():
	# 调用方: Eventmanger.saveErrorWord信号触发 (第25行)
	# 功能: 保存错误单词和已掌握单词到文件
	print("_saveErrorWord: 开始保存错误单词")
	print("_saveErrorWord: errorWord字典大小: %d" % errorWord.size())
	print("_saveErrorWord: allErrorWord数组大小: %d" % allErrorWord.size())
	print("_saveErrorWord: masteredWord字典大小: %d" % masteredWord.size())
	
	var savepath = "user://saveErrorWordData.json"
	var exitWord:Array = []
	
	# 加载已保存的错误单词
	if FileAccess.file_exists(savepath):
		print("_saveErrorWord: 发现已存在的保存文件")
		var openData = FileAccess.open(savepath,FileAccess.READ)
		if openData:
			var tempjson = openData.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_ARRAY:
				exitWord = tempData
				print("_saveErrorWord: 已加载 %d 个已保存的错误单词" % exitWord.size())
			else:
				push_error("数据加载失败")
		openData.close()
	else:
		print("_saveErrorWord: 保存文件不存在，将创建新文件")
	
	# 合并当前游戏的错误单词到已保存的列表
	var saved_word_dict:Dictionary = {}
	
	# 先将已保存的单词加入字典
	for saved_word in exitWord:
		if typeof(saved_word) == TYPE_DICTIONARY and saved_word.has("word_data"):
			var word_key = saved_word.word_data.get("假名", "")
			if not word_key.is_empty():
				saved_word_dict[word_key] = saved_word
	
	print("_saveErrorWord: 当前游戏错误单词数量: %d" % errorWord.size())
	print("_saveErrorWord: 当前游戏allErrorWord数量: %d" % allErrorWord.size())
	
	# 使用allErrorWord而不是errorWord，因为errorWord在游戏结束时已被清空
	var source_error_words = allErrorWord if errorWord.is_empty() else errorWord.values()
	
	# 然后将当前游戏的错误单词合并到字典
	for current_word in source_error_words:
		var word_key = current_word.word_data.get("假名", "")
		if word_key.is_empty():
			continue
			
		if saved_word_dict.has(word_key):
			# 如果已存在，累加错误次数
			var existing_word = saved_word_dict.get(word_key)
			existing_word.error_count += current_word.error_count
			saved_word_dict[word_key] = existing_word
			print("_saveErrorWord: 更新已存在的单词 '%s'，错误次数累加到 %d" % [word_key, existing_word.error_count])
		else:
			# 如果不存在，直接添加
			saved_word_dict[word_key] = current_word
			print("_saveErrorWord: 添加新单词 '%s'，错误次数: %d" % [word_key, current_word.error_count])
	
	# 保存已掌握的单词（错误次数为0且从错题本移除的单词）
	for mastered_key in masteredWord.keys():
		var mastered_data = masteredWord.get(mastered_key)
		# 检查是否已在保存数据中（避免重复保存）
		if not saved_word_dict.has(mastered_key):
			var mastered_entry = {
				"word_data": mastered_data,
				"error_count": 0,
				"mastered": true  # 标记为已掌握
			}
			saved_word_dict[mastered_key] = mastered_entry
			print("_saveErrorWord: 保存已掌握单词 '%s'" % mastered_key)
		else:
			print("_saveErrorWord: 已掌握单词 '%s' 已存在，跳过保存" % mastered_key)
	
	# 将字典转换回数组
	var save_array:Array = []
	for word_key in saved_word_dict.keys():
		save_array.append(saved_word_dict.get(word_key))
	
	print("_saveErrorWord: 最终保存 %d 个单词（包含错误单词和已掌握单词）" % save_array.size())
	
	# 保存到文件
	var file = FileAccess.open(savepath,FileAccess.WRITE)
	if file:
		var tempjson = JSON.stringify(save_array, "\t")
		file.store_string(tempjson)
		print("单词数据已保存，共 %d 个单词" % save_array.size())
	else:
		print("保存失败")
	
	print("_saveErrorWord: 保存完成")

func _loadErrorWord():
	# 调用方: menu/menu.gd (第104行)
	# 功能: 从文件加载错误单词和已掌握单词数据
	var savepath = "user://saveErrorWordData.json"

	if FileAccess.file_exists(savepath):
		var openData = FileAccess.open(savepath,FileAccess.READ)
		if openData:
			var tempjson = openData.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_ARRAY:
				savedErrorWord = tempData
				print("已加载 %d 个单词数据" % savedErrorWord.size())
				
				# 从保存数据中恢复已掌握的单词
				for saved_entry in savedErrorWord:
					if typeof(saved_entry) == TYPE_DICTIONARY and saved_entry.has("mastered") and saved_entry.mastered:
						var word_key = saved_entry.word_data.get("假名", "")
						if not word_key.is_empty():
							masteredWord.set(word_key, saved_entry.word_data)
							print("恢复已掌握单词: %s" % word_key)
			else:
				push_error("数据加载失败")
		openData.close()
	else:
		print("错误单词保存文件不存在，将创建新文件")
	
func _loadWord():
	# 调用方: _ready()函数 (第23行)
	# 功能: 从CSV文件加载单词数据到内存
	for y in wordBookPath:
		var tempWordData:Dictionary
		var file = FileAccess.open(wordBookPath.get(y),FileAccess.READ)
		if file == null:
			push_error(y+"单词csv文件读取失败，by:jlptn_5.gd")
			continue
		else:
			var headers = file.get_csv_line()
			if not "中文翻译" in headers:
				file.close()
				push_error("文件异常，没有中文翻译，无法使用这一行作为唯一id，by:jlptn_5.gd,002")
				continue
			while not file.eof_reached():
				var line_Data = file.get_csv_line()
				if line_Data.size() <= 1 and line_Data[0] =="":
					continue
				if line_Data.size() != headers.size():
					continue
				var row_dir ={}
				for i in range(headers.size()):
					var head = headers[i]
					var temp = line_Data[i]
					row_dir[head] = temp
				tempWordData[row_dir["中文翻译"]] = row_dir
			file.close()
			word_data.set(y,tempWordData)
			print(y+"单词加载完毕共载入单词",tempWordData.size(),"个。by：jlpt_n5.gd")


func sendWordData():
	# 调用方: _gameStart()函数 (第278行)
	# 功能: 根据当前单词本列表返回合并后的单词数据
	var tempdata:Dictionary={}
	for i in wordBookList:
		if not word_data.has(i):
			push_error("单词本"+ str(i)+"无法加载")
			continue
		tempdata.merge(word_data.get(i))
	return tempdata

func _setWordBookList(list:Array):
	# 调用方: menu/menu.gd (第58行)
	# 功能: 设置当前使用的单词本列表
	wordBookList.clear()
	wordBookList=list
	
func _getNextWordData():
	# 调用方: _getCurrentTitleWord()函数 (第81行), main/UI/answering.gd (第54行)
	# 逻辑问题: 此函数会从allCurrentKeys中移除一个元素，可能导致题目数量减少
	var tiltle:Dictionary
	if allCurrentKeys.size() >=4:
		var temp = allCurrentKeys.pop_back()
		tiltle[temp] = allCurrentWordData.get(temp)
	return tiltle
	
func _getErrorWordData():
	# 调用方: main/UI/answering.gd (第58行, 第133行)
	# 功能: 随机获取2个错误选项，用于选择题
	# 逻辑问题: 可能会返回重复的选项，因为随机数可能相同
	var ran:Array
	var selectErrorWord:Array
	ran.resize(2)
	for i in range(2):
		ran[i] = randi()%allCurrentKeys.size()
		var temp = allCurrentWordData.get(allCurrentKeys[ran[i]])
		if not temp.get("日语汉字").is_empty():
			if randi()%10 < 8:
				selectErrorWord.append(temp.get("日语汉字"))
			else :
				selectErrorWord.append(temp.get("假名"))
		else :
			selectErrorWord.append(temp.get("假名"))
	return selectErrorWord
func _gameStart():
	# 调用方: main/UI/answering.gd (第21行)
	# 功能: 游戏开始时初始化单词数据
	if currentWordBookList != wordBookList:
		currentWordBookList = wordBookList
		allCurrentWordData = sendWordData()
		allCurrentKeys = allCurrentWordData.keys()
		allCurrentKeys.shuffle()

# 获取错误次数最高的错题
func _getHighestErrorWord():
	# 调用方: main/UI/answering.gd (第114行)
	# 功能: 获取错误次数最高的单词，用于错题复习
	if errorWord.is_empty():
		return null
	
	var highest_error_word = null
	var highest_error_count = 0
	
	for word_key in errorWord.keys():
		var error_word_data = errorWord.get(word_key)
		if error_word_data.error_count > highest_error_count:
			highest_error_count = error_word_data.error_count
			highest_error_word = error_word_data.word_data
	
	return highest_error_word

# 获取单词重组模式的字符数据
func _getWordReorderData(target_word: Dictionary):
	# 调用方: main/UI/answering.gd (第204行)
	# 功能: 为单词重组模式生成字符数据，包括目标字符和干扰字符
	var result = {
		"target_word": target_word,
		"characters": [],
		"interference": []
	}
	
	# 提取目标词汇的假名和汉字部分
	var kana = target_word.get("假名", "")
	var kanji = target_word.get("日语汉字", "")
	
	# 将假名按字符拆分
	for i in range(kana.length()):
		result.characters.append(kana.substr(i, 1))
	
	# 汉字保持整体
	if not kanji.is_empty():
		result.characters.append(kanji)
	
	# 添加2-3个干扰字符（来自同级别其他词汇）
	var interference_count = randi_range(2, 4)
	var available_words = allCurrentWordData.values()
	available_words.shuffle()
	
	for word in available_words:
		if interference_count <= 0:
			break
		
		# 避免使用目标词汇的字符
		var source_kana = word.get("假名", "")
		var source_kanji = word.get("日语汉字", "")
		
		# 优先使用假名作为干扰字符
		if not source_kana.is_empty():
			var random_char = source_kana.substr(randi() % source_kana.length(), 1)
			if not result.characters.has(random_char):
				result.interference.append(random_char)
				interference_count -= 1
				print("添加假名干扰字符: ", random_char, " 来自单词: ", word.get("中文翻译", ""))
		# 如果假名为空，尝试使用汉字作为干扰字符
		elif not source_kanji.is_empty():
			var random_char = source_kanji.substr(randi() % source_kanji.length(), 1)
			if not result.characters.has(random_char):
				result.interference.append(random_char)
				interference_count -= 1
				print("添加汉字干扰字符: ", random_char, " 来自单词: ", word.get("中文翻译", ""))
	
	# 合并所有选项并随机排序
	var all_options = []
	all_options.append_array(result.characters)
	all_options.append_array(result.interference)
	all_options.shuffle()
	
	result.all_options = all_options
	return result

# 获取已掌握的单词（错误次数为0或不在错题本中）用于单词重组模式
func _getMasteredWordForReorder():
	# 调用方: main/UI/answering.gd (第188行)
	# 功能: 获取一个已掌握的单词用于单词重组模式
	# 逻辑问题: 此函数可能返回null，调用方需要处理这种情况
	var mastered_words = []
	
	# 从所有当前单词中筛选出已掌握的单词
	for current_key in allCurrentKeys:
		var current_word_data = allCurrentWordData.get(current_key)
		
		# 检查单词是否在错题本中
		var is_in_error_book = errorWord.has(current_word_data.get("假名", ""))
		
		# 如果不在错题本中，则认为是已掌握的
		if not is_in_error_book:
			mastered_words.append(current_word_data)
	
	# 如果没有已掌握的单词，返回null
	if mastered_words.is_empty():
		return null
	
	# 随机选择一个已掌握的单词
	mastered_words.shuffle()
	return mastered_words[0]
