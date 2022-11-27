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

#Regex to be compared if mathces with the COMM column when casted the -c option(by default is null)
regex=""

#Date and hour of start reference (by default is the value of the first process)
month=$(ps -o lstart -p 1 | awk '{ if ( $1 != "STARTED") print $2; }' )
day=$(ps -o lstart -p 1 | awk '{ if ( $1 != "STARTED") print $3; }' )
hour=$(ps -o lstart -p 1 | awk '{ if ( $1 != "STARTED") print $4; }' )        
start="${month} ${day} ${hour}"

#Date and hour of end reference (by default if null)
end=""

# : --> for opt with arguments
# ; --> for opt without arguments
seconds_index=$#
re='[0-9]+'
sec=$1
#The number(seconds) to sleep to calculate the rateR and rateW[
#standardizing the seconds argument position as the first passed
if [[ ! "$sec" =~ $re ]]; then 
    #echo $sec
    echo "O primeiro argumento deve ser o valor (em segundos) para o cálculo das taxas de rateR e rateW"
    exit
fi    

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
	-c)
        regex=$2
        ;;
    -s)
        start=$2
        exit_start=$(date -d "$start" +%s)
        if [[ "$?" -eq 1 ]]; then
            echo "Referência de data e hora de início invalido (Mês dia hh:mm:ss)"
            exit
        fi
        ;;
    -e)
        end=$2
        exit_end=$(date -d "$end" +%s)
        if [[ "$?" -eq 1 ]]; then
            echo "Referência de data e hora de fim invalido (Mês dia hh:mm:ss)"
            exit
        fi
        ;;        
    esac
	shift
    
done      

# 1 . 0
#Catch all pids by a given user
if test -z "$user" 
then
      rawpids=$( ps aux | awk '{ if ( $2 != "PID") print $2 ;}' )  
else
        if [[ user == "root" ]]; then
            rawpids=$(printpidsbyuser $user)

        else
            rawpids=$(printpidsbyuser $user)

        fi    
fi

# Note: rawpids are already ordered in increasing order

# 2 . 1
#regular expressionto to check if the var is a numeric or not
re='^[0-9]+$'
#iteration the store each pids into the file

declare -a pids

#This for loop also builds the PIDs array according to a few established parameters in the option arguments
#iteration the store each pids into the file
for ((i=0; i<${#rawpids}; i++)); do
    
    #cast the var
    ch="${rawpids:$i:1}"
    #check if its numeric (a pid properly)
    if [[ $ch =~ $re ]]; then
        fullpid="${fullpid}${ch}"

    else
        #Check if the dir exist
        dir="/proc/${fullpid}/"
        if [[ -d $dir ]]; then

            #Check if the io file exists
            iofile="/proc/${fullpid}/io"
            if [[ -e $iofile ]]; then
            #echo $(sudo cat $iofile)

                #Check if the regex expression is defined (by the -c option)
                if [[ "$regex" != "" ]]; then

                    #Check if the regex match with the command of the process
                    CMD=$(sudo cat /proc/${fullpid}/comm)
                    if [[ $CMD == $regex ]]; then
                        #Check if the (current) pid is greater or equal of the min pid range value (by default is 0)   
                        if [[ "$fullpid" -ge "$min" ]]; then
                            #Check if a max value of pid range is defined
                            if [[ "$max" != "" ]]; then
                                    #Check if (current) pid is less or equal to the max value range
                                    if [[ "$fullpid" -gt "$max" ]]; then
                                        break
                                    fi  
                                    #Check if a current pid process is greater or erqual than the start reference
                                    start_by_sec=$(date -d "$start" +%s)
                                    #The date info of the curr pid
                                    month=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $2; }' )
                                    day=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $3; }' )
                                    hour=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $4; }' )        
                                    DATE="${month} ${day} ${hour}"
                                    date_pid_sec=$(date -d  "$DATE" +%s)
                                    if [[ "$date_pid_sec" -ge "$start_by_sec" ]]; then
                                            #Check if theres an end date and hour reference define
                                            if [[ "$end" != "" ]]; then
                                                end_by_sec=$(date -d "$end" +%s)
                                                #Check if the date of the process of the current pid is greater than the end reference
                                                if [[ "$date_pid_sec" -gt "$end_by_sec" ]]; then
                                                    echo "end break : $DATE"
                                                    break
                                                fi    
                                            fi
                                            pids+=("$fullpid")
                                            fullpid=""
                                    #Else : theres n start reference
                                    else
                                        fullpid=""
                                    fi

                            #Theres no max range value defined
                            else
                                    #Check if a current pid process is greater or erqual than the start reference
                                    start_by_sec=$(date -d "$start" +%s)
                                    #The date info of the curr pid
                                    month=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $2; }' )
                                    day=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $3; }' )
                                    hour=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $4; }' )        
                                    DATE="${month} ${day} ${hour}"
                                    date_pid_sec=$(date -d  "$DATE" +%s)
                                    if [[ "$date_pid_sec" -ge "$start_by_sec" ]]; then
                                            #Check if theres an end date and hour reference define
                                            if [[ "$end" != "" ]]; then
                                                end_by_sec=$(date -d "$end" +%s)
                                                #Check if the date of the process of the current pid is greater than the end reference
                                                if [[ "$date_pid_sec" -gt "$end_by_sec" ]]; then
                                                    break
                                                fi    
                                            fi    
                                            #echo max pid range value : $max
                                            #echo fullpid $fullpid
                                            pids+=("$fullpid")
                                            fullpid=""
                                    #Else : theres n start reference
                                    else
                                        fullpid=""
                                    fi
                            fi

                        else
                            fullpid=""
                        fi
                    fi

                #If theres no regex value defined to be compared                    
                else
                        #Check if the (current) pid is greater or equal of the min pid range value (by default is 0)   
                        if [[ "$fullpid" -ge "$min" ]]; then
                            #Check if a max value of pid range is defined
                            if [[ "$max" != "" ]]; then
                                #Check if (current) pid is less or equal to the max value range
                                if [[ "$fullpid" -gt "$max" ]]; then
                                    echo "end break : $DATE"

                                    break
                                fi

                                    #Check if a current pid process is greater or erqual than the start reference
                                    start_by_sec=$(date -d "$start" +%s)
                                    #The date info of the curr pid
                                    month=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $2; }' )
                                    day=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $3; }' )
                                    hour=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $4; }' )        
                                    DATE="${month} ${day} ${hour}"
                                    date_pid_sec=$(date -d  "$DATE" +%s)
                                    if [[ "$date_pid_sec" -ge "$start_by_sec" ]]; then
                                            #Check if theres an end date and hour reference define
                                            if [[ "$end" != "" ]]; then
                                                end_by_sec=$(date -d "$end" +%s)
                                                #Check if the date of the process of the current pid is greater than the end reference
                                                if [[ "$date_pid_sec" -gt "$end_by_sec" ]]; then
                                                    break
                                                fi    
                                            fi
                                            pids+=("$fullpid")
                                            fullpid=""
                                    #Else : theres n start reference
                                    else
                                        fullpid=""
                                    fi
                            #Theres no max range value defined       
                            else
                                
                                #Check if a current pid process is greater or erqual than the start reference
                                    start_by_sec=$(date -d "$start" +%s)
                                    #The date info of the curr pid
                                    month=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $2; }' )
                                    day=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $3; }' )
                                    hour=$(ps -o lstart -p $fullpid | awk '{ if ( $1 != "STARTED") print $4; }' )        
                                    DATE="${month} ${day} ${hour}"
                                    date_pid_sec=$(date -d  "$DATE" +%s)
                                    if [[ "$date_pid_sec" -ge "$start_by_sec" ]]; then
                                            #Check if theres an end date and hour reference define
                                            if [[ "$end" != "" ]]; then
                                                end_by_sec=$(date -d "$end" +%s)
                                                #Check if the date of the process of the current pid is greater than the end reference
                                                if [[ "$date_pid_sec" -gt "$end_by_sec" ]]; then
                                                    break
                                                fi    
                                            fi    
                                            #echo max pid range value : $max
                                            #echo fullpid $fullpid
                                            pids+=("$fullpid")
                                            fullpid=""
                                    #Else : theres n start reference
                                    else
                                        fullpid=""
                                    fi

                            fi

                        else
                            
                            fullpid=""
                        fi

                fi

            fi

        else
            fullpid=""
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
        iofile="/proc/${cont}/io"
        if [ -e $iofile ]; then
            readb=$(sudo cat /proc/${cont}/io | grep "rchar" | awk '{print $2}' )
            writeb=$(sudo cat /proc/${cont}/io | grep "wchar" | awk '{print $2}' )
        fi
    fi
    rateR[$cont]=$readb
    rateW[$cont]=$writeb
done


sleep $sec

for ((i=0; i<${#pids[@]}; i++)); do
        pid=${pids[i]}
        checkexistence="/proc/${pid}/"
        readb=0
        writeb=0
        if [ -d $checkexistence ]; then
            iofile="/proc/${pid}/io"
            if [ -e $iofile ]; then
                readb=$(sudo cat /proc/${pid}/io | grep "rchar" | awk '{print $2}' )
                writeb=$(sudo cat /proc/${pid}/io | grep "wchar" | awk '{print $2}' )
            fi
        fi
        delta_readB=$(( $readb - ${rateR[$pid]} )) #Difference between previous and current read byte values
        delta_writeB=$(( $writeb - ${rateW[$pid]} )) #Same but with write byte values

        #Incomplete computation of rate of read bytes so that it may be compared without much complication

        rateR[$pid]=$(( $delta_readB*100/$sec  ))

        #Incomplete computation of rate of read bytes so that it may be compared without much complication

        rateW[$pid]=$(( $delta_writeB*100/$sec ))
done





#---Sorting by reading rate using an improvised but slow sorting method
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

#---Sorting by write rate using an improvised but slow sorting method

#rateW sorting overrides any rateR sorting

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
fi

#Divide by 100 to get actual rate values

for i in ${pids[@]}; do
    rateW[$i]=$( bc <<< "scale=2; ${rateW[$i]}/100" )
    rateR[$i]=$( bc <<< "scale=2; ${rateR[$i]}/100" )
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
fi






source "./printprocess_edit.sh"


printprocess_edit pids rateR rateW total
