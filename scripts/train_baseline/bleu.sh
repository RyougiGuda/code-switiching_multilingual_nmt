MULTI_BLEU=../../requirements/mosesdecoder/scripts/generic/multi-bleu.perl

 out_path=../../evaluate/baseline   

${MULTI_BLEU} -lc ${out_path}/true.txt < ${out_path}/predict.txt

