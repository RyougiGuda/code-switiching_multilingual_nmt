# Train a multilingual transformer model
path_2_data="../../data/code_switching/processed_path"
CUDA_VISIBLE_DEVICES=0 fairseq-train \
    ${path_2_data} \
    --arch transformer   \
    --layernorm-embedding \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 1.0 \
    --share-all-embeddings \
    --lr 2e-4   --lr-scheduler inverse_sqrt --warmup-updates 4000 \
    --dropout 0.4 --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 2048 --update-freq 2 \
    --patience 5 \
    --log-interval 100 \
    --log-format simple --log-file log_1.txt \
    --tensorboard-logdir logs \
    --save-dir ../../model/code_switching/checkpoints
