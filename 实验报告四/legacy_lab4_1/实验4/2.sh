#!/bin/bash

if [[ $# == 1 ]]; then
    ls -al $1 | awk 'BEGIN { file = 0; dirffectory = 0; executable = 0; } NR > 1 { if ($1 ~ /^d/) { ++directory; } else { ++file; if ($1 ~ /x/) { ++executable; } } } END { directory -= 2; printf "Files: %d, directories: %d, executables: %d\n", file, directory, executable; }'
else
    echo "ERROR: You should enter one and only one parameter."
fi
