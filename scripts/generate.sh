model=<multilingual model>
source_lang=<source language>
target_lang=<target language>
lang_pairs="ar-de,de-ru,en-fr,en-ru,en-zh,es-fr"
lang_list=../data/lang_list.txt



fairseq-generate $path_2_data \
  --path $model \
  --task translation_multi_simple_epoch \
  --gen-subset test \
  --source-lang $source_lang \
  --target-lang $target_lang
  --sacrebleu --remove-bpe 'sentencepiece'\
  --batch-size 32 \
  --encoder-langtok "src" \
  --decoder-langtok \
  --lang-dict "$lang_list" \
  --lang-pairs "$lang_pairs" > ${source_lang}_${target_lang}.txt