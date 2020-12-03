#!/bin/bash
echo "So InDesign is being stupid, huh?"
echo "Lets see if deleting some of their files fixes it for whatever reason"
rm -rf ~/Library/Caches/Adobe\ InDesign/
rm -rf ~/Library/Preferences/Adobe\ InDesign/
echo "Done, waiting 5 seconds"
sleep 5
echo "Starting Adobe InDesign"
INDIR=$(ls /Applications/ | grep InDesign)
open "/Applications/${INDIR}/${INDIR}.app"
