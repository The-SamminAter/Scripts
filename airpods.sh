#!/bin/bash
#This relies on AirStatus - it's just a quick script to interpret its readouts
fullReadout="$(cat /tmp/airstatus.out 2>&1 | tail -1)"
if [[ "${fullReadout}" == *"No such file or directory"* ]]
then
    sudo touch /tmp/airstatus.out
    "$0"
elif [[ -z "${fullReadout}" ]]
then
    sudo systemctl stop airstatus
    sudo systemctl start airstatus
    if [[ "$(bluetoothctl info)" == "Missing device address argument" ]]
    then
        bluetoothctl power off
        bluetoothctl power on
    fi
    echo "No data"
else
    leftPod="$(echo "${fullReadout}" | awk -F'"left": ' '{print $2}' | awk -F',' '{print $1}')"
    rightPod="$(echo "${fullReadout}" | awk -F'"right": ' '{print $2}' | awk -F',' '{print $1}')"
    case="$(echo "${fullReadout}" | awk -F'"case": ' '{print $2}' | awk -F'}' '{print $1}')"
    timeMeasured="$(echo "${fullReadout}" | awk -F'"date": ' '{print $2}' | awk -F' ' '{print $2}' | head -c8 | awk -F: '{print ($1*3600)+($2*60)+$3}')"
    timeCurrent="$(date +'%H:%M:%S' | awk -F: '{print ($1*3600)+($2*60)+$3}')"
    #time="$(date -d@$(bc <<< "${timeCurrent}-${timeMeasured}") -u +'%H:%M:%S')"
    #We don't really need it in proper format, as it seems to update <1m
    time=$(bc <<< "${timeCurrent}-${timeMeasured}")
    if [[ "${case}" == "-1" ]]
    then
        echo "L: ${leftPod}%    R: ${rightPod}%    Time: ${time}s ago"
    else
        echo "L: ${leftPod}%    R: ${rightPod}%    C: ${case}%    Time: ${time}"
    fi
    unset leftPod rightPod case time
fi
unset fullReadout
#Dunno why the case sometimes returns -1, I presume it perhaps isn't always connected?
