#!/bin/bash
switch_num="$1" #number of words to be switched
decode_stat="$2"
SRC="$3"
TGT="$4"
filter_num="$5"
path_2_data=../../data/bleu_single_pair/add_tokens/add_tokens${switch_num}
out_path=../../evaluate/bleu_single_pair/switching_${switch_num}
data_for_bpe_learning="/home/ryougiguda/Projects/multilingual_nmt/data/baseline/data_for_bpe_learning"
sacrebleu=../../fairseq/scripts/sacrebleu.sh
DETOKENIZER=../../requirements/mosesdecoder/scripts/tokenizer/detokenizer.perl
if [ "${decode_stat}" == "0" ]; then
	rm -r ${out_path}
	mkdir ${out_path}
	if [ "${switch_num}" == "0" ]; then
		path_2_dict=../../data/baseline/processed_path
		fairseq-interactive $path_2_dict \
	  	--input  $path_2_data/${SRC}-${TGT}.${SRC} \
	    	--path ../../model/baseline/checkpoints/checkpoint_best.pt \
    		--source-lang src --target-lang tgt \
		--buffer-size=2000 --batch-size 128 --beam 5 --remove-bpe=sentencepiece >${out_path}/result.txt
	
	else
		path_2_dict=../../data/code_switching/processed_path${switch_num}
		fairseq-interactive $path_2_dict \
	    	--input  $path_2_data/${SRC}-${TGT}.${SRC} \
	    	--path ../../model/code_switching/checkpoints${switch_num}/checkpoint_best.pt \
	    	--source-lang src --target-lang tgt \
	    	--buffer-size=2000 --batch-size 128 --beam 5 --remove-bpe=sentencepiece >${out_path}/result.txt
	fi
	grep ^H ${out_path}/result.txt| cut -f3- > ${out_path}/predict.txt
	cp $data_for_bpe_learning/test.${SRC}-${TGT}.${TGT}  ${out_path}/true.txt

fi

bash filter.sh ${out_path}/predict.txt ${out_path}/true.txt ${filter_num}
${DETOKENIZER}   < ${out_path}/true.a.txt > ${out_path}/true.detok.txt
${DETOKENIZER}   < ${out_path}/predict.a.txt > ${out_path}/predict.detok.txt

sacrebleu ${out_path}/true.detok.txt -i ${out_path}/predict.detok.txt -m bleu -b -w 4
