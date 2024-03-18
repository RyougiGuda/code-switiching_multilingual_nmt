import os
import random
import pandas as pd

# 输入文件夹路径和输出文件夹路径
input_folder = "../data/raw"
output_folder = "../data/divided_data"

# 遍历文件夹中的每个文件
for filename in os.listdir(input_folder):
    # 检查文件是否是TSV文件
    if filename.endswith(".tsv"):
        input_file = os.path.join(input_folder, filename)
        output_prefix = os.path.join(output_folder, filename[:-4])  #去除.tsv后缀
        lang1= output_prefix.split("-")[0][-2:]
        lang2= output_prefix.split("-")[1]
        output_prefix = output_prefix[:-5] #提取目标路径
        # 打开输入文件并进行处理
        with open(input_file, "r", encoding="utf-8") as f_input, \
             open(output_prefix +"test."+lang1+"-"+lang2+"."+lang1, "w", encoding="utf-8") as test_lang1, \
             open(output_prefix +"test."+lang1+"-"+lang2+"."+lang2, "w", encoding="utf-8") as test_lang2, \
             open(output_prefix +"train."+lang1+"-"+lang2+"."+lang1, "w", encoding="utf-8") as train_lang1, \
             open(output_prefix +"train."+lang1+"-"+lang2+"."+lang2, "w", encoding="utf-8") as train_lang2, \
             open(output_prefix +"valid."+lang1+"-"+lang2+"."+lang1, "w", encoding="utf-8") as valid_lang1, \
             open(output_prefix +"valid."+lang1+"-"+lang2+"."+lang2, "w", encoding="utf-8") as valid_lang2:
            # 读取原始文件的所有行，并随机打乱顺序
            lines=f_input.readlines()
           
            random.shuffle(lines)
            total_lines=len(lines)
            used_percentage=0.4 #只取原数据集的0.4,减小数据集大小加快训练
            total_lines=total_lines*used_percentage
            # 计算每份数据的大小
            train_size = int(0.7 * total_lines)
            test_size = int(0.2 * total_lines)
            valid_size = int(0.5 * test_size)
            # 分割点索引位置
            split_point1 = train_size
            split_point2 = train_size + test_size
            for idx,line in enumerate(lines):
                line = line.strip()
                if '\t' in line:
                    # 假设双语语料库文件中源语言和目标语言之间使用制表符分隔
                    lang1_part, lang2_part = line.split("\t")  
                    lang2_part = lang2_part.rstrip("\n") #去除目标语言结尾自带的换行符！！      
                    if idx < split_point1:
                        train_lang1.write(lang1_part + "\n")
                        train_lang2.write(lang2_part + "\n")
                    elif idx < split_point2:
                        test_lang1.write(lang1_part + "\n")
                        test_lang2.write(lang2_part + "\n")
                    elif idx > split_point2 and idx < total_lines:
                        valid_lang1.write(lang1_part + "\n")
                        valid_lang2.write(lang2_part + "\n")
                    

        print(f"Processed file: {filename}")

