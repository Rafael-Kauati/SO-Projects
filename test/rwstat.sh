#!/bin/bash
# Fun fact : using "<< com" and then "com" on separate lines will make it so everything in between is commented
source "./readpidsbyuser.sh" 
source "./printprocess.sh"


### Data zone , to store variables that can be changed with the opts or let by deafult

#for arg in "$@"; do echo $arg ; done

#If shall print on the reverser order of the pids (i guess the reference are the pids)
reverse=false
#min value of the pids range
min=0
#max value of the pids range
max=0
#Number of process to be printed
total=-1
#User if its not specified, its used the default null option (all user)

# : --> for opt with arguments
# ; --> for opt without arguments
while getopts ":c:s:e:u:m:M:r;w:p:" opt; do
    case $opt in

        c)
            regex=$OPTARG
        ;;

        s)
        
        ;;

        e)
        
        ;;

        u)
            user=$OPTARG
        ;;

        m)
            min=$OPTARG
        ;;

        M)
            max=$OPTARG
        
        ;;

        p)
            total=$OPTARG
        ;;

        r)
            reverse=true
        ;;

        w)
        
        ;;

    esac
done            


# 1 . 0
#Catch all pids by a given user
if test -z "$user" 
then
      #echo "\$user is NULL"
      rawpids=$( ps aux | awk '{ if ( $2 != "PID") print $2 ;}' )  
else
        #echo "\$user is NOT NULL"
        if [[ user == "root" ]]; then
            rawpids=$(printpidsbyuser $user)

        else
            rawpids=$(printpidsbyuser $user)

        fi    
fi





#The number(seconds) to sleep to calculate the rateR and rateW[
#Assuming that its always passed as the last argument
for last; do true ; done
sec=$last


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
        #Only add a pid if the "proc/pid/" exists
        checkexistence="/proc/$fullpid/"
        if [ -d "$checkexistence" ] ;
        then
            pids+=("$fullpid")
        fi    
        fullpid=""

    fi
done



printprocess $pids $sec





