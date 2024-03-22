path_2_data=../../data/code_switching/processed_path
out_path=../../evaluate/code_switching
fairseq-generate $path_2_data \
    --path ../../model/code_switching/checkpoints/checkpoint_best.pt \
    --batch-size 128 --beam 5 --remove-bpe >${out_path}/result.txt
    
    

grep ^H ${out_path}/result.txt| cut -f3- > ${out_path}/predict.txt
grep ^T ${out_path}/result.txt| cut -f2- > ${out_path}/true.txt

