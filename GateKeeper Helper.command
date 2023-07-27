#!/bin/bash
BLU='\033[1;40;34m'
GRN='\033[1;40;92m'
printf '\e[1;40;92m\n'
clear
echo "  ____________________________________________________________________________  "
echo " /   _____    ___    _____  _____  _   __ _____  _____  ____   _____  _____   \ "
echo "||  / ____|  / _ \  |_   _||  ___|| | / /|  ___||  ___||  _ \ |  ___||  _  \  ||"
echo "|| | /  __  / / \ \   | |  | |_   | |/ / | |_   | |_   | |_| || |_   | |_|  | ||"
echo "|| | | |_ \| |___| |  | |  |  _|  |   |  |  _|  |  _|  |  __/ |  _|  |  _  /  ||"
echo "|| | \__/ ||  ___  |  | |  | |___ | |\ \ | |___ | |___ | |    | |___ | | \ \  ||"
echo "||  \_____/|_|   |_|  |_|  |_____||_| \_\|_____||_____||_|    |_____||_|  \_| ||"
echo "||             ___   ____   _____  _____   ___   __   _   _____  _            ||"
echo "||\           / _ \ |  _ \ |_   _||_   _| / _ \ |  \ | | /  ___||_|          /||"
echo "||I\         | | | || |_| |  | |    | |  | | | ||   \| | \_ \_              /I||"
echo "||I/         | |_| ||  __/   | |   _| |_ | |_| || |\   | __\  \  _          \I||"
echo "||/           \___/ |_|      |_|  |_____| \___/ |_| \__||_____/ |_|     v2.2 \||"
echo "||                                                                            ||"
echo "|| 1) Disable GateKeeper system-wide                                          ||"
echo "|| 2) Enable GateKeeper system-wide                                           ||"
echo "|| 3) Disable GateKeeper for a specific app                                   ||"
printf " \____________________________________________________________________________/ \e[1;40m\n"
read -p "Please chose an option: " answer;
case $answer in
    "1")
		echo -e "${BLU}You chose to disable GateKeeper globally"
		if [ $EUID -ne 0 ]; then
			echo "Please enter your password to proceed:"
		else
			echo "No password required"
		fi
		sudo spctl --master-disable
		echo -e "${GRN}Done"
		;;
	"2")
		echo -e "${BLU}You chose to enable GateKeeper globally${NC}"
		if [ $EUID -ne 0 ]; then
			echo "Please enter your password to proceed:"
		else
			echo "No password required"
		fi
		sudo spctl --master-enable
		echo -e "${GRN}Done"
		;;
	"3")
		echo -e "${BLU}You chose to disable GateKeeper for a specific app${NC}"
		read -e -p "Please drag and drop the app here, and then press enter: " FILEPATH
		if [ $EUID -ne 0 ]; then
			echo "Please enter your password to proceed:"
		else
			echo "No password required"
		fi
		sudo xattr -rd com.apple.quarantine "$FILEPATH"
		echo -e "${GRN}Done"
		;;
	*) 
		echo -e "${BLU}No option selected"
		echo -e "${GRN}Exiting GateKeeper Helper"
		;;
esac
#done