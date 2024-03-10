#!/bin/bash

set -e
ROOT=../fairseq
SCRIPTS=$ROOT/scripts
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens
# 指定文件夹路径
data_path="../data/divided_data"
moses_path="../data/moses_path" #经过mosesdecoder处理后
bpe_path="../data/bpe_path" #经过bpe处理后
BPE="../data/bpe" #bpe_folder
BPESIZE=16384
processed_path="../data/processed_path"
moses_decoder=../requirements/mosesdecoder
lang1=("ar" "de") 
lang2=("de" "ru")
lang3=("en" "fr")
lang4=("en" "ru")
lang5=("en" "zh")
lang6=("es" "fr")
LANG_PAIRS+=("${lang1[@]}")
LANG_PAIRS+=("${lang2[@]}")
LANG_PAIRS+=("${lang3[@]}")
LANG_PAIRS+=("${lang4[@]}")
LANG_PAIRS+=("${lang5[@]}")
LANG_PAIRS+=("${lang6[@]}")





# 循环读取文件夹中的文件名
#for file in "$data_path"/*; do
#        # 获取文件名（不包含路径）
#	filename=$(basename "$file")
#       # 提取文件名中源语言sl和目标语言tl数据
#      sl=$(echo "$filename" | cut -d'_' -f2 | cut -d'-' -f1)
#     tl=$(echo "$filename" | cut -d'-' -f2 | cut -d'.' -f1)
#	# 将源语言和目标语言添加到LANG_PAIRS数组
#  	LANG_PAIR=("$sl" "$tl")
# 	LANG_PAIRS+=("$LANG_PAIR")
#       
#done

: '
for ((i=0; i<${#LANG_PAIRS[@]}; i+=2)); do
	sl="${LANG_PAIRS[i]}"
    	tl="${LANG_PAIRS[i+1]}"
	lp="$sl-$tl"
	echo "$lp"
	for lang in $sl $tl; do
  		for f in train valid test ;do
    			perl ${moses_decoder}/scripts/tokenizer/tokenizer.perl -l ${lang} < ${data_path}/${f}.${lp}.${lang} > ${moses_path}/${f}.${lp}.${lang}
    		# 如果是中，额外进行一步分词处理
    		if [ ${lang} = zh ];then
      			python -m jieba -d " " ${data_path}/${f}.${lp}.${lang} > ${moses_path}/temp.txt
      			mv ${moses_path}/temp.txt ${moses_path}/${f}.${lp}.${lang}
    		fi
		done
	done
done
# 扫描是否有已学习好的bpe，无则执行训练脚本
if [ -z "$(ls -A $BPE)" ]; then
    echo "无已训练bpe,正在训练新的bpe"
    TRAIN_FILES=$(find "$moses_path" -type f  -exec echo -n "{}," \; | sed 's/,$//')
	echo "learning joint BPE over ${TRAIN_FILES}..."
	python "$SPM_TRAIN" \
        	--input=$TRAIN_FILES \
        	--model_prefix=$BPE/sentencepiece.bpe \
        	--vocab_size=$BPESIZE \
        	--character_coverage=1.0 \
        	--model_type=bpe
	echo "complete bpe learining!"                             
else
    echo "有已训练bpe，将用其处理数据集"
fi

# encode train/valid/test
echo "encoding train with learned BPE..."

for ((i=0; i<${#LANG_PAIRS[@]}; i+=2)); do
        SRC="${LANG_PAIRS[i]}"
        TGT="${LANG_PAIRS[i+1]}"

	python "$SPM_ENCODE" \
        	--model "$BPE/sentencepiece.bpe.model" \
        	--output_format=piece \
        	--inputs $moses_path/train.${SRC}-${TGT}.${SRC} $moses_path/train.${SRC}-${TGT}.${TGT} \
        	--outputs $bpe_path/train.bpe.${SRC}-${TGT}.${SRC} $bpe_path/train.bpe.${SRC}-${TGT}.${TGT} \
        	--min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN
done
for ((i=0; i<${#LANG_PAIRS[@]}; i+=2)); do
        SRC="${LANG_PAIRS[i]}"
        TGT="${LANG_PAIRS[i+1]}"

	for f in train valid test;do 
		echo "encoding $f with learned BPE..."
		python "$SPM_ENCODE" \
        	--model "$BPE/sentencepiece.bpe.model" \
        	--output_format=piece \
        	--inputs $moses_path/$f.${SRC}-${TGT}.${SRC} $moses_path/$f.${SRC}-${TGT}.${TGT} \
        	--outputs $bpe_path/$f.bpe.${SRC}-${TGT}.${SRC} $bpe_path/$f.bpe.${SRC}-${TGT}.${TGT} \
        	--min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN
	done
done
'
# use tricks for creating a joined dictionary
# strip the first three special tokens and append fake counts for each vocabulary
cut -f1 $BPE/sentencepiece.bpe.vocab  | tail -n +4 | sed 's/$/ 100/g' > dict.txt
#fairseq-preprocess
for ((i=0; i<${#LANG_PAIRS[@]}; i+=2)); do
        SRC="${LANG_PAIRS[i]}"
        TGT="${LANG_PAIRS[i+1]}"

	fairseq-preprocess --source-lang $SRC --target-lang $TGT \
		--trainpref $bpe_path/train.bpe.$SRC-$TGT  \
	    	--validpref $bpe_path/valid.bpe.$SRC-$TGT  \
    		--testpref $bpe_path/test.bpe.$SRC-$TGT    \
    		--destdir $processed_path		   \
		--srcdict dict.txt    \
		--tgtdict dict.txt	   \
    		--workers 10 
done
