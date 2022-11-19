#!/bin/bash

printprocess(){

pids=$1
sec=$2


echo -e seconds : $sec

# RateR and RateW calculation using pids array
declare -a rateR
declare -a rateW

for ((i=0; i<${#pids[@]}; i++)); do
    cont=${pids[i]}
    #checkexistence="/proc/${cont}/"
    readb=$(sudo cat /proc/${cont}/io | grep "rchar" | awk '{print $2}' )
    writeb=$(sudo cat /proc/${cont}/io | grep "wchar" | awk '{print $2}' )
    rateR+=($readb)
    rateW+=($writeb)
    #echo "Initial rater n ratew"
done

sleep $sec

# 3 . 1
#iteration to read each pid in the file
for p in "${pids[@]}" ; do
        echo -e "\n\n\n|-------------------------------(iteration : start)----------------------------------\n"
        pid=$p
        #just to print the info of the process to compare
        
        echo -e "\nsudo cat /proc/$pid/io :\n-------------------------\n$(sudo cat /proc/$pid/io)\n-------------------------\n"
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %20s" "COMM" "PID" "USER" "READB" "WRITEB" "RATER" "RATEW" "DATE"

        #The command (COMM) that casted the process
        CMD=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
        
        #User that cast the command/process
        USER=$(ps -p $pid -F | awk '{ if ( $1 != "UID" ) print $1; }')

        # The value here will obviously have to be changed to a variable derived from the arguments
        # By omission, we'll use 5 seconds (though I think it's supposed to be 10 but I don't like waiting for too long)
        readb=$(sudo cat /proc/${pid}/io | grep "rchar" | awk '{print $2}' )
        writeb=$(sudo cat /proc/${pid}/io | grep "wchar" | awk '{print $2}' )
        #The rate of chars that were read on this process
        rateR[$pid]="$(($readb/$sec)).$(( ($readb*100/$sec)%100 ))"
        #The rate of chars that wre write on this process
        rateW[$pid]="$(($writeb/$sec)).$(( ($writeb*100/$sec)%100 ))"

        #'READB' column
        READB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "read_bytes:" ) print $2;}' )
        
        #'WRITEB' column
        WRITEB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "write_bytes:" ) print $2;}' )

        #the datemonth=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $2; }' )
        day=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $3; }' )
        hour=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $4; }' )
        DATE=$(echo ${month} " " ${day} " " ${hour})

        #Print the process info 
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %10s" $CMD $pid $USER $READB $WRITEB "${rateR[$pid]}" "${rateW[$pid]}" $DATE

        echo -e "\n-------------------------------(iteration : end)----------------------------------|\n"
done



echo "Erika~"
 
}
