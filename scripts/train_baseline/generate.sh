path_2_data=../../data/baseline/processed_path
out_path=../../evaluate/baseline
fairseq-generate $path_2_data \
    --path ../../model/baseline/checkpoints/checkpoint_best.pt \
    --batch-size 128 --beam 5 --remove-bpe=sentencepiece >${out_path}/result.txt
    
    

grep ^H ${out_path}/result.txt| cut -f3- > ${out_path}/predict.txt
grep ^T ${out_path}/result.txt| cut -f2- > ${out_path}/true.txt

