LANG_PAIRS=( #actual exist lang pairs
    "en fr"
    "fr en"
    "en ru"
    "ru en" 
    "en zh"
    "zh en"
    "es fr"
    "fr es"
)
> bleu_all.txt

for PAIR in "${LANG_PAIRS[@]}"; do    	
    	PAIR=($PAIR)
   	SRC=${PAIR[0]}
  	TGT=${PAIR[1]}
	echo -n "${SRC}-${TGT}" >> bleu_all.txt
	echo -n " " >> bleu_all.txt
	for num in 0 3 4 5 6 ; do
		bleu_scores=$(./interactive.sh ${num} 0 ${SRC} ${TGT} 0 | tail -n 1 )
		 echo -n "$bleu_scores" >> bleu_all.txt
		 echo -n " " >> bleu_all.txt
	echo "" >> bleu_all.txt
	done
done
