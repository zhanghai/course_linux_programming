#!/bin/bash
# 打印目录名
echo "$1"
# 打印普通文件数量，以-开头
echo $(ls -al "$1" | grep -c '^-' ) 个普通文件
# 打印目录数量，以d开头
echo $(ls -al "$1" | grep -c '^d') 个目录
# 打印可执行数量，开头处含有x
echo $(ls -al "$1" | grep -c '^[-a-z]+x') 个可执行文件
# 打印所有文件字节数
ls -al "$1" | head -n1
