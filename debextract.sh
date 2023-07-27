#!/bin/bash
FP="${1%%.deb}" #add incrementing system to not overwrite pre-existing dir
mkdir "${FP}"
cp "$1" "${FP}"
cd "${FP}"
ar x *
rm "debian-binary" "$(ls -a | grep '.deb')"
cFile=$(ls | grep "control.tar")
dFile=$(ls | grep "data.tar")
mkdir DEBIAN
tar xvf "${cFile}" -C DEBIAN/
tar xvf "${dFile}"
rm "${cFile}" "${dFile}"
