#!/bin/bash

# 初始化变量
i=0
sum=0
# 读取数组，同时求和
while [[ $i -lt 100 ]]; do
    read array[$i]
    (( sum += array[i] ))
    (( ++i ))
done
# 求平均数
avg=$(echo "scale=2; ${sum} / 100.0" | bc)
# 排序，-n 表示基于数值排序
sorted=($(printf '%s\n' "${array[@]}" | sort -n))
# 打印平均值、最大值、最小值
echo "Avg = ${avg}, Min = ${sorted[0]}, Max = ${sorted[99]}"
echo "${sorted[@]}"
