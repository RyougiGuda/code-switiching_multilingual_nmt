#!/bin/bash
ROOT=../../fairseq
SCRIPT=$ROOT/scripts
SPM_ENCODE=$SCRIPT/spm_encode.py
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens
data_root="/home/ryougiguda/Projects/multilingual_nmt/data/bleu_single_pair"   # 指定文件夹路径
data_for_bpe_learning="/home/ryougiguda/Projects/multilingual_nmt/data/baseline/data_for_bpe_learning"
bpe_path=$data_root/bpe_path
data_code_switching=$data_root/data_code_switching
add_tokens=$data_root/add_tokens
BPE_out="/home/ryougiguda/Projects/multilingual_nmt/data/bpe" #存储学习到的bpe model
LANG_PAIRS=( #actual exist lang pairs
    "en fr"
    "fr en"
    "en ru"
    "ru en" 
    "en zh"
    "zh en"
    "es fr"
    "fr es"
)

first_line=$(head -n 1 stats.txt)
read -a stats <<< "$first_line" #获取当前已进行过的处理

if [ "${stats:0:1}" == "0" ]; then 
	rm -r ${data_code_switching}
	mkdir -p ${data_code_switching}
	for PAIR in "${LANG_PAIRS[@]}"; do    	
    		PAIR=($PAIR)
   		SRC=${PAIR[0]}
   		TGT=${PAIR[1]}
		for num in 3 4 5 6 ;do
			mkdir -p ${data_code_switching}/code_switching${num}
			python single_code_switching.py --num "${num}" --ratio 0.4 --src "${SRC}" --tgt "${TGT}" 
        	
		done
		mkdir -p ${data_code_switching}/code_switching0
		cp $data_for_bpe_learning/test.${SRC}-${TGT}.${SRC}  ${data_code_switching}/code_switching0/${SRC}-${TGT}.${SRC}
	done
fi
if [ "${stats:1:1}" == "0" ]; then 
	rm -r $bpe_path
	mkdir -p $bpe_path
	for PAIR in "${LANG_PAIRS[@]}"; do
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
		echo "encoding test with learned BPE..."
		for num in 0 3 4 5 6 ;do
			mkdir $bpe_path/bpe${num}
			python "$SPM_ENCODE" \
			       	--model "$BPE_out/sentencepiece.bpe.model" \
       				--output_format=piece \
       				--inputs ${data_code_switching}/code_switching${num}/${SRC}-${TGT}.${SRC} ${data_code_switching}/code_switching${num}/${SRC}-${TGT}.${TGT} \
       				--outputs $bpe_path/bpe${num}/${SRC}-${TGT}.bpe.${SRC} $bpe_path/bpe${num}/${SRC}-${TGT}.bpe.${TGT} \
       				--min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN  
		done
	done
fi


#add target language tokens to the head of source languages
if [ "${stats:2:1}" == "0" ]; then 
	echo "processing adding target languages tokens..."
	rm -r $add_tokens
	mkdir -p $add_tokens
	for PAIR in "${LANG_PAIRS[@]}"; do
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
		for num in 0 3 4 5 6 ;do
			mkdir ${add_tokens}/add_tokens${num} 
			cat $bpe_path/bpe${num}/${SRC}-${TGT}.bpe.${SRC} | python add_tokens.py --tag "<2${TGT}>" > ${add_tokens}/add_tokens${num}/${SRC}-${TGT}.${SRC}
			cat $bpe_path/bpe${num}/${SRC}-${TGT}.bpe.${TGT}  > ${add_tokens}/add_tokens${num}/${SRC}-${TGT}.${TGT}
    		done
	done

fi



