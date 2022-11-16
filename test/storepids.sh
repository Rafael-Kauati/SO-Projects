#!/bin/bash

storepids(){
    pids=$1
    echo $1
    file=$2
    re='^[0-9]+$'
    for ((i=0; i<${#pids}; i++)); do
        ch="${pids:$i:1}"
        if [[ $ch =~ $re ]]; then
        echo $ch
            echo -n $ch >> file
        else
            echo -e "\n" >> file
        fi
    done
}
