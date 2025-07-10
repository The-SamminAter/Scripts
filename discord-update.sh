#!/bin/bash
#This updates discord's (stable and canary) alleged version number, because I'm tired of having to do it myself
#This also updates all installed modules, as discord is shipping out updates to those several times a day, and with firejail+OpenAsar updating is broken
#This script was made possible by httptap and OpenAsar
#shellcheck disable=SC2115
#^Warns about unintended behaviour that I intend
if [[ ${UID} != 0 ]]
then
	echo "This script needs administration permissions"
	exit 1
fi

user=$(who am i | awk -F' ' '{print $1}')
canary=/opt/discord-canary/resources/build_info.json
stable=/opt/discord/resources/build_info.json
newCanary="$(curl -s 'https://discord.com/api/updates/canary?platform=linux' | sed -r 's/\{"name": "([0-9.]*)".*/\1/g')"
newStable="$(curl -s 'https://discord.com/api/updates/stable?platform=linux' | sed -r 's/\{"name": "([0-9.]*)".*/\1/g')"
modulesCanary="/home/${user}/.config/discordcanary/${newCanary}/modules/"
modulesStable="/home/${user}/.config/discord/${newStable}/modules/"

if [[ -z ${newCanary} && -z ${newStable} ]]
then
	echo "Unable to fetch the latest Discord versions"
	echo "Please check your internet connection and try again"
	exit 1
fi

if [[ -f ${canary} ]]
then
	if [[ ! -z ${newCanary} ]]
	then
		curCanary="$(sed -r 's/"version": "([0-9.]*)"/\1/g' ${canary} | grep -v -E "[\{\"A-Za-z:,\}]" | tr -d ' ')"
		if [[ "${curCanary}" != "${newCanary}" ]]
		then
			sed -i "s/${curCanary}/${newCanary}/g" ${canary}
			mv "/home/${user}/.config/discordcanary/${curCanary}" "/home/${user}/.config/discordcanary/${newCanary}"
			echo "Discord Canary's version has been updated"
		else
			echo "Discord Canary is already set to the latest version"
		fi
	fi

	#modules=$(curl -s "https://discord.com/api/modules/canary/versions.json?host_version=${newCanary}&platform=linux" | jq 'to_entries[] | .key' | tr -d '"')
	#There are more modules listed than are actually used
	modules=$(cat "${modulesCanary}/installed.json" | jq 'to_entries[] | .key' | tr -d '"')
	for module in ${modules}
	do
		curModule=$(cat "${modulesCanary}/installed.json" | jq ".${module}.installedVersion")
		newModule=$(curl -s "https://discord.com/api/modules/canary/versions.json?host_version=${newCanary}&platform=linux" | jq ".${module}")
		if [[ ${newModule} -ne ${curModule} ]]
		then
			printf "Updating  ${module} ${curModule} -> ${newModule}\r"
			#Just as a side note, the URL the client uses to download (which redirects to the cdn is the following:
			#https://discord.com/api/modules/canary/${module}/${newModule}?host_version=${newCanary}&platform=linux
			curl -s "https://canary.dl2.discordapp.net/apps/linux/${newCanary}/modules/${module}-${newModule}.zip" -O --output-dir "${modulesCanary}/pending/"
			echo "Unpacking ${module} ${curModule} -> ${newModule}"
			rm -rf "${modulesCanary}/${module}/"*
			7z x "${modulesCanary}/pending/${module}-${newModule}.zip" -o"${modulesCanary}/${module}/" 2>&1 > /dev/null
			rm "${modulesCanary}/pending/${module}-${newModule}.zip"
			cat "${modulesCanary}/installed.json" | jq ".${module}.installedVersion = ${newModule}" > "${modulesCanary}/installed.new"
			mv "${modulesCanary}/installed.new" "${modulesCanary}/installed.json"
		else
			echo "${module} is already up to date"
		fi
	done
else
	tick=0
fi

if [[ -f ${stable} ]]
then
	#Just formatting things
	if [[ -f ${canary} ]]
	then
		echo ""
	fi

	if [[ ! -z ${newStable} ]]
	then
		curStable="$(sed -r 's/"version": "([0-9.]*)"/\1/g' ${stable} | grep -v -E "[\{\"A-Za-z:,\}]" | tr -d ' ')"
		if [[ "${curStable}" != "${newStable}" ]]
		then
			sed -i "s/${curStable}/${newStable}/g" ${stable}
			mv "/home/${user}/.config/discord/${curStable}" "/home/${user}/.config/discordcanary/${newStable}"
			echo "Discord Stable's version has been updated"
		else
			echo "Discord Stable is already set to the latest version"
		fi
	fi

	modules=$(cat "${modulesStable}/installed.json" | jq 'to_entries[] | .key' | tr -d '"')
	for module in ${modules}
	do
		curModule=$(cat "${modulesStable}/installed.json" | jq ".${module}.installedVersion")
		newModule=$(curl -s "https://discord.com/api/modules/stable/versions.json?host_version=${newStable}&platform=linux" | jq ".${module}")
		if [[ ${newModule} -ne ${curModule} ]]
		then
			printf "Updating  ${module} ${curModule} -> ${newModule}\r"
			curl -s "https://stable.dl2.discordapp.net/apps/linux/${newStable}/modules/${module}-${newModule}.zip" -O --output-dir "${modulesStable}/pending/"
			echo "Unpacking ${module} ${curModule} -> ${newModule}"
			rm -rf "${modulesStable}/${module}/"*
			7z x "${modulesStable}/pending/${module}-${newModule}.zip" -o"${modulesStable}/${module}/" 2>&1 > /dev/null
			rm "${modulesStable}/pending/${module}-${newModule}.zip"
			cat "${modulesStable}/installed.json" | jq ".${module}.installedVersion = ${newModule}" > "${modulesStable}/installed.new"
			mv "${modulesStable}/installed.new" "${modulesStable}/installed.json"
		else
			echo "${module} is already up to date"
		fi
	done
else
	if [[ ${tick} == 0 ]]
	then
		echo "You appear not to have Discord Stable or Discord Canary installed"
		echo "Please check/adjust your paths and try again"
		exit 1
	fi
fi


