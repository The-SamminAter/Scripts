#!/bin/bash
#Basic script to automate an action. Cause aliases are weird.
#Now with screenshot handling!
if [[ "$1" == *"Screenshot"* ]]
then
    mv "$1" "/home/$(whoami)/Desktop/Screenshot.png"
    SCFLAG=true
    FILE="/home/$(whoami)/Desktop/Screenshot.png"
elif [[ "$(cut -f2 -d'/' <<< $1)" == *":"* ]] || [[ "$(cut -f2 -d'/' <<< $1)" == *","* ]]
then
    echo "File name has character(s) that will cause it to fail to upload"
    exit
elif [[ "$(cut -f1 -d'/' <<< $1)" == *":"* ]] || [[ "$(cut -f1 -d'/' <<< $1)" == *","* ]]
then
    echo "File path has character(s) that will cause it to fail to upload"
    exit
else
    FILE="$1"
fi
fullOut=$(curl --request POST --url <your assx server here> --progress-bar -H 'Authorization: <your authorization key here>' -H 'Connection: keep-alive' -F file=@"$FILE")
resource="$(echo "${fullOut}" | awk -F'"resource":"' '{print $2}' | awk -F'"' '{print $1}')"
delete="$(echo "${fullOut}" | awk -F'"delete":"' '{print $2}' | awk -F'"' '{print $1}')"
echo "Download: ${resource}"
echo "Delete: ${delete}"
if [[ $SCFLAG ]]
then
    rm "/home/$(whoami)/Desktop/Screenshot.png"
fi
#Might as well keep track of all of the uploaded files
if [[ ! -z "${resource}" ]]
then
    echo "$1" >> ~/.assx
    echo "${resource}" >> ~/.assx
    echo "${delete}" >> ~/.assx
fi
#Allows for every file listed as an argument to be uploaded
if [[ "$2" ]]
then
        $0 "${@:2}"
fi
unset fullOut resource delete FILE SCFLAG
