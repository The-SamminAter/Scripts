#!/usr/bin/env bash

#WARNING: check for wc, cut, grep, and grep's -F

cd "/Volumes/"
found=false
for parts in *
do
	if [[ -d "${parts}/Backups.backupdb/Kim’s MacBook Pro/" ]]
	then
		cd "${parts}"
		echo "Found disk"
		found=true
	fi
done
if [[ ! ${found} ]]
then
	echo "Unable to find disk"
	echo "Please make sure it's connected and shows up in Finder"
	exit 1
fi
cd "Backups.backupdb/Kim’s MacBook Pro/" || exit 1

#This next part is going to rely on the fact that one can't have both a dir and a file named identically
#The * means that every dir gets fed into find - meaning we still get the full path (minus the ./ at the start), but in alphabetical order
dump="../.backup_dump"
found="../.backup_found"
notFound="../.backup_notfound"
linked="../.backup_linked"
if [[ -f "${dump}" ]]
then
	tick=30
	echo "You've previously ran this app"
	echo "While it is not suggested to run this multiple times, I won't stop you"
	echo "If not every link is fixed, running it again likely won't solve the issue"
	echo "Please contact Sam"
	echo "You have ${tick} seconds to quit the app if you don't want to run it again"
	while [[ ${tick} -ge 0 ]]
	do
		printf "${tick}"
		sleep 0.25
		printf "."
		sleep 0.25
		printf "."
		sleep 0.25
		printf "."
		sleep 0.25
		let tick--
	done
	echo ""
	rm "${dump}" "${found}" "${notFound}" "${linked}"
fi
echo "Creating dump of backup directory structure"
find * >> "${dump}"
if [[ $(wc -l < "${dump}") -gt 900000 ]] && [[ $(wc -l < "${dump}") -lt 1000000 ]]
then
	echo "Dump created successfully, proceeding"
else
	echo "Something went wrong creating the dump"
	echo "Expected item count: ~950,000"
	echo "Dump item count: $(wc -l < ${dump})"
	echo "Please contact Sam"
	exit 1
fi

#With this dump, we check if each 'item' is empty - this notably works on dirs too
#If it isn't, we write it to a file, and if it is we read from the file to find the last non-empty item, and symlink to it
#WARNING: do previous run checking
#TODO: so we do back checking, we may also have to do forward checking??? verify
# echo "Note: some files may be missing because macOS excluded the file from being backed up, due to it being a stock/standard file"
while read item
do
# 	#sleep 0.005
	itemLocal="$(echo ${item} | cut -d'/' -f2-)" #Gives us the item path minus the date dir
	if [[ -s "${item}" ]]
	then
		echo "${item}" >> "${found}"
	else
		lastMatch="$(grep -F "${itemLocal}" ${found} | tail -1)" #DANGER: not exact match/don't check for line-end
		lastLocal="$(echo ${lastMatch} | cut -d'/' -f2-)"
		if [[ -z $(echo "${itemLocal}" | grep -F "${lastLocal}") ]]
		then
			lastMatch=""
		fi
		if [[ -z "${lastMatch}" ]]
		then
			if [[ "${itemLocal}" != "Macintosh HD/usr"* ]] && [[ "${itemLocal}" != "Macintosh HD/Applications/Safari.app"* ]] && [[ "${itemLocal}" != "Macintosh HD/private"* ]] && [[ "${itemLocal}" != "Macintosh HD/Library"* ]] && [[ "${itemLocal}" != "Macintosh HD/System"* ]] && [[ "${itemLocal}" != "Macintosh HD/.DocumentRevisions-V100"* ]] && [[ "${itemLocal}" != "Macintosh HD/Applications/Microsoft Outlook.app"* ]] #Whitelist/don't show on screen. Some of these, namely ~/Library, are rather important
			then
				echo "No original found for ${item}"
			fi
			echo "${item}" >> "${notFound}"
		else
			#WARNING:
			#- verify this works in finder
			#- verify elevated permissions aren't required
			rm "${item}"
			ln -s "${lastMatch}" "${item}"
			echo "Creating link ${lastMatch} -> ${item}"
			echo "${lastMatch} -> ${item}" >> "${linked}"
		fi
	fi
done < "${dump}"


#Forward-checking (kinda crap?):
#sleep 10
echo "Second check: forward-linking"
sleep 3
while read item
do
	itemLocal="$(echo ${item} | cut -d'/' -f2-)"
	if [[ -s "${item}" ]]
	then
		:
	else
		firstMatch="$(grep -F "${itemLocal}" ${found} | head -1)"
		firstLocal="$(echo ${firstMatch} | cut -d'/' -f2-)"
		if [[ -z $(echo "${itemLocal}" | grep -F "${firstLocal}") ]]
		then
			firstMatch=""
		fi
		if [[ -z "${firstMatch}" ]]
		then
			if [[ "${itemLocal}" != "Macintosh HD/usr"* ]] && [[ "${itemLocal}" != "Macintosh HD/Applications/Safari.app"* ]] && [[ "${itemLocal}" != "Macintosh HD/private"* ]] && [[ "${itemLocal}" != "Macintosh HD/Library"* ]] && [[ "${itemLocal}" != "Macintosh HD/System"* ]] && [[ "${itemLocal}" != "Macintosh HD/.DocumentRevisions-V100"* ]] && [[ "${itemLocal}" != "Macintosh HD/Applications/Microsoft Outlook.app"* ]] #Whitelist/don't show on screen. Some of these, namely ~/Library, are rather important
			then
				echo "No original found for ${item}"
			fi
			echo "${item}" >> "${notFound}2"
		else
			#WARNING:
			#- verify this works in finder
			#- verify elevated permissions aren't required
			rm "${item}"
			#TODO: remove entry from ${notFound}
			ln -s "${firstMatch}" "${item}"
			echo "Creating link ${firstMatch} -> ${item}"
			echo "${firstMatch} -> ${item}" >> "${linked}"
		fi
	fi
done < "${dump}"
