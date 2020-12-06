#!/bin/bash
echo "So InDesign is being stupid, huh?"
echo "Lets see if deleting some of its files fixes it for whatever reason"
rm -rf ~/Library/Caches/Adobe\ InDesign/
rm -rf ~/Library/Preferences/Adobe\ InDesign/
echo "Done, waiting 2 seconds because ¯\_(ツ)_/¯"
sleep 2
echo "Starting Adobe InDesign"
#I know that I shouldn't be trying to parse ls, but for this I don't care
INDIR=$(ls /Applications/ | grep InDesign)
open "/Applications/${INDIR}/${INDIR}.app
#If you want to get more information/feedback from InDesign, use line 13 instead of 11
#"/Applications/${INDIR}/${INDIR}.app/Contents/MacOS/${INDIR}"
