#!/bin/bash

printpidsbyuser(){
    #read all pids (from the pids column) of a specified user
ps -u $1 | awk '{ if ( $1 != "PID") print $1 ;}'
}

#./printpidsbyuser $1