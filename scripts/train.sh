# Train a multilingual transformer model
path_2_data="../data/processed_path"
lang_pairs="ar-de,de-ru,en-fr,en-ru,en-zh,es-fr"
lang_list=../data/lang_list.txt

fairseq-train "$path_2_data" \
  --encoder-normalize-before --decoder-normalize-before \
  --arch transformer --layernorm-embedding \
  --task translation_multi_simple_epoch \
  --sampling-method "temperature" \
  --sampling-temperature 1.5 \
  --encoder-langtok "src" \
  --decoder-langtok \
  --lang-dict "$lang_list" \
  --lang-pairs "$lang_pairs" \
  --criterion label_smoothed_cross_entropy --label-smoothing 0.2 \
  --optimizer adam --adam-eps 1e-06 --adam-betas '(0.9, 0.98)' \
  --lr-scheduler inverse_sqrt --lr 3e-05 --warmup-updates 2500  \
  --dropout 0.3 --attention-dropout 0.1 --weight-decay 0.0 \
  --max-tokens 2048 --update-freq 2 \
  --save-interval 1 --save-interval-updates 5000 --keep-interval-updates 10 --no-epoch-checkpoints \
  --seed 222 --log-format simple --log-interval 2 --save-dir ../model
