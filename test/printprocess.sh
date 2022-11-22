#!/bin/bash

printprocess(){
declare -a pids
for p in "$@"; do 
if [[ $p == "sep" ]]; then
        break
fi
pids+=("$p")        
#echo $p 
done
#pids=("$1")
#echo total of pids : "${#pids[@]}"
rateR=$2
#echo rateR : "${rateR[@]}"
rateW=$3
#echo rateW : "${rateW[@]}"
#total=$2
#echo "total : $2"



printed=0
# 3 . 1
#iteration to read each pid in the file
for p in "${pids[@]}" ; do
        echo -e "\n\n\n|-------------------------------(iteration : $printed start)----------------------------------\n"
        pid=$p
        #just to print the info of the process to compare
        
        echo -e "\nsudo cat /proc/$pid/io :\n-------------------------\n$(sudo cat /proc/$pid/io)\n-------------------------\n"
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %10s" "COMM" "PID" "USER" "READB" "WRITEB" "RATER" "RATEW" "DATE"

        #The command (COMM) that casted the process
        CMD=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
        
        #User that cast the command/process
        USER=$(ps -p $pid -F | awk '{ if ( $1 != "UID" ) print $1; }')

        #'READB' column
        READB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "read_bytes:" ) print $2;}' )
        
        #'WRITEB' column
        WRITEB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "write_bytes:" ) print $2;}' )

        #the datemonth=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $2; }' )
        day=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $3; }' )
        hour=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $4; }' )
        DATE=$(echo ${day} " " ${hour})

        #Print the process info 
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %16s" $CMD $pid $USER $READB $WRITEB "${rateR[$pid]}" "${rateW[$pid]}" $DATE

        echo -e "\n-------------------------------(iteration : $printed end)----------------------------------|\n"
        printed=$(($printed+1))
done



echo "Erika~"
 
}