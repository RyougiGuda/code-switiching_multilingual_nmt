
path_2_data=../../data/bleu
out_path=../../evaluate/code_switching
processed_path=../../data/code_switching/processed_path 
SPM_ENCODE=$SCRIPTS/spm_decode.py
fairseq-interactive $processed_path \
    --path ../../model/code_switching/checkpoints3/checkpoint_best.pt \
    --input ${path_2_data}/test.zh-en.zh \
    --buffer-size 2000 --batch-size 128 --beam 5 --remove-bpe=sentencepiece >${out_path}/result_interactive.txt
    
    

grep ^H ${out_path}/result_interactive.txt| cut -f3- > ${out_path}/predict_interactive.txt
grep ^T ${out_path}/result_interactive.txt| cut -f2- > ${out_path}/true_interactive.txt
#rm ${out_path}/result_interactive.txt
