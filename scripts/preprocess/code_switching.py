import sys
import os
import argparse
import logging
import shutil

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--num", type=str, help="numbers of phrases to conduct code-swithing", required=True)
    parser.add_argument("--ratio", type=str, help="max ratio of words to be conducted code-switching", required=True)
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
    ratio = args.num #max ratio of words to be conducted code-switching
    dict_file = "/home/ryougiguda/Projects/multilingual_nmt/data/dictionaries/" + tgt + "-" + src + ".0-5000.txt"
    corpus_path= "/home/ryougiguda/Projects/multilingual_nmt/data/baseline/data_for_bpe_learning/" #path of corpus 
    code_switched_path="/home/ryougiguda/Projects/multilingual_nmt/data/code_switching/code_switched_path/" #path of code_switched data 
    if os.path.exists(dict_file)!=True:  #如果没有对应词典，则直接将源文件复制过去
        for f in ["train", "valid", "test"]:
            source_file = corpus_path+f+"."+lang_pairs+"."+src
            destination_file =code_switched_path+f+"."+lang_pairs+"."+src
            shutil.copyfile(source_file, destination_file)
        sys.exit()
    logging.basicConfig(level=logging.DEBUG)
    logging.debug(args)
    code_dict = {} #dictionary

    # 打开文件并逐行读取
    with open(dict_file, "r") as file:
        for line in file:
            # 去除行末的换行符并按空格分割为键值对
            value , key = line.strip().split(None, 1) #以空格或者tab分割，由于字典格式不统一
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
                        leng=len(tokens1)
                        max_len=int(ratio)*leng
                        count = min(int(num),max_len)
                        for i in range(leng):
                            if tokens1[i] in keys_set and code_dict.get(tokens1[i]) in tokens2_set:
                                tokens1[i] = code_dict[tokens1[i]]
                                count -= 1
                            if count == 0:
                                break

                        switched_src = " ".join(tokens1)
                        src_switched.write(switched_src)
                        src_switched.write("\n")
        print("finished switching "+corpus_path+f+"."+lang_pairs+"."+src)

if __name__ == '__main__':
    main()
    
    
    
    
    
    
    

