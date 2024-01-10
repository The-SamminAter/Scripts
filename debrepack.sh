#!/bin/bash

if [[ ! "$1" == *".deb" ]]
then
	echo "Usage: debrepack.sh <deb> [options] <additional debs>"
	echo " -c, --control		Edit the control file before repacking the deb"
	echo " -a, --all		Edit all files in the DEBIAN directory"
	echo ""
	echo "Note that if you plan on using an argument, it must be after the first deb, and before any additional debs"
	exit 1
fi

#WARNING: old code, it stays untouched as it works
FP="${1%%.deb}" #add incrementing system to not overwrite pre-existing dir
mkdir "${FP}"
cp "$1" "${FP}"
cd "${FP}"
if [[ "$(uname -m)" == *"iP"* ]] #iOS detection
then
	ar x *
else
	ar x -- *
fi
rm "debian-binary" "$(ls -a | grep '.deb')"
cFile=$(ls | grep "control.tar")
dFile=$(ls | grep "data.tar")
mkdir DEBIAN
tar xvf "${cFile}" -C DEBIAN/
tar xvf "${dFile}"
rm "${cFile}" "${dFile}"

#Add a little control+scripts edit feature
if [[ "$2" == "-c" || "$2" == "--control" ]]
then
		nano DEBIAN/control
		if [[ "$3" ]]
		then
			rerun=true
			arg="--control"
		fi
elif [[ "$2" == "-a" || "$2" == "--all" ]]
then
		nano DEBIAN/*
		if [[ "$3" ]]
		then
			rerun=true
			arg="--all"
		fi
elif [[ "$2" ]]
then
	rerun=true
fi

#Now for the remaking part
cd ../
rm $1
dpkg-deb -b ${FP}
rm -rf ${FP}

if [[ "${rerun}" == "true" ]]
then
		if [[ -z "${arg}" ]]
		then
			$0 "${@:2}"
		else
			$0 "$3" ${arg} "${@:4}" #Should work even if there is no $4
		fi
fi
