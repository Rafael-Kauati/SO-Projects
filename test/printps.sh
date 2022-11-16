#!/bin/bash

PRINTPS () { ps -u root; }
#PRINTPS
export -f PRINTPS
#./caller.sh
#export -p 