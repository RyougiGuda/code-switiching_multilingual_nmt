path_2_data=../data/baseline/processed_path


fairseq-generate $path_2_data \
    --path checkpoints/checkpoint_best.pt \
    --batch-size 128 --beam 5 --remove-bpe >result.txt
