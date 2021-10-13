#!/bin/bash

docker exec -it -u cadisa  --env COLUMNS=`tput cols` --env LINES=`tput lines` $USER-node01 bash
