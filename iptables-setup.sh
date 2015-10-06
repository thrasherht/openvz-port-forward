#!/bin/bash
# A menu driven shell script sample template 
## ----------------------------------
# Step #1: Define variables
# ----------------------------------
#function for color coding
RED=`tput setaf 1`
GREEN=`tput setaf 2`
PURPLE=`tput setaf 5`
WHITE=`tput setaf 7`
STD=`tput sgr0`
BOLD=`tput bold`
#Primary IP to forwart ports from
SERVERIP="67.227.240.49"
NETCONFIG="/etc/network/interfaces"
# ----------------------------------
# Step #2: User defined function
# ----------------------------------
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

restore_check(){
	#Check for presence of iptables restore in network configuration.
			echo "Checking ${RED}$NETCONFIG${STD} for presence of iptables-restore command"
			echo ""
			echo ""
		if grep -Fq "iptables-restore" $NETCONFIG ; then
			show_menus
		else
			echo "${RED}IPTables Restore directive not found in network configuration"
			echo "Please setup ${WHITE}iptables-restore${RED} in your network configuration${STD}"
			exit
		fi
}
#Used to add new port to iptables for forwarding 
one(){
	#Setup variables for backups information
	DATE=`date +%F`
	TIME=`date +%R`
	BACKUPRULES="/backup/iptables-backups/iptables.rules.$DATE.$TIME"
	
	#Ask for input of port forward configuration
	read -e -p "${GREEN}Enter private instance IP: " DIP
	read -e -p "Enter destination port: " DPORT
	read -e -p "Enter external port to be forwarded: " EPORT
	
	#Make a dated backup of the current configuration
	echo "${RED}Saving Backup of iptables rules"
		cp -a /etc/iptables.rules $BACKUPRULES
	echo "${GREEN}Rules saved to $BACKUPRULES"
	
	#push update to iptables
	echo "${PURPLE}Adding rule to live iptables configuration"
	iptables -t nat -A PREROUTING -i vmbr0  -p tcp -m tcp -d $SERVERIP --dport $EPORT -j DNAT --to-destination $DIP:$DPORT
	
	#save new configuration to file
	echo "${GREEN}Saving new configuration to persistant file"
	iptables-save > /etc/iptables.rules
	pause
}
 
#Used to restore iptables configuration from backup
two(){

	#Change to backup directory
	cd /backup/iptables-backups/

	#Set Variables for restoration script
	prompt="Please select a file:"
	options=( $(ls) )
	
	
	PS3="$prompt "
	select opt in "${options[@]}" "Quit" ; do
	    if (( REPLY == 1 + ${#options[@]} )) ; then
	        exit

	    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
	        echo  "Restoring iptables configuration file from $opt"
	        mv /etc/iptables.rules /etc/iptables.rules.mostrecent
	        cp -af $opt /etc/iptables.rules
	        break

	    else
	        echo "Invalid option. Try another one."
	    fi
	done

}
 
# function to display menus
show_menus() {
	clear
	echo "${GREEN}~~~~~~~~~~~~~~~~~~~~~"	
	echo " M A I N - M E N U"
	echo "~~~~~~~~~~~~~~~~~~~~~${STD}"
	echo "${WHITE}1. ${PURPLE}Forward a port to an instance"
	echo "${WHITE}2. ${PURPLE}Restore iptables configuration from file${STD}"
	echo "${WHITE}3. ${RED}Exit${STD}"
}
# read input from the keyboard and take a action
# invoke the one() when the user select 1 from the menu option.
# invoke the two() when the user select 2 from the menu option.
# Exit when user the user select 3 form the menu option.
read_options(){
	local choice
	read -p "Enter choice [ 1 - 3] " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 1
	esac
}
 
# ----------------------------------------------
# Step #3: Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP
 
# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------
while true
do
	restore_check
	show_menus
	read_options
done
