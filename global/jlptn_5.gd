extends Node

# JLPT N5级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN5_Data:Dictionary

# JLPT N4级别单词数据字典（当前未使用，可能是预留的存储结构）
var jlptN4_Data:Dictionary

# 单词本文件路径配置，键为单词本名称，值为对应的CSV文件路径
var wordBookPath:Dictionary={
	"JLPTN5":'res://word/JLPTN5.csv',
	"JLPTN4":'res://word/JLPTN4.csv',
	"JLPTN3":'res://word/JLPTN3.csv',
}

#用于保存错误单词文件路径
var savepath = "user://saveErrorWordData.json"
#用于保存已掌握单词文件路径
var saveMasteredPath = "user://masteredWordData.json"



# 存储所有已加载的单词数据，键为单词本名称，值为该单词本的所有单词数据
var word_data:Dictionary={}

# 当前选择的单词本列表，用于确定游戏中使用的单词范围，默认情况下使用JLPT N5级别单词本
var wordBookList:Array=[
	"JLPTN5",
]




# 当前游戏实际使用的单词本列表（用于检测单词本是否发生变化）
var currentWordBookList:Array=[]

# 当前游戏中所有可用单词的键列表（随机排序后用于出题）
var allCurrentKeys:Array=[]

# 当前游戏中所有可用单词的完整数据字典，键为单词标识，值为单词详细信息
var allCurrentWordData:Dictionary={}

# 历史累计的所有错误单词单词字典（进入下一个关卡就会将数据累计起来）
var allErrorWord:Dictionary

# 历史累计的所有正确单词字典（进入下一个关卡就会将数据累计起来）
var allcorrectWord:Dictionary

# 当前游戏中的错误单词字典，键为单词假名，值为包含单词数据和错误次数的结构
var errorWord:Dictionary  # 存储当前游戏的错误单词，值包含单词数据和错误次数

# 当前游戏中的正确单词字典，键为单词假名，值为单词数据
var correctWord:Dictionary

# 从文件加载的已保存错误单词数组，包含历史错误记录和错误次数
var savedErrorWord:Dictionary  # 存储从文件加载的错误单词，包含错误次数

# 已掌握的单词字典，键为单词假名，值为单词数据（错误次数为0且从错题本移除的单词）
var masteredWord:Dictionary  # 存储已掌握的单词（错误次数为0且从错题本移除）

var needSave:bool = false
func _ready() -> void:
	# 调用方: Godot引擎自动调用
	_loadWord()
	_loadErrorWord()  # 加载已保存的错误单词和已掌握单词数据
	Eventmanger.restartGame.connect(_restartGame)
	Eventmanger.saveErrorWord.connect(func ():
		needSave = true
		)
	Eventmanger.gameover.connect(_clearWord)




func updateWordCount(word:Dictionary, count_change:int):
	var word_key = word.get("假名", "")
	if word_key.is_empty():
		return
	# 根据count_change的值决定增加或减少错误次数,-1为答对题目需要减少错误次数，3为答错题目需要增加错误次数
	match count_change:
		-1:
			#先将正确的单词加入正确列表
			correctWord.set(word_key,word)

			#按照顺序合并错题本。
			var error_lists = [errorWord,allErrorWord,savedErrorWord]
			# 按优先级检查并更新所有错误单词列表
			for error_list in error_lists:
				if error_list.has(word_key):
					var error_word_data = error_list.get(word_key)
					var tempCount =error_word_data.get("error_count",1) 
					tempCount += count_change
					if tempCount <= 0:
						error_list.erase(word_key)
						masteredWord.set(word_key, word) # 添加到已掌握单词列表
					else:
						error_word_data.set("error_count",tempCount)# 如果错误次数小于等于0，从错误列表中移除
		3:		
			#增加错误次数
			#直接添加到当前游戏的错误列表里
			if errorWord.has(word_key):
				var error_word_data = errorWord.get(word_key)
				error_word_data.error_count += count_change
			else:
				var add_data = word.duplicate()
				add_data.set("error_count", count_change)
				errorWord.set(word_key,add_data)


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

			var tempCount = errorWord.get(word_key).get("error_count")+allErrorWord.get(word_key).get("error_count")
			tempErrorWord.set("error_count",tempCount)
			allErrorWord.set(word_key,tempErrorWord)
		else :
			#如果是新的错误单词就直接添加进allErrorWord中。
			allErrorWord.set(word_key,errorWord.get(word_key))


	
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
	# 功能: 保存错误单词和已掌握单词到不同文件
	#先合并allerrorWord和savedErrorWord
	for tempWordKey in allErrorWord:
		var cheackWord = savedErrorWord.get(tempWordKey,null)
		var needSaveWord = allErrorWord.get(tempWordKey)
		#如果该单词重复则累加错误次数
		if cheackWord:
			var tempcount = cheackWord.get("error_count",3)+needSaveWord.get("error_count",3)
			cheackWord.set("error_count",tempcount)
		else:
			#如果是新的错误单词则直接添加进SavedErrorWord
			savedErrorWord.set(tempWordKey,needSaveWord)

	#保存单词
	var errorWordFile = FileAccess.open(savepath, FileAccess.WRITE)
	if errorWordFile:
		var tempjson = JSON.stringify(savedErrorWord, "\t")
		errorWordFile.store_string(tempjson)
		print("错误单词数据已保存，共 %d 个单词" % savedErrorWord.size())
		errorWordFile.close()
	else:
		print("错误单词保存失败")
	# 保存错误单词到文件


	# 保存已掌握的单词到单独的文件
	var masteredFile = FileAccess.open(saveMasteredPath, FileAccess.WRITE)
	if masteredFile:
		var masetredJson = JSON.stringify(masteredWord, "\t")
		masteredFile.store_string(masetredJson)
		print("已掌握单词数据已保存，共 %d 个单词" % masteredWord.size())
		masteredFile.close()
	else:
		print("已掌握单词保存失败")
	print("_saveErrorWord: 保存完成")

func _loadErrorWord():
	# 调用方: menu/menu.gd (第104行)
	# 功能: 从文件加载错误单词和已掌握单词数据
	# 加载错误单词数据
	if FileAccess.file_exists(savepath):
		var errorWordFile = FileAccess.open(savepath,FileAccess.READ)
		if errorWordFile:
			var tempjson = errorWordFile.get_as_text()
			var tempData = JSON.parse_string(tempjson)
			if typeof(tempData) == TYPE_DICTIONARY:
				savedErrorWord = tempData
				print("已加载 %d 个错误单词数据" % savedErrorWord.size())
			else:
				push_error("错误单词数据加载失败")
		errorWordFile.close()
	else:
		print("错误单词保存文件不存在，将创建新文件")
	
	# 加载已掌握单词数据
	if FileAccess.file_exists(saveMasteredPath):
		var masteredWordFile = FileAccess.open(saveMasteredPath, FileAccess.READ)
		if masteredWordFile:
			var mastered_json = masteredWordFile.get_as_text()
			var mastered_parsed = JSON.parse_string(mastered_json)
			if typeof(mastered_parsed) == TYPE_DICTIONARY:
				masteredWord = mastered_parsed
		masteredWordFile.close()
	else:
		print("已掌握保存文件不存在，将创建新文件")

	
		
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
					#如果项目是空，不为空项目设置key和值
					if temp =="":
						continue
					row_dir[head] = temp
				if row_dir.get("假名"):
					tempWordData[row_dir["假名"]] = row_dir
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
	wordBookList=list.duplicate()

func getNextQuestion(type:int = 0):
	var questionData :Dictionary ={}
	
	## 0为普通题目,1为错题插入，2为单词重组。
	#发送题目，正确选项，错误选择
	var tiltle:Dictionary #用于设置题目
	var correctData:Array #用于存放正确选项
	var selectErrorWordData:Array #用于存在错误选项
	var errorButtonCount:int #需要使用的干扰选项数量
	var selectErrorKeys:Array


	var allErrorWordDataDic:Array = [
		errorWord,
		allErrorWord,
		savedErrorWord,
	]
	var uesDic:Dictionary ={}
	#确认是否有错题可以进行错题插入。若无则则使用普通的题目
	if type == 1:
		for i in allErrorWordDataDic:
			if not i.is_empty():
				uesDic = i
				break
	if type == 1 and uesDic =={}:
		type =0
	#确认是否有masteredWord可以进行单词重组，若无则则使用普通的题目
	if type ==2 and masteredWord.is_empty():
		type =1
		for i in allErrorWordDataDic:
			if not i.is_empty():
				uesDic = i
				break
		if type == 1 and uesDic =={}:
			type =0


		


	match type:
		0:
			#设置题目，并添加进tilte
			if allCurrentKeys.size()>= 4:
				var selectTilteKey = allCurrentKeys.pop_back()
				tiltle =allCurrentWordData.get(selectTilteKey)

			else:
				##需要设计题目不足，询问player要重新加载题目还是新增题目。
				pass
			

			#将正确选项放入correctData
			if tiltle.get("日语汉字",null):
				if randi()%2 >=1:
					correctData.append(tiltle.get("日语汉字"))
				else:
					correctData.append(tiltle.get("假名"))
			else:
				correctData.append(tiltle.get("假名"))


			#获取干扰选项key，并添加进selectErrorKeys
			if allCurrentKeys.size() > 3:
				for i in range(3):
					var tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
					while selectErrorKeys.has(tempkey) :
						tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
					selectErrorKeys.append(tempkey)
			elif allCurrentKeys.size() == 3:
				for i in range(3) :
					var tempkey = allCurrentKeys.get(i)
					selectErrorKeys.append(tempkey)
			else:
				##需要设计题目不足，询问player要重新加载题目还是新增题目。
				pass
			#将干扰选项添加进selectErrorWordData
			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i)
				var errorWordStr:String

				#true 设置日语汉字，fales 设置假名
				if tempWordData.get("日语汉字",null):
					if randi()%2 >=1:
						errorWordStr=tempWordData.get("日语汉字")
					else:
						errorWordStr=tempWordData.get("假名")
				else:
					errorWordStr=tempWordData.get("假名")

				selectErrorWordData.append(errorWordStr)
			#检测是否有错误单词，如果有就加入干扰项
			var temp = tiltle.get("容易混淆的单词",null)
			if temp :
				selectErrorWordData.append(temp)
				pass
			errorButtonCount = 3
		
		1:
			#设置题目，并添加进tilte
			var tempKeys = uesDic.keys()
			var tempTiltle :Dictionary= uesDic.get(tempKeys.get(randi()%tempKeys.size()),null)
			if tempTiltle:
				tempTiltle.erase("error_count")
				tiltle = tempTiltle
			else:
				print("无法设置题目")
			
			#将正确选项放入correctData
			if tiltle.get("日语汉字",null):
				if randi()%2 >=1:
					correctData.append(tiltle.get("日语汉字"))
				else:
					correctData.append(tiltle.get("假名"))
			else:
				correctData.append(tiltle.get("假名"))
			
			#获取干扰选项key，并添加进selectErrorKeys
			if allCurrentKeys.size() > 3:
				for i in range(3):
					var tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
					while selectErrorKeys.has(tempkey) :
						tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
					selectErrorKeys.append(tempkey)
			elif allCurrentKeys.size() == 3:
				for i in range(3) :
					var tempkey = allCurrentKeys.get(i)
					selectErrorKeys.append(tempkey)
			else:
				##需要设计题目不足，询问player要重新加载题目还是新增题目。
				pass
			#将干扰选项添加进selectErrorWordData
			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i)
				var tempErrorWord:String

				#true 设置日语汉字，fales 设置假名
				if tempWordData.get("日语汉字",null):
					if randi()%2 >=1:
						tempErrorWord=tempWordData.get("日语汉字")
					else:
						tempErrorWord=tempWordData.get("假名")
				else:
					tempErrorWord=tempWordData.get("假名")

				selectErrorWordData.append(tempErrorWord)

			#检测是否有错误单词，如果有就加入干扰项
			var temp = tiltle.get("容易混淆的单词",null)
			if temp :
				selectErrorWordData.append(temp)
			errorButtonCount = 3
			
		2:
			#设置题目，并添加进tilte
			var tempKeys = masteredWord.keys()
			var tempTiltle :Dictionary= masteredWord.get(tempKeys.get(randi()%tempKeys.size()),null)
			if tempTiltle:
				tiltle = tempTiltle
			else:
				print("无法设置题目")

			#将正确选项放入correctData,先选择要使用汉字还是假名，目标单词拆分存放。
			var targetWord :String
			if tiltle.get("日语汉字",null):
				if randi()%2:
					targetWord = tiltle.get("日语汉字")
				else:
					targetWord = tiltle.get("假名")
			else :
				targetWord = tiltle.get("假名")
			for i in range(targetWord.length()):
				correctData.append(targetWord.substr(i,1))

			#将错误选项放入selectErrorWordData
			#先获取3个错误单词。
			if allCurrentWordData.size()<3:
				##需要设计题目不足，询问player要重新加载题目还是新增题目。
				pass
			for i in range(3):
				var tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
				while  selectErrorKeys.has(tempkey):
					tempkey = allCurrentKeys.get(randi()%allCurrentKeys.size())
			
			var tempWordArray:Array 
			for i in selectErrorKeys:
				var tempWordData = allCurrentWordData.get(i)
				var tempErrorWord:String
				#true 设置日语汉字，fales 设置假名
				if tempWordData.get("日语汉字",null):
					if randi()%2 >=1:
						tempErrorWord=tempWordData.get("日语汉字")
					else:
						tempErrorWord=tempWordData.get("假名")
				else:
					tempErrorWord=tempWordData.get("假名")
				tempWordArray.append(tempErrorWord)
			#将所有汉字或者假名拆分后放入selectErrorWordData
			for i in tempWordArray:
				for y in range(i.length()):
					var tempStr =i.substr(y,1)
					selectErrorWordData.append(tempStr)
			#移除与正确选项相同的字符，避免同一个字符出项多次，且正确与错误不统一。
			for i in correctData:	
				selectErrorWordData.erase(i)
			errorButtonCount = int (selectErrorWordData.size()*0.8)





			


			

	questionData = {
		"type":type,
		"tiltle":tiltle,
		"correctData":correctData,
		"selectErrorWordData":selectErrorWordData,
		"errorButtonCount":errorButtonCount,
	}
	return questionData


	

func _gameStart():
	# 调用方: main/UI/answering.gd (第21行)
	# 功能: 游戏开始时初始化单词数据
	if currentWordBookList != wordBookList:
		currentWordBookList = wordBookList
		allCurrentWordData = sendWordData()
		allCurrentKeys = allCurrentWordData.keys()
		allCurrentKeys.shuffle()
