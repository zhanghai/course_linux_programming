#!/bin/bash

i=0
sum=0
while [[ $i -lt 100 ]]; do
    read array[$i]
    (( sum += array[i] ))
    (( ++i ))
done
sorted=($(printf '%s\n' "${array[@]}" | sort))
echo "Min = ${sorted[0]}, Max = ${sorted[99]}, Sum = $sum"
echo "${sorted[@]}"
