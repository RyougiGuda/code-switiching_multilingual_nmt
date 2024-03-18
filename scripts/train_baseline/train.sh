# Train a multilingual transformer model
path_2_data="../data/baseline/processed_path"
CUDA_VISIBLE_DEVICES=0 fairseq-train \
    ${path_2_data} \
    --arch transformer   \
    --layernorm-embedding \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 1.0 \
    --share-all-embeddings \
    --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
    --dropout 0.2 --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 1000 --update-freq 3 \
    --log-format simple --log-file log2.txt --save-dir ../../model/baseline/checkpoints
