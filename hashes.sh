#!/bin/bash
#Easy printing of sums for Packages file
echo "MD5sum: $(md5sum $1 | awk -F' ' '{print $1}')"
echo "SHA1: $(sha1sum $1 | awk -F' ' '{print $1}')"
echo "SHA256: $(sha256sum $1 | awk -F' ' '{print $1}')"
