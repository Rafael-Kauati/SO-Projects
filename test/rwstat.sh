#!/bin/bash
# Fun fact : using "<< com" and then "com" on separate lines will make it so everything in between is commented
source "./readpidsbyuser.sh" 
source "./printprocess.sh"


### Data zone , to store variables that can be changed with the opts or let by deafult

#for arg in "$@"; do echo $arg ; done

#If shall print on the reverser order of the pids (i guess the reference are the pids)
reverse=false
#min value of the pids range, if its not specified, its 0 by default
min=0
#max value of the pids range, if nost specified, theres no max limit
max=""
#Number of process to be printed
total=""

# : --> for opt with arguments
# ; --> for opt without arguments
seconds_index=$#
while [ "$#" -gt 0 ]
do  
    #The number(seconds) to sleep to calculate the rateR and rateW[
    #standardizing the seconds argument position as the first passed
    if [[ $# -eq $seconds_index ]]; then
     #echo $1
     sec=$1
    fi

	case "$1" in
	-u)
		user=$2
		;;
	-m)
        min=$2
        ;;
    -M)
        max=$2
        ;;
    -p)
        total=$2
        ;;        
	esac
	shift
    
done         

# 1 . 0
#Catch all pids by a given user
echo user : $user
if test -z "$user" 
then
      #echo "\$user is not define"
      rawpids=$( ps aux | awk '{ if ( $2 != "PID") print $2 ;}' )  
else
        #echo "\$user is defined"
        if [[ user == "root" ]]; then
            rawpids=$(printpidsbyuser $user)

        else
            rawpids=$(printpidsbyuser $user)

        fi    
fi

 


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
        if [[ -n "$max" ]] ;
        then
            #echo max : $max
            #Add pid if : pid >= min
            if (( "$fullpid" >= "$min" && ( "$fullpid" <= "$max" ) )); then
                #Only add a pid if the "proc/pid/" exists

                checkexistence="/proc/$fullpid/"
                if [ -d "$checkexistence" ] ;
                then
                    pids+=("$fullpid")
                fi    

                fullpid=""
            fi
        else
        #echo min : $min

            #Add pid if : pid >= min
            if [[ $fullpid -ge $min ]]; then
                #Only add a pid if the "proc/pid/" exists

                checkexistence="/proc/$fullpid/"
                if [ -d "$checkexistence" ] ;
                then
                    pids+=("$fullpid")
                fi    

                fullpid=""
            fi
                
        fi
    fi

done


#echo total : $total

if test -z "$total"
then
    #echo total : 0
    total="${#pids[@]}"
    echo total : $total
else
    echo total : $total
fi       
#echo seconds first : $sec

#Print the process in table format
printprocess $pids $sec $total
