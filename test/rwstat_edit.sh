#!/bin/bash
# Fun fact : using "<< com" and then "com" on separate lines will make it so everything in between is commented

#Small side note: may want to package PID existence verification into a function to keep things clean

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
#Flag for ordering the table by rate of bytes written by processes
ratew_order=0

# : --> for opt with arguments
# ; --> for opt without arguments

re='^[0-9]+' #To check whether or not the final argument is a number

seconds_index=$#

last_arg=${@: -1} #Last argument

#Check if last argument is a number.
#If the last argument is not a number (or a negative number), inform user of usage and terminate

if [[ !(${last_arg} =~ $re ) ]]; then
    echo "Usage: ./rwstat.sh [options] [number of seconds]"
    exit
#Check if number of seconds is zero
elif [[ $last_arg == 0 ]]; then
    echo "ERROR: Número de segundos deve ser positivo"
    exit
fi

sec=$last_arg

while [ "$#" -gt 0 ]
do  
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
    -w)
        ratew_order=1
        ;;   
	esac
	shift
    
done         

# 1 . 0
#Catch all pids by a given user
echo user : $user
if test -z "$user" 
then
      #echo "\$user is not defined"
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
declare -A rateR
declare -A rateW


for ((i=0; i<${#pids[@]}; i++)); do
    
    cont=${pids[i]}
    checkexistence="/proc/${cont}/"
    readb=0
    writeb=0
    if [ -d $checkexistence ]; then
        readb=$(sudo cat /proc/${cont}/io | grep "rchar" | awk '{print $2}' )
        writeb=$(sudo cat /proc/${cont}/io | grep "wchar" | awk '{print $2}' )
    fi
    rateR[$cont]=$readb
    rateW[$cont]=$writeb
done


sleep $sec

for ((i=0; i<${#pids[@]}; i++)); do
        pid=${pids[i]}
        readb=0
        writeb=0
        if [ -d $checkexistence ]; then
            readb=$(sudo cat /proc/${pid}/io | grep "rchar" | awk '{print $2}' )
            writeb=$(sudo cat /proc/${pid}/io | grep "wchar" | awk '{print $2}' )
        fi

        delta_readB=$(( $readb - ${rateR[$pid]} )) #Difference between previous and current read byte values
        delta_writeB=$(( $writeb - ${rateW[$pid]} )) #Same but with write byte values

        #Incomplete computation of rate of read bytes so that it may be compared without much complication

        rateR[$pid]=$(( $delta_readB*100/$sec  ))

        #Less cumbersome method to obtain floating point arithmetic result
        #rateR[$pid]=$( bc <<< "scale=2; $delta_readB/$sec" )

        #Incomplete computation of rate of read bytes so that it may be compared without much complication

        rateW[$pid]=$(( $delta_writeB*100/$sec ))

        #rateW[$pid]=$( bc <<< "scale=2; $delta_writeB/$sec" )
        #echo rateR of pid $pid : ${rateR[$pid]}
        #echo rateW of pid $pid : ${rateW[$pid]}

done

#echo total : $total

#Check array elements
<< com 
for ((i=0; i<${#pids[@]}; i++)); do
    echo ${pids[i]} : ${rateR[i]} : ${rateW[i]} 
done
com


echo original PIDs : "${pids[@]}"

#---Sorting by reading rate using an improved but slow sorting method
if [[ $ratew_order -eq 0 ]]
then
    one_before_last=$(( ${#pids[@]} - 1 ))
    for ((i=0; i < $one_before_last; i++)); do
        max_ind=$(($i))
        max_rateR=${rateR[${pids[i]}]}
        one_after_i=$(( $i + 1 ))
        #This will determine the maximum rateW for any PIDs in the index interval [i , last]
        for ((j=$one_after_i; j < ${#pids[@]}; j++)); do

            curr_rateR=${rateR[${pids[j]}]}

            if [ $curr_rateR -gt $max_rateR ]; then
                max_rateR=$curr_rateR
                max_ind=$(($j))
            fi
        done
        #Swap PID associated to the maximum rateW in interval [i, last] with the PID at index i
        tmp=${pids[i]}
        pids[i]=${pids[$max_ind]}
        pids[$max_ind]=$tmp
    done

echo PIDs after rateR-based sorting : "${pids[@]}"

#---Sorting by write rate using an improvised but slow sorting method

#rateW sorting overwrites any rateR sorting

else
    one_before_last=$(( ${#pids[@]} - 1 ))
    for ((i=0; i < $one_before_last; i++)); do
        max_ind=$(($i))
        max_rateW=${rateW[${pids[i]}]}
        one_after_i=$(( $i + 1 ))
        #This will determine the maximum rateW for any PIDs in the index interval [i , last]
        for ((j=$one_after_i; j < ${#pids[@]}; j++)); do

            curr_rateW=${rateW[${pids[j]}]}

            if [ $curr_rateW -gt $max_rateW ]; then
                max_rateW=$curr_rateW
                max_ind=$(($j))
            fi
        done
        #Swap PID associated to the maximum rateW in interval [i, last] with the PID at index i
        tmp=${pids[i]}
        pids[i]=${pids[$max_ind]}
        pids[$max_ind]=$tmp
    done
    echo after rateW order PIDs: ${pids[@]}
fi

#Divide by 100 to get actual rate values

for i in ${pids[@]}; do
    rateW[$i]=$( bc <<< "scale=2; ${rateW[$i]}/100" )
    rateR[$i]=$( bc <<< "scale=2; ${rateR[$i]}/100" )
    echo "rateR for PID $i : ${rateR[$i]}"
    #echo "rateW for PID $i : ${rateW[$i]}"
done



#Use PIDs primarily to obtain their respective rateB and rateW values :)))

#Reverse the PID array

if [[ $reverse -eq 1 ]]; then
    Min=0
    Max=$(( ${#pids[@]} -1 ))

    while [[ Min -lt Max ]]
    do
        # Swap current first and last elements
        x="${pids[$Min]}"
        pids[$Min]="${pids[$Max]}"
        pids[$Max]="$x"

        # Move closer
        (( Min++, Max-- ))
    done
    echo reversed PIDs : "${pids[@]}"
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

com