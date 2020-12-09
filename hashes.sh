#!/bin/bash
#Get values:
SIZE=$(wc -c <"${1}" | tr -d ' ')
MD5=$(md5sum "${1}")
SHA1=$(sha1sum "${1}")
SHA256=$(sha256sum "${1}")
#Hash-print section
echo ""
echo "Name: ${1}"
echo "Size: ${SIZE}"
echo "MD5sum: ${MD5%% *}"
echo "SHA1: ${SHA1%% *}"
echo "SHA256: ${SHA256%% *}"
echo ""
