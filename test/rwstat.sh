#!/bin/bash

source "./readpidsbyuser.sh" 

# 1 . 0
user="tk"
rawpids=$(printpidsbyuser $user)
#echo $rawpids

# '>' for overwrite 
# '>>' for append

#to clean pids previously saved in the file (assuming that they're "outdated")
echo "" > pids.txt


# 2 . 1
re='^[0-9]+$'
for ((i=0; i<${#rawpids}; i++)); do
    ch="${rawpids:$i:1}"
    if [[ $ch =~ $re ]]; then
        echo -n $ch >> pids.txt
    else
        echo -e "\n" >> pids.txt
    fi
done


# 3 . 1
file="pids.txt"
while read line; do
    pid=$line
    if [[ $pid =~ $re ]]; then
        echo -e "\nProcess number : "
        echo -e "$pid\n"
        
        printf "\n%10s %10s %10s %10s %10s %10s %10s %20s" "COMM" "USER" "READB" "RATER" "RATEW" "DATE"
        
        procinfo=$(sudo cat "/proc/$pid/io")
        cmd=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
        READB=$(echo ${procinfo:8:14})
        echo $READB
        #echo $cmd
        #printf "\n%10s %10s %10s %10s %10s %10s %10s %20s" $cmd $user "READB" "RATER" "RATEW" "DATE"
        echo -e "\n"
        echo $procinfo
    else    
        echo -e "\n"

    fi
done < $file


 