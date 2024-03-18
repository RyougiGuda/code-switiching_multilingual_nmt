#对于双语词典进行简繁转换

import opencc

# 创建 OpenCC 实例
cc = opencc.OpenCC('t2s')

# 输入路径和输出路径
path = "/home/ryougiguda/Projects/multilingual_nmt/data/dictionaries/"
converted_path = "/home/ryougiguda/Projects/multilingual_nmt/data/converted_dictionaries/"

# 定义转换函数
def convert(line, p):
    tokens = line.strip().split(" ")
    simp = cc.convert(tokens[p])
    tokens[p] = simp
    if tokens[0]==tokens[1]:
    	return ""
    tokens[1] += "\n"
    return " ".join(tokens)

texts = ["", ".0-5000", ".5000-6500"]
for i in texts:
    with open(path + "zh-en" + i + ".txt", "r") as input1, open(converted_path + "zh-en" + i + ".txt", "w") as output1:
        for line in input1:
            converted_line = convert(line, 0)
            output1.write(converted_line)

    with open(path + "en-zh" + i + ".txt", "r") as input2, open(converted_path + "en-zh" + i + ".txt", "w") as output2:
        for line in input2:
            converted_line = convert(line, 1)
            output2.write(converted_line)

