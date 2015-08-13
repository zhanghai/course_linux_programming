#!/bin/bash

if [[ $# == 1 ]]; then
    stat $1 --printf "Owner: %U, Last modified: %y\n"
else
    echo "ERROR: You should enter one and only one parameter."
fi
