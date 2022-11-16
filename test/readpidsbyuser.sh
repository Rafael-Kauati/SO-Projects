#!/bin/bash

printpidsbyuser(){
ps -u $1 | awk '{ if ( $1 != "PID") print $1 ;}'
}

#./printpidsbyuser $1