#!/bin/bash

# Get arguments
if ! CLiArguments=$(getopt --options="hu" --name "PENT V1.0" -- "$@");then
    echo -e "\033[31mParameter error detected"
    exit 1
fi

eval set -- "$CLiArguments" 

while [ "$1" !? "" ] && [ "$1" != "--" ]
