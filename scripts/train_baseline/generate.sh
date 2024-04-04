#!/bin/bash
decode_stat="$1"
filter_num="$2"
path_2_data=../../data/baseline/processed_path
out_path=../../evaluate/baseline
sacrebleu=../../fairseq/scripts/sacrebleu.sh
DETOKENIZER=../../requirements/mosesdecoder/scripts/tokenizer/detokenizer.perl

if [ "${decode_stat}" == "0" ]; then
	rm -r ${out_path}
	mkdir ${out_path}
	fairseq-generate $path_2_data \
	    --path ../../model/baseline/checkpoints/checkpoint_best.pt \
	    --batch-size 128 --beam 5 --remove-bpe=sentencepiece >${out_path}/result.txt
	grep ^H ${out_path}/result.txt| cut -f3- > ${out_path}/predict.txt
	grep ^T ${out_path}/result.txt| cut -f2- > ${out_path}/true.txt
	rm ${out_path}/result.txt
fi

bash filter.sh ${out_path}/predict.txt ${out_path}/true.txt ${filter_num}
${DETOKENIZER}   < ${out_path}/true.a.txt > ${out_path}/true.detok.txt
${DETOKENIZER}   < ${out_path}/predict.a.txt > ${out_path}/predict.detok.txt

sacrebleu ${out_path}/true.detok.txt -i ${out_path}/predict.detok.txt -m bleu -b -w 4
