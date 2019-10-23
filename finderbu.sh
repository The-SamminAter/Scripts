echo "finderbu: for backing up and restoring Finder"
echo "(Backing up will overwrite any existing Finder backups in the same locations)"
echo "Would you like to backup [1] or restore [2] Finder?"
read -p "" answer;
	case $answer in
		#Backup
		[1]* )
		echo "Backing up Finder to two locations"
		#Backup 1/2
		echo "Backing up Finder to location 1: /System/Library/CoreServices/"
		zip /System/Library/CoreServices/Finder.app.zip /System/Library/CoreServices/Finder.app
		#Backup 1/2 check
		if [ -f /System/Library/CoreServices/Finder.app.zip ]; then
			echo "Backup 1 succesfull"
		else
			echo "Backup 1 unsuccesfull"
		fi
		#Backup 2/2
		echo "Backing up Finder to location 2: /Applications/"
		zip /Applications/Finder.app.zip /System/Library/CoreServices/Finder.app
		#Backup 2/2 check
		if [ -f /Applications/Finder.app.zip ]; then
			echo "Backup 2 succesfull"
		else
			echo "Backup 2 unsuccesfull"
		fi
		echo ""
		echo "Backup done"
		;;

		#Restore
		[2]* )
		echo "To work, this needs to be run with root permissions"
		echo "(As root or sudo)"
		echo "Before running this, please cd into the root directory of the target device"
		#Root check
		echo "Checking if this is being run as root"
		if [ $EUID -e 0 ]; then
			echo "This is being run as root"
		else
			echo "Not being run as root"
			echo "Exiting"
			exit 0
		fi
		#dir check
		echo "Checking if this is being run in a root directory"
		if [ -f System/Library/CoreServices/Finder.app/Contents/MacOS/Finder ]; then
			echo "This is being run in a root directory"
		else
			echo "Not being run in a root directory"
			echo "Exiting"
			exit 0
		fi
		#Backup check
		echo "Checking for Finder backup 1"
		if [ -f System/Library/CoreServices/Finder.app.zip ]; then
			echo "Backup 1 present"
			echo "Selecting backup 1 for restore"
			#I decided to try something new
			#echo "System/Library/CoreServices/Finder.app.zip" > bu-rs
			ln -s System/Library/CoreServices/ bu-rs
		else
			echo "Backup 1 not present"
			echo "Checking for backup 2"
			if [ -f /Applications/Finder.app.zip ]; then
				echo "Backup 2 present"
				echo "Selecting backup 2 for restore"
				ln -s Applications/ bu-rs
			else
				echo "Backup 2 not present"
				echo "No backups present"
				echo "Exiting"
				exit 0
			fi
		fi
		#Finder check, rename
		echo "Checking if Finder.app exists in System/Library/CoreServices/"
		if [ -f System/Library/CoreServices/Finder.app/Contents/MacOS/Finder ]; then
			echo "Finder exists"
			echo "Renaming Finder.app to Finder.o.app"
			mv bu-rs/Finder.app bu-rs/Finder.o.app
			echo "To use the renamed Finder, run the following (in the root dir):"
			echo "mv System/Library/CoreServices/Finder.o.app System/Library/CoreServices/Finder.app"
		else
			echo ""
		fi
		#Unzip and check
		echo "Restoring Finder backup"
		unzip bu-rs/Finder.app.zip -d System/Library/CoreServices/Finder.app
		if [ -f System/Library/CoreServices/Finder.app/Contents/MacOS/Finder ]; then
			echo "Finder backup restoration succesful"
		else
			echo "Finder backup restoration unsuccesfull"
			if [ -f System/Library/CoreServices/Finder.o.app/Contents/MacOS/Finder ]; then
				echo "Moving renamed finder back into position as Finder"
				mv System/Library/CoreServices/Finder.o.app System/Library/CoreServices/Finder.app
			else
				echo "The targe's macOS currently has no Finder, and is therefor unbootable"
				echo "I suggest re-installing macOS to restore functionality"
			fi
		fi
		#Delete bu-rs
		echo "Cleaning up"
		rm bu-rs
		if [ -f bu-rs/Finder.app.zip ]; then
			echo ""
		else
			echo "Clean-up unsuccesfull;"
			echo "Please run (as root) rm bu-rs"
			echo ""
		echo "Restore done"
	esac