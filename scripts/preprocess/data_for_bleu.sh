#!/bin/bash
ROOT=../../fairseq
SCRIPT=$ROOT/scripts
SPM_ENCODE=$SCRIPT/spm_encode.py
TRAIN_MINLEN=1  # remove sentences with <1 BPE token
TRAIN_MAXLEN=250  # remove sentences with >250 BPE tokens
data_root="/home/ryougiguda/Projects/multilingual_nmt/data/bleu_single_pair"   # 指定文件夹路径
data_path=$data_root/bleu_raw
tokenized_path=$data_root/tokenized
moses_path=$data_root/moses_path
data_for_bpe_learning=$data_root/data_for_bpe_learning
bpe_path=$data_root/bpe_path
data_code_switching=$data_root/data_code_switching
add_tokens=$data_root/add_tokens
processed_path=$data_root/processed_path
BPE_out="/home/ryougiguda/Projects/multilingual_nmt/data/bpe" #存储学习到的bpe model
moses_decoder="../../requirements/mosesdecoder"
SCRIPTS=$moses_decoder/scripts
TOKENIZER=$SCRIPTS/tokenizer
LC=$SCRIPTS/tokenizer/lowercase.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
LANG_PAIRS=( #actual exist lang pairs
    "es en"
    "ru en"
    "zh en"
    "en fr"
)

first_line=$(head -n 1 stat_bleu.txt)
read -a stats <<< "$first_line" #获取当前已进行过的处理
if [ "${stats:0:1}" == "0" ]; then 
	rm -r ${tokenized_path}
	mkdir ${tokenized_path}
	for PAIR in "${LANG_PAIRS[@]}"; do
		PAIR=($PAIR)
	    	SRC=${PAIR[0]}
	    	TGT=${PAIR[1]}
		f1=IWSLT14.TED.tst2012.${SRC}-${TGT}.${SRC}.xml
		f2=IWSLT14.TED.tst2012.${SRC}-${TGT}.${TGT}.xml
	        out1=${SRC}-${TGT}.${SRC}
	        out2=${SRC}-${TGT}.${TGT}
	        rm $data_path/$out1 $data_path/$out2
	
	        cat $data_path/$f1   | \
	        grep -o '<seg.*</seg>' | \
	        sed -e 's/<[^>]*>//g' > $tokenized_path/$out1
	        echo ""
		        
	        cat $data_path/$f2   | \
	        grep -o '<seg.*</seg>' | \
	        sed -e 's/<[^>]*>//g'  > $tokenized_path/$out2
	        echo ""
	done
fi
if [ "${stats:1:1}" == "0" ]; then 
	echo "processing mosesdecoder perl..."
	rm -r ${moses_path}
	rm -r  ${data_for_bpe_learning}
	mkdir -p ${moses_path}
	mkdir -p ${data_for_bpe_learning}
	for PAIR in "${LANG_PAIRS[@]}"; do 
	    	PAIR=($PAIR)
	    	SRC=${PAIR[0]}
	    	TGT=${PAIR[1]}
		echo "${SRC}-${TGT}"
		for lang in $SRC $TGT; do
			cat "${tokenized_path}/${SRC}-${TGT}.${lang}" | perl ${TOKENIZER}/normalize-punctuation.perl | perl ${TOKENIZER}/tokenizer.perl -a  -l ${lang} > ${moses_path}/${SRC}-${TGT}.tok.${lang}			
  	  		# 如果是中，额外进行一步分词处理
		    	if [ ${lang} = zh ];then
		      		python -m jieba -d " " ${moses_path}/${SRC}-${TGT}.tok.${lang} > ${moses_path}/temp.txt
				mv ${moses_path}/temp.txt ${moses_path}/${SRC}-${TGT}.tok.${lang}
		    	fi
		done

		#(solved)big mistake--this will clean different lines to parallel corpus!! --reason: divided_data forgot to re	move /n in the target language, leads to empty rolls in target language corpus
		perl $CLEAN -ratio 1.5 ${moses_path}/${SRC}-${TGT}.tok $SRC $TGT ${moses_path}/${SRC}-${TGT}.clean 1 175 
		for l in $SRC $TGT; do
			perl $LC < ${moses_path}/${SRC}-${TGT}.clean.$l > ${data_for_bpe_learning}/${SRC}-${TGT}.$l
		done
	done
fi
if [ "${stats:2:1}" == "0" ]; then 
	rm -r ${data_code_switching}
	mkdir -p ${data_code_switching}
	for PAIR in "${LANG_PAIRS[@]}"; do    	
    		PAIR=($PAIR)
   		SRC=${PAIR[0]}
   		TGT=${PAIR[1]}
		for num in 3 4 5 6 ;do
			mkdir -p ${data_code_switching}/code_switching${num}
			python single_code_switching.py --num "${num}" --ratio 0.4 --src "${SRC}" --tgt "${TGT}" 
        		cp $data_for_bpe_learning/${SRC}-${TGT}.${TGT}  ${data_code_switching}/code_switching${num}/${SRC}-${TGT}.${TGT}
		done
		mkdir -p ${data_code_switching}/code_switching0
		cp $data_for_bpe_learning/${SRC}-${TGT}.${SRC}  ${data_code_switching}/code_switching0/${SRC}-${TGT}.${SRC}
		cp $data_for_bpe_learning/${SRC}-${TGT}.${TGT}  ${data_code_switching}/code_switching0/${SRC}-${TGT}.${TGT}
	done
fi
if [ "${stats:3:1}" == "0" ]; then 
	echo "encoding train with learned BPE..."
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
if [ "${stats:4:1}" == "0" ]; then 
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



