#!/bin/bash
ROOT=../../fairseq
SCRIPTS=$ROOT/scripts
data_root="/home/ryougiguda/Projects/multilingual_nmt/data"   # 指定文件夹路径
data_path=$data_root/bleu_raw
bleu_path=$data_root/bleu
add_tokens_path=$data_root/baseline/add_tokens_path #经过add_tokens处理后
merged_path=$data_root/baseline/merged_path #经过merged处理后
BPE_out=$data_root/bpe #存储学习到的bpe model
BPESIZE=40000
moses_decoder="../../requirements/mosesdecoder"
SCRIPTS=$moses_decoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
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

    "es en"
    "ru en"
    "zh en"
    "en fr"
)
for PAIR in "${LANG_PAIRS_real[@]}"; do
	PAIR=($PAIR)
    	SRC=${PAIR[0]}
    	TGT=${PAIR[1]}
	f1=IWSLT14.TED.tst2012.${SRC}-${TGT}.${SRC}.xml
	f2=IWSLT14.TED.tst2012.${SRC}-${TGT}.${TGT}.xml
        out1=test.${SRC}-${TGT}.${SRC}
        out2=test.${SRC}-${TGT}.${TGT}
        rm $data_path/$out1 $data_path/$out2

        cat $data_path/$f1   | \
        grep -o '<seg.*</seg>' | \
        sed -e 's/<[^>]*>//g' | \
        perl $TOKENIZER -threads 8 -l $SRC | \
        python add_tokens.py --tag "<2${TGT}>"   > $bleu_path/$out2 > $bleu_path/${out1}
        echo ""
        
        cat $data_path/$f2   | \
        grep -o '<seg.*</seg>' | \
        sed -e 's/<[^>]*>//g' | \
        perl $TOKENIZER -threads 8 -l $TGT > $bleu_path/$out2
        echo ""
done

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




