path_2_data=../data/code_switching/processed_path

fairseq-generate $path_2_data \
    --path switched_checkpoints/checkpoint_best.pt \
    --batch-size 128 --beam 5 --remove-bpe >switched_result.txt
