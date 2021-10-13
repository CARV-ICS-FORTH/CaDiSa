#!/bin/bash

if [ "$#" -eq 0 ]; then
    docker exec -it -u cadisa  --env COLUMNS=`tput cols` --env LINES=`tput lines` $USER-node01 bash
else
    docker exec -it -u cadisa  --env COLUMNS=`tput cols` --env LINES=`tput lines` $1-node01 bash
fi