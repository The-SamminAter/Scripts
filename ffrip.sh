#!/bin/bash
#Simple wrapper for ffmpeg for m3u8 ripping - mainly so I don't have to look through my bash history every time I want to download something
if [[ "$1" == *".mpd"* ]]
then
    echo "Warning: ffmpeg is useless against Widevine content without a key"
    echo "Use StreamFab instead"
elif [[ "$1" == *"http"* ]] && [[ "$2" ]]
then
    ffmpeg -user_agent 'Mozilla/5.0 (Windows NT 10.0; rv:110.0) Gecko/20100101 Firefox/110.0' -i "$1" -headers $'Mozilla/5.0 (Windows NT 10.0; rv:110.0) Gecko/20100101 Firefox/110.0' -c copy "$2"
elif [[ "$1" == *"http"* ]]
then
    ffplay -user_agent 'Mozilla/5.0 (Windows NT 10.0; rv:110.0) Gecko/20100101 Firefox/110.0' -i "$1" -headers $'Mozilla/5.0 (Windows NT 10.0; rv:110.0) Gecko/20100101 Firefox/110.0'
else
    echo "arg1 was not a url"
    echo "Nothing to do"
fi
