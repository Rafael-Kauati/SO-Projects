#!/bin/bash
# Fun fact : using "<< com" and then "com" on separate lines will make it so everything in between is commented
source "./readpidsbyuser.sh" 


### Data zone , to store variables that can be changed with the opts or let by deafult

#for arg in "$@"; do echo $arg ; done

#If shall print on the reverser order of the pids (i guess the reference are the pids)
reverse=0
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
     echo $1
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
    -r)
        reverse=1
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

for ((i=0; i<${#pids[@]}; i++)); do
    pid=${pids[i]}
        # The value here will obviously have to be changed to a variable derived from the arguments
        # By omission, we'll use 5 seconds (though I think it's supposed to be 10 but I don't like waiting for too long)
        readb=$(sudo cat /proc/${pid}/io | grep "rchar" | awk '{print $2}' )
        writeb=$(sudo cat /proc/${pid}/io | grep "wchar" | awk '{print $2}' )
        #The rate of chars that were read on this process
        rateR[$pid]="$(($readb/$sec)).$(( ($readb*100/$sec)%100 ))"
        #The rate of chars that wre write on this process
        rateW[$pid]="$(($writeb/$sec)).$(( ($writeb*100/$sec)%100 ))"
        #echo rateR of pid $pid : ${rateR[$pid]}
        #echo rateW of pid $pid : ${rateW[$pid]}

done

#echo total : $total

   

#echo total : $total
#echo final pids : "${pids[@]}"

if [[ $reverse -eq 1 ]]; then

    #Reverse the rateR
    Min=0
    Max=$(( ${#rateR[@]} -1 ))

    while [[ Min -lt Max ]]
    do
        # Swap current first and last elements
        x="${rateR[$Min]}"
        rateR[$Min]="${rateR[$Max]}"
        rateR[$Max]="$x"

        # Move closer
        (( Min++, Max-- ))
    done

    echo reversed order rateR : "${rateR[@]}"


    #Reverse the rateW
    Min=0
    Max=$(( ${#rateW[@]} -1 ))

    while [[ Min -lt Max ]]
    do
        # Swap current first and last elements
        x="${rateW[$Min]}"
        rateW[$Min]="${rateW[$Max]}"
        rateW[$Max]="$x"

        # Move closer
        (( Min++, Max-- ))
    done

    echo reversed order rateW : "${rateW[@]}"
fi


echo "seconds first : $sec"

source "./printprocess.sh"

if test -z "$total"
then
    #echo total : 0
    #total="${#pids[@]}"
    #echo total : $total
     #Print the process in table format
    #            $1            $2            $3               
    printprocess "${pids[@]}"  "${rateR[@]}" "${rateW[@]}"  

else
    echo total defined : $total
    declare -a finalPids
    n=0
    for ((i=0;i<${#pids[@]};i++)){
        if [[ $n -eq $total ]]; then
        break
        fi
        pid=${pids[i]}
        finalPids+=($pid)
        echo pid : $n
        echo final pids : ${finalPids[@]}

           n=$((n+1)) 
    }
    echo end on pids : ${finalPids[@]}
    #            $1                $2      $3            $4              
    printprocess "${finalPids[@]}" "sep"   "${rateR[@]}" "${rateW[@]}"
    #source "./testargs.sh"

    #func ${finalPids[@]}


    #pids=${finalPids[@]}
    #set -v -x
    #Print the process in table format

fi    

