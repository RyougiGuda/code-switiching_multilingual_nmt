path_2_data=../../data/baseline/processed_path

fairseq-generate $path_2_data \
    --path ../../model/baseline/checkpoints/checkpoint_best.pt \
    --batch-size 128 --beam 5 --remove-bpe >result.txt
    
    

grep ^H result.txt| cut -f3- > predict.txt
grep ^T result.txt| cut -f2- > true.txt

