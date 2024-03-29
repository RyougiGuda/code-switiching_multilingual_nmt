#!/bin/bash

file1="$1"
file2="$2"
filter_num="$3"
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
    echo "Usage: $0 <file1> <file2>"
    exit 1
fi

# 提取文件名和扩展名
filename1=$(basename "$file1")
filename2=$(basename "$file2")
file_dir=$(dirname "$file1")
extension="${filename1##*.}"

# 组合新文件名
output1="${file_dir}/${filename1%.*}.a.$extension"
output2="${file_dir}/${filename2%.*}.a.$extension"

# 获取 file1 中大于 10 个词的行号，并将行号保存到数组中
mapfile -t lines < <(awk '{ if(NF > ${filter_num}) print NR }' "$file1")

# 将 file1 中大于  n 个词的行写入 output1 文件
awk 'FNR==NR {a[$1]; next} FNR in a' <(printf "%s\n" "${lines[@]}") "$file1" > "$output1"

# 将 file2 中对应行号的行写入 output2 文件
awk 'FNR==NR {a[$1]; next} FNR in a' <(printf "%s\n" "${lines[@]}") "$file2" > "$output2"

echo "Output saved to $output1 and $output2"

