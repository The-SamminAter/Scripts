#!/bin/bash
#Source: https://wejn.org/2023/05/split-big-xci-or-nsp-to-store-it-on-fat32/
if [[ "$1" != *".xci" ]] && [[ "$1" != *".nsp" ]]
then
	echo "This script only operates on XCIs and NSPs"
	exit 1
fi

path="$(pwd)"
filename="$(echo $1 | sed 's/.*\///')"

if [[ ! -d "/Volumes/SWITCH SD" && -z $2 ]]
then
	echo "Please mount the Switch SD or set a destination"
	exit 1
elif [[ $2 ]]
then
	if [[ ! -d "$2" ]]
	then
		mkdir "$2"
	fi
	cd "$2"
else
	# Move to target
	cd /Volumes/SWITCH\ SD/  # ← path to sd card's root
	if [[ ! -d "roms" ]]
	then
		mkdir roms
	fi
	cd roms
fi

# Make "xci" directory, and set archive bit
mkdir "${filename}"
fatattr +a "${filename}" # apt install fatattr if you don't have it

# Split up big ass xci to properly sized chunks
cd "${filename}"
split --verbose -a 2 -b 4294901760 -d "${path}/$1" ''
