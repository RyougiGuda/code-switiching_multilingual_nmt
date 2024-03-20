import sys
import os
import argparse
import logging

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--num", type=str, help="numbers of phrases to conduct code-swithing", required=True)
    parser.add_argument("--src", type=str, help="source language", required=True)
    parser.add_argument("--tgt", type=str, help="target language", required=True)
    args = parser.parse_args()
    return args

def main():
    args = parse_args()
    src = args.src
    tgt = args.tgt
    lang_pairs=src+"-"+tgt
    num = args.num #numbers of phrases to conduct code-switching 
    dict_file = "/home/ryougiguda/Projects/multilingual_nmt/all_test/dictionaries/" + tgt + "-" + src + ".5000-6500.txt"
    corpus_path= "/home/ryougiguda/Projects/multilingual_nmt/all_test/" #path of corpus 
    code_switched_path="/home/ryougiguda/Projects/multilingual_nmt/all_test/data_code_switching/" #path of code_switched data 
    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)
    code_dict = {} #dictionary

    # 打开文件并逐行读取
    with open(dict_file, "r") as file:
        for line in file:
            # 去除行末的换行符并按空格分割为键值对
            value , key = line.strip().split(" ")
            # 将键值对添加到字典中
            code_dict[key] = value
    keys_set = set(code_dict.keys()) #使用集合存放字典的键加快查找速度
    for f in ["train","valid","test"]:
    	if os.path.exists(corpus_path+f+"."+lang_pairs+"."+src):
    		print(corpus_path+f+"."+lang_pairs+"."+src)
    		with open(corpus_path+f+"."+lang_pairs+"."+src, "r") as src_corpus, \
       		     open(corpus_path+f+"."+lang_pairs+"."+tgt, "r") as tgt_corpus , \
       		     open(code_switched_path+f+"."+lang_pairs+"."+src, "w") as src_switched :
       			for src_line in src_corpus:
       	        		tgt_line = tgt_corpus.readline()
       	        		tokens1 = src_line.strip().split(" ")
        	       		tokens2 = tgt_line.strip().split(" ")
        	       		tokens2_set = set(tokens2)
        	       		count = int(num)
        	       		for i in range(len(tokens1)):
        	       		    if tokens1[i] in keys_set and code_dict.get(tokens1[i]) in tokens2_set:
        	       		        tokens1[i] = code_dict[tokens1[i]]
        	       		        count -= 1
        	       		    if count == 0:
                		        break
       	        		print("aaaaaa")
       	        		switched_src = " ".join(tokens1)
       	        		src_switched.write(switched_src)
       	        		src_switched.write("\n")
	

if __name__ == '__main__':
    main()
    
    
    
    
    
    
    

