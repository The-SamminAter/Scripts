#!/bin/bash
"/Applications/The Unarchiver.app/Contents/MacOS/The Unarchiver" "${1}"
FP=$(echo "${1%%.deb}")
rm "${FP}/debian-binary"
cFile=$(ls "${FP}" | grep "control.tar")
dFile=$(ls "${FP}" | grep "data.tar")
"/Applications/The Unarchiver.app/Contents/MacOS/The Unarchiver" "${FP}/${cFile}"
"/Applications/The Unarchiver.app/Contents/MacOS/The Unarchiver" "${FP}/${dFile}"
rm "${FP}/${cFile}" "${FP}/${dFile}"
mv "${FP}/control" "${FP}/DEBIAN"
mv "${FP}/data/"* "${FP}/"
rm -rf "${FP}/data"
