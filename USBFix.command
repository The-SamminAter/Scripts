#!/bin/bash
#MacBook Airs (the original, pre-M* ones) have this strange issue where they stop providing enough power to their USB ports
#This just exists for me to launch it via spotlight whenever this happens
sudo killall -STOP -c usbd
