#!/bin/bash

printprocess_edit(){

#Note: Local variables can't be called the same name as name of arrays passed as arguments
local -n pids_ref=$1
local -n rateR_ref=$2
local -n rateW_ref=$3
local -n total_ref=$4

w_space=37
u_space=12
p_space=13
r_space=15
d_space=25

printf "%-${w_space}s %-${u_space}s %${p_space}s %${r_space}s %${r_space}s %${r_space}s %${r_space}s %${r_space}s %${d_space}s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"


for pid in "${pids_ref[@]}" ; do
        #If the total of pids to be printed is defined
        if [[ ! -z "$total_ref" ]]; then
            if [[ "$total_ref" -eq 0 ]]; then
                break
            fi
            total_ref=$((total_ref-1))    
        fi
        dir="/proc/${pid}/"
        #Check process directory existence
        if [[ -d $dir ]]; then
                iofile="/proc/${pid}/io"
                #Check process io file existence
                if [[ -e $iofile ]]; then
                        #The command (COMM) that casted the process
                        CMD=$(ps -p $pid | awk '{ if ( $4 != "CMD") print $4 ;}' )
                        
                        #User that cast the command/process
                        USER=$(ps -p $pid -F | awk '{ if ( $1 != "UID" ) print $1; }')

                        #'READB' column
                        READB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "read_bytes:" ) print $2;}' )
                        
                        #'WRITEB' column
                        WRITEB=$(sudo cat /proc/$pid/io | awk '{ if ( $1 == "write_bytes:" ) print $2;}' )

                        month=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $2; }' )
                        day=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $3; }' )
                        hour=$(ps -o lstart -p $pid | awk '{ if ( $1 != "STARTED") print $4; }' )        
                        DATE="${month} ${day} ${hour}"

                        #Print the process info 
                        printf "%-${w_space}s %-${u_space}s %${p_space}s %${r_space}s %${r_space}s %${r_space}s %${r_space}s %${r_space}s %${d_space}s\n" "$CMD" "$USER" "$pid" "$READB" "$WRITEB" "${rateR_ref[$pid]}" "${rateW_ref[$pid]}" "$DATE"
                fi
        fi
done


}