extends Node
var jlptN5_Data:Dictionary
var jlptN4_Data:Dictionary
var wordBookPath:Dictionary={
	"JLPTN5":'res://word/JLPTN5.csv',
	"JLPTN4":'res://word/JLPTN4.csv'
}

var word_data:Dictionary={}
var wordBookList:Array=[
	"JLPTN5",
]
var currentWordBookList:Array=[]
var allCurrentKeys:Array=[]
var allCurrentWordData:Dictionary={}
var allErrorWord:Array
var allcorrectWord:Array
var errorWord:Dictionary  # 存储当前游戏的错误单词，值包含单词数据和错误次数
var correctWord:Dictionary
var savedErrorWord:Array  # 存储从文件加载的错误单词，包含错误次数
func _ready() -> void:
	_loadWord()
	Eventmanger.restartGame.connect(_restartGame)
	Eventmanger.saveErrorWord.connect(_saveErrorWord)
	Eventmanger.gameover.connect(_clearWord)

func _addErrorWord(sword:Dictionary):
	# 创建包含错误次数的数据结构
	var error_word_data = {
		"word_data": sword,
		"error_count": 3  # 新加入的错误单词初始错误次数为3
	}
	errorWord.set(sword.get("假名"), error_word_data)
	
func _addCorrectWord(sword:Dictionary):
	correctWord.set(sword.get("假名"),sword)

func _updateErrorWordCount(word:Dictionary, count_change:int):
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
	allcorrectWord.append_array(correctWord.values())
	
	# 处理错误单词，只添加错误次数大于0的
	for word_key in errorWord.keys():
		var error_word = errorWord.get(word_key)
		if error_word.error_count > 0:
			allErrorWord.append(error_word)
	
	errorWord.clear()
	correctWord.clear()

func _getCurrentTitleWord():  # 获取当前题目单词，用于更新错误次数
	var temp_Tiltle:Dictionary = _getNextWordData()
	if temp_Tiltle.is_empty():
		return null
	var temp_key = temp_Tiltle.keys()[0]
	return temp_Tiltle.get(temp_key)

func _restartGame():
	allcorrectWord.clear()
	allErrorWord.clear()
	pass


func _saveErrorWord():
	print("_saveErrorWord: 开始保存错误单词")
	print("_saveErrorWord: errorWord字典大小: %d" % errorWord.size())
	print("_saveErrorWord: allErrorWord数组大小: %d" % allErrorWord.size())
	
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
	var word_dict:Dictionary = {}
	
	# 先将已保存的单词加入字典
	for saved_word in exitWord:
		if typeof(saved_word) == TYPE_DICTIONARY and saved_word.has("word_data"):
			var word_key = saved_word.word_data.get("假名", "")
			if not word_key.is_empty():
				word_dict[word_key] = saved_word
	
	print("_saveErrorWord: 当前游戏错误单词数量: %d" % errorWord.size())
	print("_saveErrorWord: 当前游戏allErrorWord数量: %d" % allErrorWord.size())
	
	# 使用allErrorWord而不是errorWord，因为errorWord在游戏结束时已被清空
	var source_error_words = allErrorWord if errorWord.is_empty() else errorWord.values()
	
	# 然后将当前游戏的错误单词合并到字典
	for current_word in source_error_words:
		var word_key = current_word.word_data.get("假名", "")
		if word_key.is_empty():
			continue
			
		if word_dict.has(word_key):
			# 如果已存在，累加错误次数
			var existing_word = word_dict.get(word_key)
			existing_word.error_count += current_word.error_count
			word_dict[word_key] = existing_word
			print("_saveErrorWord: 更新已存在的单词 '%s'，错误次数累加到 %d" % [word_key, existing_word.error_count])
		else:
			# 如果不存在，直接添加
			word_dict[word_key] = current_word
			print("_saveErrorWord: 添加新单词 '%s'，错误次数: %d" % [word_key, current_word.error_count])
	
	# 将字典转换回数组
	var save_array:Array = []
	for word_key in word_dict.keys():
		save_array.append(word_dict.get(word_key))
	
	print("_saveErrorWord: 最终保存 %d 个错误单词" % save_array.size())
	
	# 保存到文件
	var file = FileAccess.open(savepath,FileAccess.WRITE)
	if file:
		var tempjson = JSON.stringify(save_array, "\t")
		file.store_string(tempjson)
		print("错误单词已保存，共 %d 个单词" % save_array.size())
	else:
		print("保存失败")
	
	print("_saveErrorWord: 保存完成")

func _loadErrorWord():
	var savepath = "user://saveErrorWordData.json"

	if FileAccess.file_exists(savepath):
		var openData = FileAccess.open(savepath,FileAccess.READ)
		if openData:
			var tempjson = openData.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_ARRAY:
				savedErrorWord = tempData
				print("已加载 %d 个错误单词" % savedErrorWord.size())
			else:
				push_error("数据加载失败")
		openData.close()
	else:
		print("错误单词保存文件不存在，将创建新文件")
	
func _loadWord():
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
	var tempdata:Dictionary={}
	for i in wordBookList:
		if not word_data.has(i):
			push_error("单词本"+ str(i)+"无法加载")
			continue
		tempdata.merge(word_data.get(i))
	return tempdata

func _setWordBookList(list:Array):
	wordBookList.clear()
	wordBookList=list
	
func _getNextWordData():
	var tiltle:Dictionary
	if allCurrentKeys.size() >=4:
		var temp = allCurrentKeys.pop_back()
		tiltle[temp] = allCurrentWordData.get(temp)
	return tiltle
	
func _getErrorWordData():
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
	if currentWordBookList != wordBookList:
		currentWordBookList = wordBookList
		allCurrentWordData = sendWordData()
		allCurrentKeys = allCurrentWordData.keys()
		allCurrentKeys.shuffle()

		
