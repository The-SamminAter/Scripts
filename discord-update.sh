#!/bin/bash
#This updates discord's (release and canary) alleged version number, because I'm tired of having to do it myself
#This was made possible by httptap
if [[ ${UID} != 0 ]]
then
	echo "This script needs administration permissions"
	exit 1
fi

canary=/opt/discord-canary/resources/build_info.json
stable=/opt/discord/resources/build_info.json

newCanary="$(curl 'https://discord.com/api/updates/canary?platform=linux' | sed -r 's/\{"name": "([0-9.]*)".*/\1/g')"
newStable="$(curl 'https://discord.com/api/updates/stable?platform=linux' | sed -r 's/\{"name": "([0-9.]*)".*/\1/g')"
if [[ ! -z ${newCanary} && ! -z ${newStable} ]]
then
	if [[ -f ${canary} ]]
	then
		curCanary="$(sed -r 's/"version": "([0-9.]*)"/\1/g' ${canary} | grep -v -E "[\{\"A-Za-z:,\}]" | tr -d ' ')"
		if [[ "${curCanary}" != "${newCanary}" ]]
		then
			sed -i "s/${curCanary}/${newCanary}/g" ${canary}
			echo "Discord Canary's version has been updated"
		else
			echo "Discord Canary is set to the latest version"
		fi
	else
		tick=0
	fi
	if [[ -f ${stable} ]]
	then
		curStable="$(sed -r 's/"version": "([0-9.]*)"/\1/g' ${stable} | grep -v -E "[\{\"A-Za-z:,\}]" | tr -d ' ')"
		if [[ "${curStable}" != "${newStable}" ]]
		then
			sed -i "s/${curStable}/${newStable}/g" ${stable}
			echo "Discord's version has been updated"
		else
			echo "Discord is set to the latest version"
		fi
	else
		if [[ ${tick} == 0 ]]
		then
			echo "You appear not to have Discord or Discord installed"
			echo "Please check/adjust your paths and try again"
		fi
	fi

else
	echo "Unable to fetch the latest Discord versions"
	echo "Please check your internet connection and try again"
fi
