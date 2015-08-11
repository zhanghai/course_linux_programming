#!/bin/bash
if [[ -z "$1" ]]; then
    echo "Please specify a string as argument"
    exit 1
fi
# 使用 sed 替换所有非字母为空
str=$(echo "$1" | sed 's/[^A-Za-z]//g')
# 使用 rev 反转字符串
rev=$(echo "$str" | rev)
# 判断 str 和 rev 是否相等
if [[ "${str}" = "${rev}" ]]; then
    echo "${str} is a palindrome"
else
    echo "${str} is not a palindrome"
fi
