#!/bin/bash

#Credit: The_SamminAter - originally by NoW4U2Kid - shout out to sudo for his work on patches
#Note: this isn't the whole script. Just the meat - the time-heavy patching part
#Note 2: Filza, for some unexplained reason, ignores shebangs and only runs scripts on sh. Short of replacing or symlinking that, this script will never achieve the intended effect of replacing the nasty messy slow sed work that the original Filza does. Oh well, at least it works well, and now GNU Strings is on iOS.

#Ok - lets remake this into an array
#v2.4-2 patches:
pathsSearched=("/Library/MobileSub" "/Library/dpkg" "/Library/Sn" "/Library/Th" "/Library/Application" "/Library/LaunchD" "/Library/PreferenceB" "/Library/PreferenceL" "/Library/Framework" "/Library/Act" "/Library/Flip" "/Library/Switch" "/Library/Hyp" "/bin/sh" "/usr/lib" "/usr/bin" "/private/var/mobile/Library/Preference" "/var/mobile/Library/Preference" "/var/mobile/Library/Application" "/Application" "/User/Library")
pathsReplaced=("/var/LIY/MobileSub" "/Library/dpkg" "/var/LIY/Sn" "/var/LIY/Th" "/var/LIY/Application" "/var/LIY/LaunchD" "/var/LIY/PreferenceB" "/var/LIY/PreferenceL" "/Library/Framework" "/var/LIY/Act" "/var/LIY/Flip" "/var/LIY/Switch" "/var/LIY/Hyp" "/var/sh" "/var/lib" "/var/bin" "/private/var/mobile/Library/Preference" "/var/mobile/Library/Preference" "/var/jb/vmo/Library/Application" "/Application" "/var/jb/UsrLb")
#Extra paths, rarely used, but for when developers decide not to use leading /s
pathsSearched+=("Library/MobileSub" "Library/dpkg" "Library/Sn" "Library/Th" "Library/Application" "Library/LaunchD" "Library/PreferenceB" "Library/PreferenceL" "Library/Framework" "Library/Act" "Library/Flip" "Library/Switch" "Library/Hyp" "bin/sh" "usr/lib" "usr/bin" "private/var/mobile/Library/Preference" "var/mobile/Library/Preference" "var/mobile/Library/Application" "Application" "User/Library")
pathsReplaced+=("var/LIY/MobileSub" "Library/dpkg" "var/LIY/Sn" "var/LIY/Th" "var/LIY/Application" "var/LIY/LaunchD" "var/LIY/PreferenceB" "var/LIY/PreferenceL" "Library/Framework" "var/LIY/Act" "var/LIY/Flip" "var/LIY/Switch" "var/LIY/Hyp" "var/sh" "var/lib" "var/bin" "private/var/mobile/Library/Preference" "var/mobile/Library/Preference" "var/jb/vmo/Library/Application" "Application" "var/jb/UsrLb")
exceptionsSearched=("/var/lib/libobjc.A.dylib" "/var/lib/libc++.1.dylib" "/var/lib/libSystem.B.dylib" "/var/lib/libstdc++.6.dylib" "/var/lib/libMobileGestalt.dylib" "/var/lib/system/" "/var/lib/dyld" "/var/lib/swift" "/var/lib/libswift")
exceptionsReplaced=("/usr/lib/libobjc.A.dylib" "/usr/lib/libc++.1.dylib" "/usr/lib/libSystem.B.dylib" "/usr/lib/libstdc++.6.dylib" "/usr/lib/libMobileGestalt.dylib" "/usr/lib/system/" "/usr/lib/dyld" "/usr/lib/swift" "/usr/lib/libswift")
patches="${#pathsSearched[@]}"
exceptions="${#exceptionsReplaced[@]}"

#######GNARLY CODE AHEAD#######
##UPDATE DEFINITIONS 'TWO LINER'
##Real nasty. But hey, why spend a min doing something when you can spent twenty automating it
##Yes, line one has to be a var. The numbers are the sections of the file with our wanted patches
#values=$(cat "<path to .script>" | head -123 | tail -23 | grep sed | awk -F's#' '{print $2}' | cut -f1 -d'g')
#printf '"' && echo ${values} | cut -f1 -d'#' | tr -s '\n' '0' | sed 's/0/" "/g' | head -c-3 | sed 's/dpk/dpkg/g'
##^f1 for origional, f2 for replacements
##IMPORTANT NOTE: the letter g gets cut off. Usually patches don't have that letter. Hence the dpkg sed line

#Hopefully there are no long strings in a binary or dylib that contain spaces and paths, hahahaha

#If the file has a filetype of binary, isn't a plist, and isn't a preinst/etc.
#(the original script) is so unreadable
#We can just put this in for the time being:
file="$1"
if [[ ! -f "${file}" ]]
then
    echo "File doesn't exist"
fi

#Patching
#Source for dd magic: https://unix.stackexchange.com/a/214824
n=0 #Variable should be renamed
while [[ "${n}" != "${patches}" ]]
do
    #We could make this into an array, but at some point all of the operations needed would probably be slower than just head and tail-ing
    echo "parse: ' ${pathsSearched[$n]}'"
    offsets=$(strings -t d "${file}" | grep -F " ${pathsSearched[$n]}" | awk -F' ' '{print $1}')
    #Yes that grep has a space before the variable, no do not touch it. It is very important
    #echo "offsets: ${offsets}"
    if [[ -z "${offsets}" ]]
    then
        : #I know I know
    else
        echo "${pathsReplaced[$n]}" | head -c -1 > /tmp/rootlessdd #The pipe is to remove 0x0a from being written to the end of the file
        offsetQuantity=$(echo "${offsets}" | wc -l)
        echo "offsetQuantity: ${offsetQuantity}"
        offsetPosition=1
        while [[ "${offsetPosition}" -le " ${offsetQuantity}" ]]
        do
            #echo "offsets: ${offsets}"
            currentOffset=$(echo "${offsets}" | head -${offsetPosition} | tail -1)
            echo "currentOffset: ${currentOffset}"
            dd if="/tmp/rootlessdd" of="${file}" obs=1 seek=${currentOffset} conv=notrunc status=none
            let offsetPosition++
            unset currentOffset
        done
        rm /tmp/rootlessdd
    fi
    let n++
    unset offsets offsetQuantity offsetPosition
done
unset n

echo "##############"
echo "# EXCEPTIONS #"
echo "##############"

#Unpatching/patching back the exceptions
n=0
while [[ "${n}" != "${exceptions}" ]]
do
    echo "parse: ' ${exceptionsSearched[$n]}'"
    offsets=$(strings -t d "${file}" | grep -F " ${exceptionsSearched[$n]}" | awk -F' ' '{print $1}')
    if [[ -z "${offsets}" ]]
    then
        :
    else
        echo "${exceptionsReplaced[$n]}" | head -c -1 > /tmp/rootlessdd
        offsetQuantity=$(echo "${offsets}" | wc -l)
        echo "offsetQuantity: ${offsetQuantity}"
        offsetPosition=1
        while [[ "${offsetPosition}" -le "${offsetQuantity}" ]]
        do
            #echo "offsets: ${offsets}"
            currentOffset=$(echo "${offsets}" | head -${offsetPosition} | tail -1)
            echo "currentOffset: ${currentOffset}"
            dd if="/tmp/rootlessdd" of="${file}" obs=1 seek=${currentOffset} conv=notrunc status=none
            let offsetPosition++
            unset currentOffset
        done
        rm /tmp/rootlessdd
    fi
    let n++
    unset offsets offsetQuantity offsetPosition
done
unset n

#Codesigning for Dopamine
if [[ "${file}" == *".dylib" ]]
then
    ldid -S "${file}"
fi
