#!/bin/bash
#
# this script should not be run directly,
# instead you need to source it from your .bashrc,
# by adding this line:
#   . ~/dir/mkcd.sh
#

function mkcd()
{
	if [[ "$1" == "-p" ]]
	then
		mkdir -p "$2"
		cd "$2"
	elif [[ "$2" == "-p" ]]
	then
		mkdir -p "$1"
		cd "$1"
	else
		mkdir "$1"
		cd "$1"
	fi
}
