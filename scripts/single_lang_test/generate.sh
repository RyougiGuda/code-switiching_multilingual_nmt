path_2_data=../../data/single_lang_test/processed_path
MULTI_BLEU=../../requirements/mosesdecoder/scripts/generic/multi-bleu.perl

fairseq-generate $path_2_data \
    --path ../../model/single_lang_test/checkpoints/checkpoint_best.pt \
    --batch-size 256 --beam 5 --remove-bpe >result.txt
    
    



