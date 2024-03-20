data_root="/home/ryougiguda/Projects/multilingual_nmt/all_test"   # 指定文件夹路径
data_for_bpe_learning=$data_root  #初步分词后
data_code_switching=$data_root/data_code_switching #转码后
dict_path=$data_root/dictionaries #转码用字典

LANG_PAIRS=(  #双向的数据。是对真实数据创建了一个反向命名的索引 
    "en zh"
    "zh en"
)

rm -r ${data_code_switching}
mkdir -p ${data_code_switching}
for PAIR in "${LANG_PAIRS[@]}"; do
    	echo "start"
    	
    	code_num=2
    	PAIR=($PAIR)
    	SRC=${PAIR[0]}
    	TGT=${PAIR[1]}
	python test_code_switching.py --num "${code_num}" --src "${SRC}" --tgt "${TGT}" 
	cp $data_for_bpe_learning/train.${SRC}-${TGT}.${TGT}  $data_code_switching/train.${SRC}-${TGT}.${TGT}
        cp $data_for_bpe_learning/valid.${SRC}-${TGT}.${TGT}  $data_code_switching/valid.${SRC}-${TGT}.${TGT}
        cp $data_for_bpe_learning/test.${SRC}-${TGT}.${TGT}  $data_code_switching/test.${SRC}-${TGT}.${TGT}
      
       		
  
       	echo "end"

done

