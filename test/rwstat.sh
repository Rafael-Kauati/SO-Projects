#!/bin/bash

source "./readpidsbyuser.sh" 

# 1 . 0
USER="root"
#Catch all pids by a given user
rawpids=$(printpidsbyuser $USER)
#echo $rawpids


# 2 . 1
#regular expressionto to check if the var is a numeric or not
re='^[0-9]+$'
#iteration the store each pids into the file
for ((i=0; i<${#rawpids}; i++)); do
    #cast the var
    ch="${rawpids:$i:1}"
    #check if its numeric (a pid properly)
    if [[ $ch =~ $re ]]; then
        fullpid="${fullpid}${ch}"
    else
        pids+=("$fullpid")
        fullpid=""
    fi
done

# RateR and RateW calculation using pids array
declare -a rateR
declare -a rateW

for ((i=0; i<${#pids[@]}; i++)); do
    cont=${pids[i]}
    readb=$(sudo cat /proc/${cont}/io | grep "rchar" | awk '{print $2}' )
    writeb=$(sudo cat /proc/${cont}/io | grep "wchar" | awk '{print $2}' )
    rateR+=($readb)
    rateW+=($writeb)
done

# The value here will obviously have to be changed to a variable derived from the arguments
# By omission, we'll use 5 seconds (though I think it's supposed to be 10 but I don't like waiting for too long)

s=5
sleep $s

for ((i=0; i<${#pids[@]}; i++)); do
    cont=${pids[i]}
    readb=$(sudo cat /proc/${cont}/io | grep "rchar" | awk '{print $2}' )
    writeb=$(sudo cat /proc/${cont}/io | grep "wchar" | awk '{print $2}' )
    # echo "$(($readb/$s)).$(( ($readb*100/$s)%100 ))"
    # echo "$(($writeb/$s)).$(( ($writeb*100/$s)%100 ))"
    rateR[i]="$(($readb/$s)).$(( ($readb*100/$s)%100 ))"
    rateW[i]="$(($writeb/$s)).$(( ($writeb*100/$s)%100 ))"
done

# Fun fact : using "<< com" and then "com" on separate lines will make it so everything in between is commented

<< com

# 3 . 1
#iteration to read each pid in the file
for index in "${pids[@]}" ; do
        echo -e "\n\n\n|-------------------------------(iteration : start)----------------------------------\n"
        pid=$index
        #just to print the info of the process to compare
        echo -e "\nsudo cat /proc/$pid/io :\n-------------------------\n$(sudo cat /proc/$pid/io)\n-------------------------\n"
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %20s" "COMM" "PID" "USER" "READB" "WRITEB" "RATER" "RATEW" "DATE"
        #The command (COMM) that casted the process
        CMD=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
        #'READB' column
        READB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "read_bytes:" ) print $2;}' )
        #'WRITEB' column
        WRITEB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "write_bytes:" ) print $2;}' )
        #the date(still only the hour in hh:mm:ss format, shall modify to catch the month date properly)
        DATE=$(ps -p $pid | awk '{ if ( $3 != "TIME") print $3; }' )
        #Print the process info 
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %20s" $CMD $pid $USER $READB $WRITEB "RATER" "RATEW" $DATE
        echo -e "\n-------------------------------(iteration : end)----------------------------------|\n"

done

com

echo "Erika~"


 