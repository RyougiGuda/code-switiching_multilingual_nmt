#!/bin/bash
ROOT=../fairseq
SCRIPTS=$ROOT/scripts
SPM_TRAIN=$SCRIPTS/spm_train.py
SPM_ENCODE=$SCRIPTS/spm_encode.py
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens
data_root="/home/ryougiguda/Projects/multilingual_nmt/data"   # 指定文件夹路径
data_path=$data_root/divided_data #最初经过对raw数据进行分解后得到的数据
symlink_path=$data_root/symlink_path #经过symlink处理之后的双向数据
moses_path=$data_root/moses_path #经过mosesdecoder处理后
bpe_path=$data_root/bpe_path #经过bpe处理后
add_tokens_path=$data_root/add_tokens_path #经过add_tokens处理后
merged_path=$data_root/merged_path #经过merged处理后
processed_path=$data_root/processed_path #经过preprocess函数处理后
BPE_out=$data_root/bpe #存储学习到的bpe model
BPEROOT="../requirements/subword-nmt"
BPESIZE=35000
moses_decoder="../requirements/mosesdecoder"
data_for_bpe_learning=$data_root/data_for_bpe_learning
SCRIPTS=$moses_decoder/scripts
TOKENIZER=$SCRIPTS/tokenizer
LC=$SCRIPTS/tokenizer/lowercase.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
LANG_PAIRS=(  #双向的数据。是对真实数据创建了一个反向命名的索引 
    #"ar de"
    #"de ar" 由于ar采取右对齐，数据处理上存在问题，暂时放弃这个数据集
    "de ru"
    "ru de"
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
    "de ru"
    "en fr"
    "en ru"
    "en zh"
    "es fr"
)

# 打开文件并读取第一行内容
first_line=$(head -n 1 stats.txt)
read -a stats <<< "$first_line" #获取当前已进行过的处理


#We first create symlinks for the reverse training directions, i.e. EN-DE and EN-IT:
if [ "${stats:0:1}" == "0" ]; then  #判断是否已执行过
  echo "processing symlinks..."
  rm -r ${symlink_path}
  mkdir -p ${symlink_path}
  cp -r "$data_path"/* "${symlink_path}"
	for PAIR in "${LANG_PAIRS_real[@]}"; do
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
    		for LANG in "${SRC}" "${TGT}"; do
        		for f in train valid test; do
        		    ln -s ${symlink_path}/${f}.${SRC}-${TGT}.${LANG} ${symlink_path}/${f}.${TGT}-${SRC}.${LANG}
        		done
    		done
    	done

fi



if [ "${stats:1:1}" == "0" ]; then  #判断是否已执行过
	echo "processing mosesdecoder perl..."
	rm -r ${moses_path}
	rm -r  ${data_for_bpe_learning}
	mkdir -p ${moses_path}
	mkdir -p ${data_for_bpe_learning}
	for PAIR in "${LANG_PAIRS[@]}"; do #虽然这样会将同样的数据处理两遍，但是目的是将虚拟的索引变成真实存在的两个文件输出到下一个文件夹
    		PAIR=($PAIR)
    		SRC=${PAIR[0]}
    		TGT=${PAIR[1]}
		echo "${SRC}-${TGT}"
		for lang in $SRC $TGT; do
	  		for f in train valid test ;do
	    			cat "${symlink_path}/${f}.${SRC}-${TGT}.${lang}" | perl ${TOKENIZER}/normalize-punctuation.perl | perl ${TOKENIZER}/tokenizer.perl -a -q -l ${lang} > ${moses_path}/${f}.${SRC}-${TGT}.tok.${lang}
	    			
	    		# 如果是中，额外进行一步分词处理
	    		if [ ${lang} = zh ];then
	      			python -m jieba -d " " ${moses_path}/${f}.${SRC}-${TGT}.tok.${lang} > ${moses_path}/temp.txt
	      			mv ${moses_path}/temp.txt ${moses_path}/${f}.${SRC}-${TGT}.tok.${lang}
	    		fi
			done
		done
		#(solved)big mistake--this will clean different lines to parallel corpus!! --reason: divided_data forgot to remove /n in the target language, leads to empty rolls in target language corpus
		for f in train valid test ;do
			perl $CLEAN -ratio 1.5 ${moses_path}/${f}.${SRC}-${TGT}.tok $SRC $TGT ${moses_path}/${f}.${SRC}-${TGT}.clean 1 175 
		done
		for f in train valid test ;do
			for l in $SRC $TGT; do
	        		perl $LC < ${moses_path}/${f}.${SRC}-${TGT}.clean.$l > ${data_for_bpe_learning}/${f}.${SRC}-${TGT}.$l
	    		done
	    	done	
	done

fi

# 扫描是否有已学习好的bpe，无则执行训练脚本
if [ "${stats:2:1}" == "0" ]; then 
    rm -r $BPE_out  
    mkdir -p $BPE_out
    echo "无已训练bpe,正在训练新的bpe"
    TRAIN_FILES=$(find "$data_for_bpe_learning" -type f -exec echo -n "{}," \; | sed 's/,$//')
    echo "learning joint BPE over ${TRAIN_FILES}..."
    python "$SPM_TRAIN" \
       	--input=$TRAIN_FILES  \
       	--model_prefix=$BPE_out/sentencepiece.bpe \
       	--vocab_size=$BPESIZE \
       	--character_coverage=1.0 \
       	--model_type=bpe
    echo "complete bpe learining!"

else
    echo "有已训练bpe，将用其处理数据集"
fi


# encode train/valid/test
if [ "${stats:3:1}" == "0" ]; then 
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
        		--inputs $data_for_bpe_learning/$f.${SRC}-${TGT}.${SRC} $data_for_bpe_learning/$f.${SRC}-${TGT}.${TGT} \
        		--outputs $bpe_path/$f.${SRC}-${TGT}.bpe.${SRC} $bpe_path/$f.${SRC}-${TGT}.bpe.${TGT} \
        		--min-len $TRAIN_MINLEN --max-len $TRAIN_MAXLEN  
		done
	done

fi
#add target language tokens to the head of source languages
if [ "${stats:4:1}" == "0" ]; then 
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


if [ "${stats:6:1}" == "0" ]; then
  echo "processing combining datasets"
  rm -r $processed_path
  mkdir -p $processed_path
  #不确定在上一步混合数据集时是否需要对于test集进行相同操作，由于如果不混合test集在下一步process将需要单独遍历每个文件，因此选择合并。
  #mkdir -p $processed_path/test_data
  #cp -r "$add_tokens_path/test.*" "processed_pathtest_data" #将test集转移进处理好的数据路径中

  fairseq-preprocess \
      --trainpref $add_tokens_path/train \
      --validpref $add_tokens_path/valid \
      --testpref $add_tokens_path/test \
      --destdir ${data_root}/processed_path_not_merged \
      --workers 10 \
      --joined-dictionary


fi






