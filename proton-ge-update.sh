#!/bin/bash
#shellcheck disable=SC2164
#Downloads the latest Proton-GE release and extracts adds it to Steam and Lutris
#This code is made under the assumptions that  Proton-GE's .tar.gz structure and naming scheme (along with GitHub) will stay the same
#So use it at your own risk (but, I mean, what's the worst that's gonna happen)
uDir="$(cd && pwd)"
sDir="${uDir}/.steam/root/compatibilitytools.d/"
lDir="${uDir}/.local/share/lutris/runners/wine/"
#I realized after finishing that that this could have been done better - no matter
#Cleanup - cleans up the temporary directories, but even if the user ^Cs the script
cleanup()
{
	printf "Cleaning up..."
	if [[ -d "${uDir}/.tmp.2" ]]
	then
		rm -rf "${uDir}/.tmp.2"
	elif [[ -d "${uDir}/.tmp" ]]
	then
		rm -rf "${uDir}/.tmp"
	fi
	echo "done"
	exit
}
trap "cleanup" EXIT

if [[ ! $1 ]]
then
	#This just gets the latest version, pre-release or not
	version="$(curl -s -L https://github.com/GloriousEggroll/proton-ge-custom/releases/ | grep Proton | grep Released | head -1 | awk -F'>' '{print $2}' | awk -F' ' '{print $1}')"
	#Please note that there are certain cases where this doesn't work, such as with Proton-GE release v7.2-GE-3-test-2
	#This is because the version used in the .tar.gz's filename doesn't match, and actually is v7.2-GE-3-test-3, and apparently 7-14.
	if [ "${version}" == "" ]
	then
		echo "Latest version could not be fetched. Please try running this script again with --alt"
		exit
	else
		echo "Latest version: ${version}"
	fi
elif [[ "$1" == "-a" ]] || [[ "$1" == "--alt" ]]
then
	#Alternative way:
	version="$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases | grep tag_name | head -1 | awk -F': "' '{print $2}' | awk -F'"' '{print $1}')"
	#Alternatives to the alternative:
	#Original alternative method:
	#version="$(curl -s -L https://github.com/GloriousEggroll/proton-ge-custom/releases/latest | grep Proton | awk -Ftag/ '{print $2}' | awk -F'"' '{print $1}' | grep Proton | head -1)"
	#Using GitHub API and some magic sed from gist lukechilds/a83e1d7127b78fef38c2914c4ececc3c:
	#version="$(curl "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases" | grep "tag_name" | sed -E 's/.*"([^"]+)".*/\1/' | head -1)"
	echo "Latest version: ${version}"
elif [[ "$1" == "-l" || "$1" == "--list" ]]
then
	if [[ "$(which tree)" == "tree not found" ]]
	then
		echo "tree needs to be installed for this feature"
	else
		echo "Versions of Proton-GE installed for Steam:"
		tree "${sDir}" -L 1 -i | grep Proton | grep GE
		echo "Versions of Proton-GE installed for Lutris:"
		tree "${lDir}" -L 1 -i | grep Proton | grep GE
	fi
	exit
elif [[ "$1" == "-r" || "$1" == "--remove" ]]
then
#The if statements don't work if the 2>&1 is altered or removed
#I spent way too long finding a solution for that
	if [[ "$(chmod 0755 -R ${sDir}/$2 2>&1 | head -c20)" == "chmod: cannot access" ]]
	then
		echo "$2 doesn't appear to be installed for Steam"
	else
		rm -r "${sDir}/$2"
		echo "$2 successfully removed for Steam"
	fi
	if [[ "$(chmod 0755 -R ${lDir}/$2 2>&1 | head -c20)" == "chmod: cannot access" ]]
	then
		echo "$2 doesn't appear to be installed for Lutris"
	else
		rm -r "${lDir}/$2"
		echo "$2 successfully removed for Lutris"
	fi
	exit
elif [[ "$(echo $1 | head -c1)" == "-" ]]
then
	echo "$1 is not an understood argument"
	echo "Understood arguments are as follows:"
	echo "{version}             Installs a specific version of Proton-GE"
	echo "-a/--alt              Fetches (alternative method) and installs the latest version of Proton-GE"
	echo "-l/--list             Lists installed versions of Proton-GE"
	echo "-r/--remove {version} Removes a specified installed version of Proton-GE"
	exit
else
	version="$1"
	echo "Version: ${version}"
fi
#There's probably a way to do this (get the version) properly with the GitHub API, but whatever
if [[ -d "${uDir}/.tmp" ]]
then
	mkdir "${uDir}/.tmp.2"
	cd "${uDir}/.tmp.2"
else
	mkdir "${uDir}/.tmp"
	cd "${uDir}/.tmp"
fi

#Allow older versions to still be used:
if [[ "$(echo ${version} | head -c2)" == "GE" ]]
then
	proton="${version}"
else
	proton="Proton-${version}"
fi
#Check if $version of Proton-GE is already installed before downloading:
#If it's (1) installed for Steam and Lutris OR (2) installed for Steam and Lutris doesn't exist OR (3) is installed for Lutris and Steam doesn't exist
if [[ -d "${sDir}/${proton}" && -d "${lDir}/${proton}" ]] || [[ -d "${sDir}/${proton}" && ! -d "${uDir}/.local/share/lutris" ]] || [[ -d "${lDir}/${proton}" && ! -d "${uDir}/.steam/root" ]]
then
	echo "Already installed: ${version}"
elif [[ ! -d "${uDir}/.steam/root" ]] && [[ ! -d "${uDir}/.local/share/lutris" ]]
then
	echo "Neither Steam nor Lutris appear to be installed under the current user's account"
else
	echo "Starting download..."
	curl -O -L "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${proton}.tar.gz"
	if [[ -d "${uDir}/.steam/root" ]]
	then
		if [[ ! -d "${sDir}" ]]
		then
			mkdir "${sDir}"
		fi
		if [[ -d "${sDir}/${proton}" ]]
		then
			echo "${proton} is already present for Steam"
		else
			echo "Installing ${proton} for Steam"
			tar -xf "${proton}.tar.gz" -C "${sDir}"
		fi
	else
		echo "Steam does not appear to be installed"
	fi
	if [[ -d "${uDir}/.local/share/lutris" ]]
	then
		if [[ ! -d "${uDir}/.local/share/lutris/runners" ]]
		then
			mkdir "${uDir}/.local/share/lutris/runners"
			mkdir "${lDir}" #${uDir}/.local/share/lutris/runners/wine
		elif [[ ! -d "${lDir}" ]]
		then
			mkdir "${lDir}"
		fi
		if [[ -d "${lDir}/${proton}" ]]
		then
			echo "${proton} is already present for Lutris"
		else
			echo "Installing ${proton} for Lutris"
			tar -xf "${proton}.tar.gz" -C "${lDir}"
			echo "Patching ${proton} for Lutris"
			cd "${lDir}/${proton}"
			mv files/* ./
		fi
	else
		echo "Lutris does not appear to be installed"
	fi
fi
