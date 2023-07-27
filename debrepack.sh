#!/bin/bash

#This part is just debextract.sh
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
elif [[ "$2" ]]
then
        nano DEBIAN/*
fi

#Now for the remaking part
cd ../
rm $1
dpkg-deb -b ${FP}
rm -rf ${FP}
