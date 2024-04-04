# Train a multilingual transformer model
path_2_data="../../data/code_switching/processed_path6"
CUDA_VISIBLE_DEVICES=0 fairseq-train \
    ${path_2_data} \
    --arch transformer   \
    --layernorm-embedding \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 1.0 \
    --share-all-embeddings \
    --lr 5e-6 \
    --dropout 0.4 --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 2048 --update-freq 2 \
    --patience 3 \
    --log-interval 100 \
    --log-format simple --log-file log_4.txt \
    --tensorboard-logdir logs4 \
    --save-dir ../../model/code_switching/checkpoints6
