#!/bin/bash

source "./readpidsbyuser.sh" 

# 1 . 0
USER="tk"
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



# 3 . 1
#iteration to read each pid in the file
for index in "${pids[@]}" ; do
        echo -e "\n\n\n|-------------------------------(iteration : start)----------------------------------\n"
        pid=$index
        #just to print the info of the process to compare
        echo -e "\n cat /proc/$pid/io :\n-------------------------\n$(cat /proc/$pid/io)\n-------------------------\n"
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %20s" "COMM" "PID" "USER" "READB" "WRITEB" "RATER" "RATEW" "DATE"
        #The command (COMM) that casted the process
        CMD=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
        #'READB' column
        READB=$( cat /proc/$pid/io | awk '{ if ( $1 == "read_bytes:" ) print $2;}' )
        #'WRITEB' column
        WRITEB=$( cat /proc/$pid/io | awk '{ if ( $1 == "write_bytes:" ) print $2;}' )
        #the date(still only the hour in hh:mm:ss format, shall modify to catch the month date properly)
        DATE=$(ps -p $pid | awk '{ if ( $3 != "TIME") print $3; }' )
        #Print the process info 
        printf "\n%10s %10s %10s %10s %10s %10s %10s %10s %10s %20s" $CMD $pid $USER $READB $WRITEB "RATER" "RATEW" $DATE
        echo -e "\n-------------------------------(iteration : end)----------------------------------|\n"

done


echo "Erika~"


 