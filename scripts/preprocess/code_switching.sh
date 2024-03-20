#!/bin/bash
ROOT=../../fairseq
SCRIPTS=$ROOT/scripts
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens
data_root="/home/ryougiguda/Projects/multilingual_nmt/data"   # 指定文件夹路径
data_for_bpe_learning=$data_root/baseline/data_for_bpe_learning #经过初步处理后，用于bpe学习
data_code_switching=$data_root/code_switching/code_switched_path #经过code-switching后
bpe_path=$data_root/code_switching/bpe_path #经过bpe处理后
add_tokens_path=$data_root/code_switching/add_tokens_path #经过add_tokens处理后
merged_path=$data_root/code_switching/merged_path #经过merged处理后
processed_path=$data_root/code_switching/processed_path #经过preprocess函数处理后
BPE_out=$data_root/bpe #存储学习到的bpe model
BPESIZE=40000
moses_decoder="../../requirements/mosesdecoder"
SCRIPTS=$moses_decoder/scripts
TOKENIZER=$SCRIPTS/tokenizer
LC=$SCRIPTS/tokenizer/lowercase.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
LANG_PAIRS=(  #双向的数据。是对真实数据创建了一个反向命名的索引 
    #"ar de"
    #"de ar" 由于ar采取右对齐，数据处理上存在问题，暂时放弃这个数据集
    "en fr"
    "fr en"
    "en ru"
    "ru en" 
    "en zh"
    "zh en"
    "es fr"
    "fr es"
)
LANG_PAIRS_real=( #actual exist lang pairs
    #"ar de"
    "en fr"
    "en ru"
    "en zh"
    "es fr"
)
# 打开文件并读取第一行内容
first_line=$(head -n 1 stats_code.txt)
read -a stats <<< "$first_line" #获取当前已进行过的处理

if [ "${stats:0:1}" == "0" ]; then 
	rm -r ${data_code_switching}
	mkdir -p ${data_code_switching}
	for PAIR in "${LANG_PAIRS[@]}"; do    		
    		code_num=3
    		max_ratio=0.4
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
		python code_switching.py --num "${code_num}" --ratio "${max_ratio}" --src "${SRC}" --tgt "${TGT}" 
		cp $data_for_bpe_learning/train.${SRC}-${TGT}.${TGT}  $data_code_switching/train.${SRC}-${TGT}.${TGT}
        	cp $data_for_bpe_learning/valid.${SRC}-${TGT}.${TGT}  $data_code_switching/valid.${SRC}-${TGT}.${TGT}
        	cp $data_for_bpe_learning/test.${SRC}-${TGT}.${TGT}  $data_code_switching/test.${SRC}-${TGT}.${TGT}
	done
fi
	
# encode train/valid/test
if [ "${stats:1:1}" == "0" ]; then 
	echo "encoding train with learned BPE..."
	rm -r $bpe_path
    	mkdir -p $bpe_path
	for PAIR in "${LANG_PAIRS[@]}"; do
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}

		for f in train valid test;do 
			echo "encoding $f with learned BPE..."
			python "$SPM_ENCODE" \
        		--model "$BPE_out/sentencepiece.bpe.model" \
        		--output_format=piece \
        		--inputs $data_code_switching/$f.${SRC}-${TGT}.${SRC} $data_code_switching/$f.${SRC}-${TGT}.${TGT} \
        		--outputs $bpe_path/$f.${SRC}-${TGT}.bpe.${SRC} $bpe_path/$f.${SRC}-${TGT}.bpe.${TGT} \
        		--min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN  
		done
	done

fi
#add target language tokens to the head of source languages
if [ "${stats:2:1}" == "0" ]; then 
	echo "processing adding target languages tokens..."
	rm -r $add_tokens_path
	mkdir -p $add_tokens_path
	for PAIR in "${LANG_PAIRS[@]}"; do
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
		for f in train valid test;do 
			cat $bpe_path/$f.${SRC}-${TGT}.bpe.${SRC} | python add_tokens.py --tag "<2${TGT}>" > $add_tokens_path/$f.${SRC}-${TGT}.${SRC}
			cat $bpe_path/$f.${SRC}-${TGT}.bpe.${TGT}  > $add_tokens_path/$f.${SRC}-${TGT}.${TGT}
    		done
	done

fi


#merge all language-pairs' corpus to build a single mixed corpus
if [ "${stats:3:1}" == "0" ]; then 
	rm -r $merged_path
	mkdir -p $merged_path
	for PAIR in "${LANG_PAIRS[@]}"; do  
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
    		for f in train valid test;do
 		      cat $add_tokens_path/${f}.${SRC}-${TGT}.${SRC}  >> $merged_path/${f}.src
 	        cat $add_tokens_path/${f}.${SRC}-${TGT}.${TGT}  >> $merged_path/${f}.tgt
 	      done
 	done


fi
if [ "${stats:4:1}" == "0" ]; then
  echo "processing combining datasets"
  rm -r $processed_path
  mkdir -p $processed_path
  #不确定在上一步混合数据集时是否需要对于test集进行相同操作，由于如果不混合test集在下一步process将需要单独遍历每个文件，因此选择合并。
  #mkdir -p $processed_path/test_data
  #cp -r "$add_tokens_path/test.*" "processed_pathtest_data" #将test集转移进处理好的数据路径中
  fairseq-preprocess --source-lang src --target-lang tgt \
      --trainpref $merged_path/train \
      --validpref $merged_path/valid \
      --testpref $merged_path/test \
      --destdir $processed_path \
      --workers 10 \
      --joined-dictionary
fi








