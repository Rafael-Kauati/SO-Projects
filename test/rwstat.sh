#!/bin/bash

source "./readpidsbyuser.sh" 

# 1 . 0
USER="tk"
#Catch all pids by a given user
rawpids=$(printpidsbyuser $USER)
#echo $rawpids

#listar todos os pids
#ls -l /proc | grep "^d" | awk '{print $9}' | grep "^[0-9]"

#declare the array of pids :

#-a stands for an array array
#-A stands for an array related
#declare -a pids ;


#echo -e $( ps -u $USER | awk '{ if ( $1 != "PID") print $1 ;}' | wc -l )
#pids[$( ps -u $USER | awk '{ if ( $1 != "PID") print $1 ;}' | wc -l )]
#echo -e "Size of array : ${#pids[@]} \n"

# '>' for overwrite 
# '>>' for append

#to clean pids previously saved in the file (assuming that they're "outdated")
echo "" > pids.txt


# 2 . 1
#regular expressionto to check if the var is a numeric or not
re='^[0-9]+$'
#iteration the store each pids into the file
for ((i=0; i<${#rawpids}; i++)); do
    #cast the var
    ch="${rawpids:$i:1}"
    #check if its numeric (a pid properly)
    if [[ $ch =~ $re ]]; then
        echo -n $ch >> pids.txt
        fullpid="${fullpid}${ch}"
        #pids+=("$ch")
    else
        pids+=("$fullpid")
        echo -e "\n" >> pids.txt
        fullpid=""

    fi
done

#echo pids : ${pids[@]}


# 3 . 1
file="pids.txt"
#iteration to read each pid in the file
while read line; do
    pid=$line
    if [[ $pid =~ $re ]]; then
        #just to print the info of the process to compare
        echo -e "\n----------------------\n$(sudo cat /proc/$pid/io)\n----------------------\n"
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
    else    
        echo -e "\n"

    fi
done < $file


 