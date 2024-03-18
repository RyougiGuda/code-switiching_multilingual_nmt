# Train a multilingual transformer model
path_2_data="../data/code_switching/processed_path"
CUDA_VISIBLE_DEVICES=0 fairseq-train \
    ${path_2_data} \
    --arch transformer -share-decoder-input-output-embed  \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 1.0 \
    --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
    --dropout 0.2 --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 1000 --update-freq 3 \
    --log-format simple --log-file log_switching.txt --save-dir ../../model/code_switching/checkpoints
