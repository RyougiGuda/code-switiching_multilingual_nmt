sacrebleu=../../fairseq/scripts/sacrebleu.sh
out_path=../../evaluate/baseline   
DETOKENIZER=../../requirements/mosesdecoder/scripts/tokenizer/detokenizer.perl


${DETOKENIZER}   < ${out_path}/true.a.txt > ${out_path}/true.detok.txt
${DETOKENIZER}   < ${out_path}/predict.a.txt > ${out_path}/predict.detok.txt
sacrebleu ${out_path}/true.detok.txt -i ${out_path}/predict.detok.txt -m bleu -b -w 4


