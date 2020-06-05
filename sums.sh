#!/bin/bash

#This seems to be completely broken, and I can't figure out/don't know why

#This gives you copy-pasteable MD5, SHA1, and SHA256 values
#I made this for my modification of unc0ver, but it has other uses, like for my repo
#Method for getting only the sums from here: http://stackoverflow.com/questions/1405611/ddg#1405641
#if [ -z "$file" ]; then
  read -e -r -p "Please drag and drop the file here, and then press enter: " DEBDIR;
#else
#  DEBDIR="$file"
#fi
MD5L=$(md5sum "${DEBDIR}")
MD5S="${MD5LONG:0:32}"
SHA1L=$(sha1sum "${DEBDIR}")
SHA1S="${SHA1LONG:0:40}"
SHA256L=$(sha256sum "${DEBDIR}")
SHA256S="${SHA256LONG:0:64}"
echo "MD5sum: ${MD5S}"
echo "SHA1: ${SHA1S}"
echo "SHA256: ${SHA256S}"
