#!/bin/bash
###############################################################
### Arch Linux Anywhere Install Script
###
### Copyright (C) 2016  Dylan Schacht
###
### By: Dylan Schacht (deadhead)
### Email: deadhead3492@gmail.com
### Webpage: http://arch-anywhere.org
###
### Any questions, comments, or bug reports may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v2.0
###
### This program is free software; you can redistribute it and/or
### modify it under the terms of the GNU General Public License
### as published by the Free Software Foundation; either version 2
### of the License, or (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License version 2 for more details.
###############################################################

init() {

	trap '' 2
	source /etc/archNAS.conf
	op_title=" -| Language Select |- "
	ILANG=$(dialog --nocancel --menu "\archNAS Installer\n\n \Z2*\Zn Select your install language:" 20 60 10 \
		"English" "-" \
		"Chinese" "Chinese" \
		"French" "Français" \
		"German" "Deutsch" \
		"Greek" "Greek" \
		"Indonesian" "bahasa Indonesia" \
		"Portuguese" "Português" \
		"Portuguese-Brazilian" "Português do Brasil" \
		"Romanian" "Română" \
		"Russian" "Russian" \
		"Spanish" "Español" \
		"Swedish" "Svenska" 3>&1 1>&2 2>&3)

	case "$ILANG" in
		"English") export lang_file=/usr/share/archNAS/lang/arch-installer-english.conf ;;
		"Chinese") export lang_file=/usr/share/archNAS/lang/arch-installer-chinese.conf ;;
		"French") export lang_file=/usr/share/archNAS/lang/arch-installer-french.conf ;;
		"German") export lang_file=/usr/share/archNAS/lang/arch-installer-german.conf ;;
		"Greek") export lang_file=/usr/share/archNAS/lang/arch-installer-greek.conf ;;
		"Indonesian") export lang_file=/usr/share/archNAS/lang/arch-installer-indonesia.conf ;;
		"Portuguese") export lang_file=/usr/share/archNAS/lang/arch-installer-portuguese.conf ;;
		"Portuguese-Brazilian") export lang_file=/usr/share/archNAS/lang/arch-installer-portuguese-br.conf ;;
		"Romanian") export lang_file=/usr/share/archNAS/lang/arch-installer-romanian.conf ;;
		"Russian") export lang_file=/usr/share/archNAS/lang/arch-installer-russian.conf ;;
		"Spanish") export lang_file=/usr/share/archNAS/lang/arch-installer-spanish.conf ;;
		"Swedish") export lang_file=/usr/share/archNAS/lang/arch-installer-swedish.conf ;;
	esac

	### Source configuration and language files
	source "$lang_file"
	export reload=true
	check_connection

}

check_connection() {

	op_title="$welcome_op_msg"
	if ! (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$intro_msg" 10 60) then
		reset ; exit
	fi
	
	op_title="$connection_op_msg"
	(wget --no-check-certificate --append-output=/tmp/wget.log -O /dev/null "$test_link"
	echo "$?" > /tmp/ex_status.var ; sleep 0.5) &> /dev/null &
	pid=$! pri=0.3 msg="\n$connection_load \n\n \Z1> \Z2wget -O /dev/null test_link/test1Mb.db\Zn" load
	sed -i 's/\,/\./' /tmp/wget.log

	while [ "$(</tmp/ex_status.var)" -gt "0" ]
	  do
		if [ -n "$wifi_network" ]; then
			if (dialog --yes-button "$yes" --no-button "$no" --yesno "$wifi_msg0" 10 60) then
				wifi-menu
				if [ "$?" -gt "0" ]; then
					dialog --ok-button "$ok" --msgbox "$wifi_msg1" 10 60
					setterm -background black -store ; reset ; echo "$connect_err1" ; exit 1
				else
					wifi=true
					echo "0" > /tmp/ex_status.var
				fi
			else
				unset wifi_network
			fi
		else
			dialog --ok-button "$ok" --msgbox "$connect_err0" 10 60
			setterm -background black -store ; reset ; echo -e "$connect_err1" ;  exit 1
		fi
	done
		
	### Define network connection speed variables from data in wget.log
	connection_speed=$(tail /tmp/wget.log | grep -oP '(?<=\().*(?=\))' | awk '{print $1}')
	connection_rate=$(tail /tmp/wget.log | grep -oP '(?<=\().*(?=\))' | awk '{print $2}')

	### Define cpu frequency variables
    cpu_mhz=$(lscpu | grep "CPU max MHz" | awk '{print $4}' | sed 's/\..*//')

	if [ "$?" -gt "0" ]; then
		cpu_mhz=$(lscpu | grep "CPU MHz" | awk '{print $3}' | sed 's/\..*//')
	fi
        
	 ### Define cpu sleep variable based on total cpu frequency
	case "$cpu_mhz" in
		[0-9][0-9][0-9]) 
			cpu_sleep=4
		;;
		[1][0-9][0-9][0-9])
			cpu_sleep=3.5
		;;
		[2][0-9][0-9][0-9])
			cpu_sleep=2.5
		;;
		*)
			cpu_sleep=1.5
		;;
	esac
        		
	export connection_speed connection_rate cpu_sleep
	rm /tmp/{ex_status.var,wget.log} &> /dev/null
	set_keys

}

set_keys() {
	
	op_title="$key_op_msg"
	keyboard=$(dialog --nocancel --ok-button "$ok" --menu "$keys_msg" 18 60 10 \
	"$default" "$default Keymap" \
	"us" "United States" \
	"de" "German" \
	"es" "Spanish" \
	"fr" "French" \
	"pt-latin9" "Portugal" \
	"ro" "Romanian" \
	"ru" "Russian" \
	"uk" "United Kingdom" \
	"$other"       "$other-keymaps"		 3>&1 1>&2 2>&3)
	source "$lang_file"

	### If user selects 'other' display full list of keymaps
	if [ "$keyboard" = "$other" ]; then
		keyboard=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$keys_msg" 19 60 10  $key_maps 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			set_keys
		fi
	fi
	
	export keyboard
	localectl set-keymap "$keyboard"
	set_locale

}

set_locale() {

	op_title="$locale_op_msg"
	LOCALE=$(dialog --nocancel --ok-button "$ok" --menu "$locale_msg" 18 60 11 \
	"en_US.UTF-8" "United States" \
	"en_AU.UTF-8" "Australia" \
	"en_CA.UTF-8" "Canada" \
	"es_ES.UTF-8" "Spanish" \
	"fr_FR.UTF-8" "French" \
	"de_DE.UTF-8" "German" \
	"en_GB.UTF-8" "Great Britain" \
	"en_MX.UTF-8" "Mexico" \
	"pt_PT.UTF-8" "Portugal" \
	"ro_RO.UTF-8" "Romanian" \
	"ru_RU.UTF-8" "Russian" \
	"sv_SE.UTF-8" "Swedish" \
	"$other"       "$other-locale"		 3>&1 1>&2 2>&3)

	### If user selects 'other' locale display full list
	if [ "$LOCALE" = "$other" ]; then
		LOCALE=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$locale_msg" 18 60 11 $localelist 3>&1 1>&2 2>&3)

		if [ "$?" -gt "0" ]; then 
			set_locale
		fi
	fi

	set_zone

}


set_zone() {

	op_title="$zone_op_msg"
	ZONE=$(dialog --nocancel --ok-button "$ok" --menu "$zone_msg0" 18 60 11 $zonelist 3>&1 1>&2 2>&3)
	if (find /usr/share/zoneinfo -maxdepth 1 -type d | sed -n -e 's!^.*/!!p' | grep "$ZONE" &> /dev/null); then
		sublist=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$ZONE")
		SUBZONE=$(dialog --ok-button "$ok" --cancel-button "$back" --menu "$zone_msg1" 18 60 11 $sublist 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then 
			set_zone 
		fi
		if (find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 -type  d | sed -n -e 's!^.*/!!p' | grep "$SUBZONE" &> /dev/null); then
			sublist=$(find /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$SUBZONE")
			SUB_SUBZONE=$(dialog --ok-button "$ok" --cancel-button "$back" --menu "$zone_msg1" 15 60 7 $sublist 3>&1 1>&2 2>&3)
			if [ "$?" -gt "0" ]; then 
				set_zone 
			fi
			ZONE="${ZONE}/${SUBZONE}/${SUB_SUBZONE}"
		else
			ZONE="${ZONE}/${SUBZONE}"
		fi
	fi

	prepare_drives

}

prepare_drives() {

	op_title="$part_op_msg"
	lsblk | grep "/mnt\|SWAP" &> /dev/null
	if [ "$?" -eq "0" ]; then
		umount -R "$ARCH" &> /dev/null &
		pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R $ARCH\Zn" load
		swapoff -a &> /dev/null &
	fi
	
	### Prompt user to select their desired method of partitioning
	### method0=Auto Partition ; method1=Auto Partition Encrypted ; method2=Manual Partition
	PART=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$part_msg" 14 64 4 \
	"$method0" "-" \
	"$method1" "-" \
	"$method2"  "-" \
	"$menu_msg" "-" 3>&1 1>&2 2>&3)

	if [ "$?" -gt "0" ] || [ "$PART" == "$menu_msg" ]; then
		main_menu
	
	### If manual partition NOT selected begin setting drive configuration
	elif [ "$PART" != "$method2" ]; then
	
		dev_menu="           Device: | Size: | Type:  |"
		if "$screen_h" ; then
			cat <<-EOF > /tmp/part.sh
					dialog --colors --backtitle "$backtitle" --title "$title" --ok-button "$ok" --cancel-button "$cancel" --menu "$drive_msg \n\n $dev_menu" 14 60 3 \\
					$(lsblk | grep "disk" | grep -v "$USB\|loop" | awk '{print "\""$1"\"""  ""\"| "$4"  |  "$6" |==>\""" \\"}' | column -t)
					3>&1 1>&2 2>&3
				EOF
		else
				cat <<-EOF > /tmp/part.sh
					dialog --colors --title "$title" --ok-button "$ok" --cancel-button "$cancel" --menu "$drive_msg \n\n $dev_menu" 14 60 3 \\
					$(lsblk | grep "disk" | grep -v "$USB\|loop" | awk '{print "\""$1"\"""  ""\"| "$4"  |  "$6" |==>\""" \\"}' | column -t)
					3>&1 1>&2 2>&3
				EOF
		fi
		
		DRIVE=$(bash /tmp/part.sh)
		rm /tmp/part.sh
		
		### If drive variable is not set user selected cancel
		### return to beginning of prepare drives function
		if [ -z "$DRIVE" ]; then
			prepare_drives
		fi
		
		### Read total gigabytes of selected drive and source language file variables
		drive_gigs=$(lsblk | grep -w "$DRIVE" | awk '{print $4}' | grep -o '[0-9]*' | awk 'NR==1') 
		f2fs=$(cat /sys/block/"$DRIVE"/queue/rotational)
		fs_select

		### Prompt user to create new swap space
		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$swap_msg0" 10 60) then
			
			### While swapped variable NOT true - Beginning of swap loop
			while ! "$swapped" 
			  do
				
				### Prompt user to set size for new swapspace default is '512M'
				SWAPSPACE=$(dialog --ok-button "$ok" --inputbox "\n$swap_msg1" 11 55 "512M" 3>&1 1>&2 2>&3)
					
				### If user selects 'cancel' escape from while loop and set SWAP to false
				if [ "$?" -gt "0" ]; then
					SWAP=false
					swapped=true
				
				### Else error checking on swapspace variable
				else
					
					### If selected unit is set to 'M' MiB
					if [ "$(grep -o ".$" <<< "$SWAPSPACE")" == "M" ]; then 
						
						### If swapsize exceeded the total volume of the drive in MiB taking into account 4 GiB for install space
						if [ "$(grep -o '[0-9]*' <<< "$SWAPSPACE")" -lt "$(echo "$drive_gigs*1000-4096" | bc)" ]; then 
							SWAP=true 
							swapped=true
						
						### Else selected swap size exceedes total volume of drive print error message
						else 
							dialog --ok-button "$ok" --msgbox "\n$swap_err_msg0" 10 60
						fi

					### Else if selected unit is set to 'G' GiB
					elif [ "$(grep -o ".$" <<< "$SWAPSPACE")" == "G" ]; then 

					### If swapsize exceeded the total volume of the drive in GiB taking into account 4 GiB for install space
						if [ "$(grep -o '[0-9]*' <<< "$SWAPSPACE")" -lt "$(echo "$drive_gigs-4" | bc)" ]; then 
							SWAP=true 
							swapped=true
							
						### Else selected swap size exceedes total volume of drive print error message
						else 
							dialog --ok-button "$ok" --msgbox "\n$swap_err_msg0" 10 60
						fi

					### Else size unit not set to 'G' for GiB or 'M' for MiB print error
					else
						dialog --ok-button "$ok" --msgbox "\n$swap_err_msg1" 10 60
					fi
				fi
				
			### End of swap loop	
			done
			
		### End of setting swap
		fi
			
		### Run efivar to check if efi support is enabled
		if (efivar -l &> /dev/null); then

			### If no error is returned prompt user to install with efi
			if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$efi_msg0" 10 60) then
					GPT=true 
					UEFI=true 
			fi
		fi

		### If uefi boot is not set to true prompt user if they would like to use GUID Partition Table
		if ! "$UEFI" ; then 

			if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$gpt_msg" 10 60) then 
				GPT=true
			fi
		fi

		source "$lang_file"

		if "$SWAP" ; then
			drive_var="$drive_var1"
			height=13

			if "$UEFI" ; then
				drive_var="$drive_var2"
				height=14
			fi
		elif "$UEFI" ; then
			drive_var="$drive_var3"
			height=13
		else
			height=11
		fi
	
		### Prompt user to format selected drive
		if (dialog --defaultno --yes-button "$write" --no-button "$cancel" --yesno "\n$drive_var" "$height" 60) then
			sgdisk --zap-all /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2sgdisk --zap-all /dev/$DRIVE\Zn" load
	
		### Else reset back to beginning of prepare drives function
		else
			prepare_drives
		fi
	### End setting drive configuration
	fi
	
	### Begin drive configuration
	case "$PART" in
		
		### Auto partition drive
		"$method0") auto_part	
		;;

		### Auto partition encrypted LVM
		"$method1") auto_encrypt
		;;

		### Manual partitioning selected
		"$method2")	points=$(echo -e "$points_orig\n$custom $custom-mountpoint")
					part_menu
		;;
	esac

	### If no root partition is mounted display error message and return to beginning of prepare drives function
	if ! "$mounted" ; then
		dialog --ok-button "$ok" --msgbox "\n$part_err_msg" 10 60
		prepare_drives
	
	### Else continue into update mirrors function
	else
		update_mirrors
	fi

}

auto_part() {
	
	op_title="$partload_op_msg"
	if "$GPT" ; then
		if "$UEFI" ; then
			if "$SWAP" ; then
				echo -e "n\n\n\n512M\nef00\nn\n3\n\n+$SWAPSPACE\n8200\nn\n\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
				pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
				SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
				
				### Wipe swap filesystem create and enable new swapspace
				(wipefs -a /dev/"$SWAP"
				mkswap /dev/"$SWAP"
				swapon /dev/"$SWAP") &> /dev/null &
				pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2mkswap /dev/$SWAP\Zn" load
			
			### Else swapspace false
			else
				
				### If efi and gpt set but swap set to false echo partition commands into 'gdisk'
				### create boot 512M type of ef00 and use remaining space for root
				echo -e "n\n\n\n512M\nef00\nn\n\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
				pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
			fi

			### Set boot and root partition variables
			BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
			ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
		
		### Else UEFI boot false
		else

			### If swapspace is true
			if "$SWAP" ; then
				
				### If uefi boot is false but gpt partitioning true echo commands into 'gdisk'
				### this gets confusing I couldn't recreate this command if I tried
				### creates a new 100M boot partition then creates a 1M Protected MBR boot partition type of EF02
				### Next creates swapspace and uses remaining space for root partition
				echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n4\n\n+$SWAPSPACE\n8200\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
				pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
				SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==5) print substr ($1,3) }')"
				(wipefs -a /dev/"$SWAP"
				mkswap /dev/"$SWAP"
				swapon /dev/"$SWAP") &> /dev/null &
				pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2mkswap /dev/$SWAP\Zn" load

			
			### Else swapspace is false
			else
				
				### If uefi boot false but gpt is true echo commands into 'gdisk'
				### Create boot and protected MBR use remaining space for root
				echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
				pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
			fi
		
			### Set boot and root partition variables 	
			BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"	
			ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
		fi
	
	### Else GPT partitioning is false
	else

		if "$SWAP" ; then
			
			### If swap is true echo partition commands into 'fdisk'
			### create new partition size of 100M this is the boot partition
			### create new partition size of swapspace variable use remaining space for root partition
			echo -e "o\nn\np\n1\n\n+100M\nn\np\n3\n\n+$SWAPSPACE\nt\n\n82\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2fdisk /dev/$DRIVE\Zn" load
			SWAP="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"					
			(wipefs -a /dev/"$SWAP"
			mkswap /dev/"$SWAP"
			swapon /dev/"$SWAP") &> /dev/null &
			pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2mkswap /dev/$SWAP\Zn" load

		else
			
			### If swap is false echo commands into 'fdisk'
			### create 100M boot partition and use remaining space for root partition
			echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2fdisk /dev/$DRIVE\Zn" load
		fi				

		### define boot and root partition variables
		BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
		ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"

	### End partitioning
	fi

	wipefs -a /dev/"$BOOT" &> /dev/null
	### If uefi boot is set to true create new boot filesystem type of 'vfat'
	if "$UEFI" ; then
		mkfs.vfat -F32 /dev/"$BOOT" &> /dev/null &
		pid=$! pri=0.1 msg="\n$efi_load1 \n\n \Z1> \Z2mkfs.vfat -F32 /dev/$BOOT\Zn" load
		esp_part="/dev/$BOOT"
		esp_mnt=/boot
	else
		mkfs.ext4 /dev/"$BOOT" &> /dev/null &
		pid=$! pri=0.1 msg="\n$boot_load \n\n \Z1> \Z2mkfs.ext4 /dev/$BOOT\Zn" load
	fi

	### Create root filesystem using desired filesystem type
	wipefs -a /dev/"$ROOT" &> /dev/null
	case "$FS" in
		jfs|reiserfs)
			echo -e "y" | mkfs."$FS" /dev/"$ROOT" &> /dev/null &
		;;
		*)
			mkfs."$FS" /dev/"$ROOT" &> /dev/null &
		;;
	esac
	pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.$FS /dev/$ROOT\Zn" load

	### Mount root partition at arch mountpoint
	(mount /dev/"$ROOT" "$ARCH"
	echo "$?" > /tmp/ex_status.var
	mkdir $ARCH/boot
	mount /dev/"$BOOT" "$ARCH"/boot) &> /dev/null &
	pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/$ROOT $ARCH\Zn" load

	if [ "$(</tmp/ex_status.var)" -eq "0" ]; then
		mounted=true
	fi

	rm /tmp/ex_status.var

}

auto_encrypt() {
	
	op_title="$partload_op_msg"
	if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$encrypt_var0" 10 60) then
		
		### While input not equal to input check password check loop
		while [ "$input" != "$input_chk" ]
    	  do
    		
        	### Set password for drive encryption and check if it matches
    		input=$(dialog --nocancel --clear --insecure --passwordbox "$encrypt_var1" 12 55 --stdout)
    		input_chk=$(dialog --nocancel --clear --insecure --passwordbox "$encrypt_var2" 12 55 --stdout)

        	### If no password entered display error message and try again
    	    if [ -z "$input" ]; then
       			dialog --ok-button "$ok" --msgbox "\n$passwd_msg0" 10 60
		 		input_chk=default
		 	
   			### Else if passwords not equal display error and try again
		 	elif [ "$input" != "$input_chk" ]; then
          		dialog --ok-button "$ok" --msgbox "\n$passwd_msg1" 10 60
         	fi
    	 
	    ### End password check loop
    	 done
	
	### if user would not like to encrypt drive return to beginning of prepare drives function
	else
		prepare_drives
	fi

	
	### If GPT set to true echo partitioning commands into 'gdisk'
	if "$GPT" ; then

		### If uefi set to true echo commands to create efi boot partition
		if "$UEFI" ; then
			echo -e "n\n\n\n512M\nef00\nn\n\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
			BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
			ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
		
		### Else echo commands to create gpt partion scheme with protected mbr boot
		else
			echo -e "o\ny\nn\n1\n\n+100M\n\nn\n2\n\n+1M\nEF02\nn\n3\n\n\n\nw\ny" | gdisk /dev/"$DRIVE" &> /dev/null &
			pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2gdisk /dev/$DRIVE\Zn" load
			ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==4) print substr ($1,3) }')"
			BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
		fi
	
	### Else echo partitioning commands into  fdisk
	else
		echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw" | fdisk /dev/"$DRIVE" &> /dev/null &
		pid=$! pri=0.1 msg="\n$load_var0 \n\n \Z1> \Z2fdisk /dev/$DRIVE\Zn" load
		BOOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==2) print substr ($1,3) }')"
		ROOT="$(lsblk | grep "$DRIVE" |  awk '{ if (NR==3) print substr ($1,3) }')"
	fi

	### Wipe filesystem on root partition
	(wipefs -a /dev/"$ROOT"
	wipefs -a /dev/"$BOOT") &> /dev/null &
	pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2wipefs -a /dev/$ROOT\Zn" load

	### Create new physical volume and volume group on root partition using LVM
	(lvm pvcreate /dev/"$ROOT"
	lvm vgcreate lvm /dev/"$ROOT") &> /dev/null &
	pid=$! pri=0.1 msg="\n$pv_load \n\n \Z1> \Z2lvm pvcreate /dev/$ROOT\Zn" load

	### If swap is set to true create new swap logical volume set to size of swapspace
	if "$SWAP" ; then
		lvm lvcreate -L "$SWAPSPACE" -n swap lvm &> /dev/null &
		pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2lvm lvcreate -L $SWAPSPACE -n swap lvm\Zn" load
	fi

	### Create new locical volume for tmp and root filesystems 'tmp' and 'lvroot'
	(lvm lvcreate -L 500M -n tmp lvm
	lvm lvcreate -l 100%FREE -n lvroot lvm) &> /dev/null &
	pid=$! pri=0.1 msg="\n$lv_load \n\n \Z1> \Z2lvm lvcreate -l 100%FREE -n lvroot lvm\Zn" load

	### Encrypt root logical volume using cryptsetup lukas format
	(printf "$input" | cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/lvm/lvroot -
	printf "$input" | cryptsetup open --type luks /dev/lvm/lvroot root -) &> /dev/null &
	pid=$! pri=0.2 msg="\n$encrypt_load \n\n \Z1> \Z2cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/lvm/lvroot\Zn" load
	unset input input_chk ; input_chk=default

	### Create and mount root filesystem on new encrypted volume
	wipefs -a /dev/mapper/root &> /dev/null
	case "$FS" in
		jfs|reiserfs)
			echo -e "y" | mkfs."$FS" /dev/mapper/root &> /dev/null &
		;;
		*)
			mkfs."$FS" /dev/mapper/root &> /dev/null &
		;;
	esac
	pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.$FS /dev/mapper/root\Zn" load
	
	### If efi is true create new boot filesystem using 'vfat'
	if "$UEFI" ; then
		mkfs.vfat -F32 /dev/"$BOOT" &> /dev/null &
		pid=$! pri=0.2 msg="\n$efi_load1 \n\n \Z1> \Z2mkfs.vfat -F32 /dev/$BOOT\Zn" load
		esp_part="/dev/$BOOT"
		esp_mnt=/boot
	else
		wipefs -a /dev/"$BOOT" &> /dev/null
		mkfs.ext4 /dev/"$BOOT" &> /dev/null &
		pid=$! pri=0.2 msg="\n$boot_load \n\n \Z1> \Z2mkfs.ext4 /dev/$BOOT\Zn" load
	fi

	(mount /dev/mapper/root "$ARCH"
	echo "$?" > /tmp/ex_status.var
	mkdir $ARCH/boot
	mount /dev/"$BOOT" "$ARCH"/boot) &> /dev/null &
	pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/mapper/root $ARCH\Zn" load

	if [ $(</tmp/ex_status.var) -eq "0" ]; then
		mounted=true
		crypted=true
	fi

	rm /tmp/ex_status.var

}

part_menu() {

	op_title="$manual_op_msg"
	unset manual_part
	part_count=$(lsblk | grep "sd." | wc -l)
	
	### Set menu height variable based on the number of listed partitions
	if [ "$part_count" -lt "6" ]; then
		height=16
		menu_height=5
	else
		height=20
		menu_height=9
	fi
	
	### Create manual partition menu
	### Set int variable to 1
	### Set count to total number of devices / partitions
	int=1
	count=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | wc -l)
	tmp_menu=/tmp/part.sh tmp_list=/tmp/part.list
	dev_menu="|  Device:  |  Size:  |  Used:  |  FS:  |  Mount:  |  Type:  |"
	
	### Until int is greater than count loop create partition menu
	### Device info defined with device dev_size dev_type mnt_point
	### awk is used with the int variable to print next line each time it loops
	until [ "$int" -gt "$count" ]
	  do
		device=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$1}")
		dev_size=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$4}" | sed 's/\,/\./')
		dev_type=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$6}")
		mnt_point=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$7}" | sed 's/\/mnt/\//;s/\/\//\//')

		### if int equals 1 output dialog command into /tmp/part.list
		### each time loop runs append new device info to /tmp/part.list
		if [ "$int" -eq "1" ]; then
			if "$screen_h" ; then
				echo "dialog --colors --backtitle \"$backtitle\" --title \"$op_title\" --ok-button \"$ok\" --cancel-button \"$cancel\" --menu \"$manual_part_msg \n\n $dev_menu\" $height 68 $menu_height \\" > "$tmp_menu"
			else
				echo "dialog --colors --title \"$title\" --ok-button \"$ok\" --cancel-button \"$cancel\" --menu \"$manual_part_msg \n\n $dev_menu\" $height 68 $menu_height \\" > "$tmp_menu"
			fi
			echo "\"$device   \" \"$dev_size $dev_type ------------->\" \\" > $tmp_list
		else
			if (<<<"$device" grep -o "sd.." &> /dev/null) then
				if (<<<"$mnt_point" grep "/" &> /dev/null) then
					fs_type="$(df -T | grep "$(<<<"$device" grep -o "sd..")" | awk '{print $2}')"
					dev_used=$(df -T | grep "$(<<<"$device" grep -o "sd..")" | awk '{print $6}')
				else
					unset fs_type dev_used
				fi
				
				if (fdisk -l | grep "$(<<<"$device" grep -o "sd..")" | grep "*" &> /dev/null) then
					part_type=$(fdisk -l | grep "$(<<<"$device" grep -o "sd..")" | awk '{print $8,$9}')
				else
					if (efivar -l &> /dev/null) then
						part_type=$(fdisk -l | grep "$(<<<"$device" grep -o "sd..")" | awk '{print $6,$7}')
						if [ "$part_type" == "Linux filesystem" ]; then
							part_type="Linux"
						elif [ "$part_type" == "EFI System" ]; then
							part_type="EFI/ESP"
						fi
					else
						part_type=$(fdisk -l | grep "$(<<<"$device" grep -o "sd..")" | awk '{print $7,$8}')
					fi
				fi

				if [ "$part_type" == "Linux swap" ]; then
					part_type="Linux/SWAP"
				fi

				echo "\"$device\" \"$dev_size $dev_used $fs_type $mnt_point $part_type\" \\" >> "$tmp_list"
				unset part_type
			else
				echo "\"$device\" \"$dev_size $dev_type ------------->\" \\" >> "$tmp_list"
			fi
		fi

		int=$((int+1))
	done

	<"$tmp_list" column -t >> "$tmp_menu"
	echo "\"$done_msg\" \"$write\" 3>&1 1>&2 2>&3" >> "$tmp_menu"
	manual_part=$(bash "$tmp_menu" | sed 's/ //g')
	rm $tmp_menu $tmp_list
	part_class

}
	
part_class() {

	op_title="$edit_op_msg"
	if [ -z "$manual_part" ]; then
		prepare_drives
	elif (<<<$manual_part grep "[0-9]" &> /dev/null); then
		part=$(<<<$manual_part grep -o "sd..")
		part_size=$(lsblk | grep "$part" | awk '{print $4}' | sed 's/\,/\./')
		part_mount=$(lsblk | grep "$part" | awk '{print $7}' | sed 's/\/mnt/\//;s/\/\//\//')
		source "$lang_file"  &> /dev/null

		### If no partitions are mounted user must create root partition first
		if ! (lsblk | grep "part" | grep "$ARCH" &> /dev/null); then
			case "$part_size" in
				[4-9]G|[0-9][0-9]*G|[4-9].*G|T)
				
					### If partition is in the correct size range prompt user to create new root partition
					if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$root_var" 13 60) then
						f2fs=$(cat /sys/block/$(echo $part | sed 's/[0-9]//g')/queue/rotational)
						fs_select

						### If exit status greater than '0' user selected cancel
						### return to beginning for manual partition function
						if [ "$?" -gt "0" ]; then
							part_menu
						fi

						source "$lang_file"

						### Prompt user to confirm creating new root mountpoint on partition
						### displays partition location partition size new mountpoint filesystem type
						if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "\n$root_confirm_var" 14 50) then
						
							### Wipe root filesystem on selected partition
							wipefs -a /dev/"$part" &> /dev/null &
							pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2wipefs -a /dev/$part\Zn" load

							### Create new filesystem on root partition
							case "$FS" in
								jfs|reiserfs)
									echo -e "y" | mkfs."$FS" /dev/"$part" &> /dev/null &
								;;
								*)
									mkfs."$FS" /dev/"$part" &> /dev/null &
								;;
							esac
							pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.$FS /dev/$part\Zn" load

							### Mount new root partition at arch mountpoint
							(mount /dev/"$part" "$ARCH"
							echo "$?" > /tmp/ex_status.var) &> /dev/null &
							pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/$part $ARCH\Zn" load

							### If exit status is equal to '0' set mounted, root, and drive variables
							if [ $(</tmp/ex_status.var) -eq "0" ]; then
								mounted=true
								ROOT="$part"
								DRIVE=$(<<<$part sed 's/[0-9]//')

							### Else mount command failed
							### display error message and return to prepare drives function
							else
								dialog --ok-button "$ok" --msgbox "\n$part_err_msg1" 10 60
								prepare_drives
							fi
						fi
					else
						part_menu
					fi
				;;
				### Size of selected partition is less than 4GB and root partition has not been selected
				*)
					### Partition too small to be root partition display error and prompt user to select another partition to be root
					dialog --ok-button "$ok" --msgbox "\n$root_err_msg" 10 60
				;;
			esac

		### Else if partition is already mounted
		elif [ -n "$part_mount" ]; then
			
			### Display mounted message with partition info and mountpoint with edit and back buttons
			if (dialog --yes-button "$edit" --no-button "$back" --defaultno --yesno "\n$manual_part_var0" 13 60) then
			
				### If user selects to edit existing mountpoint check if it is the root partition
				### if existing mountpoint is root warn user
				if [ "$part" == "$ROOT" ]; then
					if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_part_var2" 11 60) then
						
						### If user decides to change mountpoint on root partition set mounted to false
						### unset variables and unmount recursive root partition
						mounted=false
						unset ROOT DRIVE
						umount -R "$ARCH" &> /dev/null &
						pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R $ARCH\Zn" load
					fi
				
				### Else if user selected to edit existing mountpoint and is not root partition
				else
			
					### Check if mountpoint is swap partition
					### if mountpoint is swap and user would like to edit mountpoint turn off swap
					if [ "$part_mount" == "[SWAP]" ]; then
						if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_swap_var" 10 60) then
							swapoff /dev/"$part" &> /dev/null &
							pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2swapoff /dev/$part\Zn" load
						fi
					
					### Else if mountpoint is not swap prompt user if they would like to change mountpoint
					### if user selects yes unmount the partition remove the created mountpoint and echo the mountpoint back into the points menu
					elif (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_part_var1" 10 60) then
						umount  "$ARCH"/"$part_mount" &> /dev/null &
						pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount ${ARCH}/${part_mount}\Zn" load
						rm -r "$ARCH"/"$part_mount"
						points=$(echo -e "$part_mount   mountpoint>\n$points")
					fi
				fi
			fi

		### Else if root partition has already been mounted and selected partition is not already mounted
		### prompt user to create a new mountpoint on selected partition
		elif (dialog --yes-button "$edit" --no-button "$back" --yesno "\n$manual_new_part_var" 12 60) then
			
			### set the variable mnt to the location of new mountpoint
			mnt=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$mnt_var0" 15 60 6 $points 3>&1 1>&2 2>&3)
				
			### If exit status is greater than '0' user selected cancel
			### return to beginning of manual partition function
			if [ "$?" -gt "0" ]; then
				part_menu
			fi

			### if user selected a custom mountpoint set err variable to true
			if [ "$mnt" == "$custom" ]; then
				err=true

				### begin custom mountpoint menu loop
				### until err is set to false prompt user to input custom mountpoint
				until ! "$err"
				  do
					mnt=$(dialog --ok-button "$ok" --cancel-button "$cancel" --inputbox "$custom_msg" 10 50 "/" 3>&1 1>&2 2>&3)
					
					### If exit status is greater than '0' user selected cancel
					### return to beginning of manual partition function
					if [ "$?" -gt "0" ]; then
						err=false
						part_menu
					
					### Else if custom mountpoint contains special characters display error message and return to beginning of custom mountpoint loop
					elif (<<<$mnt grep "[\[\$\!\'\"\`\\|%&#@()+=<>~;:?.,^{}]\|]" &> /dev/null); then
						dialog --ok-button "$ok" --msgbox "\n$custom_err_msg0" 10 60

					### Else if custom mountpoint is set to root '/' display error message and return to beginning of custom mountpoint loop
					elif (<<<$mnt grep "^[/]$" &> /dev/null); then
						dialog --ok-button "$ok" --msgbox "\n$custom_err_msg1" 10 60
					
					### Else custom mountpoint is valid set err variable to false
					else
						err=false
					fi
				
				### End custom mountpoint loop
				done
			fi

					
			### Else prompt user to select filesystem type for selected partition
			if [ "$mnt" != "SWAP" ]; then
				if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$part_frmt_msg" 11 50) then
					f2fs=$(cat /sys/block/$(echo $part | sed 's/[0-9]//g')/queue/rotational)
					
					if [ "$mnt" == "/boot" ] || [ "$mnt" == "/boot/EFI" ] || [ "$mnt" == "/boot/efi" ]; then
						if (fdisk -l | grep "$part" | grep "EFI" &> /dev/null); then
							vfat=true
						fi
						f2fs=1
						btrfs=false
					fi
					
					fs_select

					if [ "$?" -gt "0" ]; then
						part_menu
					fi
					frmt=true
				else
					frmt=false
				fi
			else
				FS="SWAP"
			fi

			source "$lang_file"
		
			### If user set  mountpoint to swap
			### wipe filesystem on selected partition
			### create new swapspace on partition and turn swap on
			if [ "$mnt" == "SWAP" ]; then
				if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$swap_frmt_msg" 11 50) then
					(wipefs -a -q /dev/"$part"
					mkswap /dev/"$part"
					swapon /dev/"$part") &> /dev/null &
					pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2mkswap /dev/$part\Zn" load
				else
					swapon /dev/"$part" &> /dev/null
					if [ "$?" -gt "0" ]; then
						dialog --ok-button "$ok" --msgbox "$swap_err_msg2" 10 60
					fi
				fi
			
			### Else if mount is not equal to swap
			else
				points=$(echo  "$points" | grep -v "$mnt")
			
				if "$frmt" ; then
					if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "$part_confirm_var" 12 50) then
						### Wipe filesystem on selected partition
						wipefs -a /dev/"$part" &> /dev/null &
						pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2wipefs -a /dev/$part\Zn" load
			
						### Create new filesystem on selected partition
						case "$FS" in
							vfat)
								mkfs.vfat -F32 /dev/"$part" &> /dev/null &
							;;
							jfs|reiserfs)
								echo -e "y" | mkfs."$FS" /dev/"$part" &> /dev/null &
							;;
							*)
								mkfs."$FS" /dev/"$part" &> /dev/null &
							;;
						esac
						pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.FS /dev/$part\Zn" load
					else
						part_menu
					fi
				fi
					
				### Create new mountpoint and mount selected partition
				(mkdir -p "$ARCH"/"$mnt"
				mount /dev/"$part" "$ARCH"/"$mnt" ; echo "$?" > /tmp/ex_status.var ; sleep 0.5) &> /dev/null &
				pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/$part ${ARCH}/${mnt}\Zn" load

				if [ "$(</tmp/ex_status.var)" -gt "0" ]; then
					dialog --ok-button "$ok" --msgbox "\n$part_err_msg2" 10 60
				fi
			fi
		fi

		part_menu

	### Else if manual part variable is set to 'done'
	elif [ "$manual_part" == "$done_msg" ]; then
	
		### If no partition is mounted display error message to user and return to beginning of manual partition function
		if ! "$mounted" ; then
			dialog --ok-button "$ok" --msgbox "\n$root_err_msg1" 10 60
			part_menu
		
		### Else partition is mounted, create a list and count of final partitions
		else
			final_part=$(lsblk | grep "/\|[SWAP]" | grep "part" | grep -v "/run" | awk '{print " "$1" "$4" "$7 "\\n"}' | sed 's/\/mnt/\//;s/\/\//\//' | column -t)
			final_count=$(lsblk | grep "/\|[SWAP]" | grep "part" | grep -v "/run" | wc -l)

			
			### Set the height of the write confirm menu based on the number of partitions to be added
			if [ "$final_count" -lt "7" ]; then
				height=17
			elif [ "$final_count" -lt "13" ]; then
				height=23
			elif [ "$final_count" -lt "17" ]; then
				height=26
			else
				height=30
			fi
			
			part_menu="$partition: $size: $mountpoint:"
			### Confirm writing changes to partition table and continue with install
			if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "$write_confirm_msg \n\n $part_menu \n\n$final_part \n\n $write_confirm" "$height" 50) then
				if (efivar -l &>/dev/null); then
					if (fdisk -l | grep "EFI" &>/dev/null); then
						if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$efi_man_msg" 11 60) then
							if [ "$(fdisk -l | grep "EFI" | wc -l)" -gt "1" ]; then
								efint=1
								while (true)
								  do
									if [ "$(fdisk -l | grep "EFI" | awk "NR==$efint {print \$1}")" == "" ]; then
										dialog --ok-button "$ok" --msgbox "$efi_err_msg1" 10 60
										part_menu
									fi
									esp_part=$(fdisk -l | grep "EFI" | awk "NR==$efint {print \$1}")
									esp_mnt=$(df -T | grep "$esp_part" | awk '{print $7}')
									if (df -T | grep "$esp_part" &> /dev/null); then
										break
									else
										efint=$((efint+1))
									fi
								done
							else
								esp_part=$(fdisk -l | grep "EFI" | awk '{print $1}')
								if ! (df -T | grep "$esp_part" &> /dev/null); then
									source "$lang_file"
									if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$efi_mnt_var" 11 60) then
										if ! (mountpoint "$ARCH"/boot &> /dev/null); then
											mkdir "$ARCH"/boot &> /dev/null
											mount "$esp_part" "$ARCH"/boot
										else
											dialog --ok-button "$ok" --msgbox "\n$efi_err_msg" 10 60
											part_menu
										fi
									else
										part_menu
									fi
								else
									esp_mnt=$(df -T | grep "$esp_part" | awk '{print $7}')
								fi
							fi
							source "$lang_file"
							if [ "$(df -T | grep "$esp_part" | awk '{print $2}')" != "vfat" ]; then
								if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$vfat_var" 11 60) then
										(umount -R "$esp_mnt"
										mkfs.vfat -F32 "$esp_part"
										mount "$esp_part" "$esp_mnt") &> /dev/null &
										pid=$! pri=0.2 msg="\n$efi_load1 \n\n \Z1> \Z2mkfs.vfat -F32 $esp_part\Zn" load
										UEFI=true
								else
									part_menu
								fi
							else
								UEFI=true
								export esp_part esp_mnt
							fi
						fi
					fi
				fi

				if "$enable_f2fs" ; then
					if ! (lsblk | grep "$ARCH/boot\|$ARCH/boot/efi" &> /dev/null) then
						FS="f2fs" source "$lang_file"
						dialog --ok-button "$ok" --msgbox "\n$fs_err_var" 10 60
						part_menu
					fi
				elif "$enable_btrfs" ; then
					if ! (lsblk | grep "$ARCH/boot\|$ARCH/boot/efi" &> /dev/null) then
						FS="btrfs" source "$lang_file"
						dialog --ok-button "$ok" --msgbox "\n$fs_err_var" 10 60
						part_menu
					fi
				fi
				
				update_mirrors
			else
				part_menu
			fi
		fi
	
	### Else user selected a root block device 
	### Prompt user to edit partition scheme
	else
		
		### Set the size of selected block device
		part_size=$(lsblk | grep "$manual_part" | awk 'NR==1 {print $4}')
		source "$lang_file"

		### Check if block device contains mounted partitions
		if (lsblk | grep "$manual_part" | grep "$ARCH" &> /dev/null); then	
			
			### If partitions are mounted display warning to user
			if (dialog --yes-button "$edit" --no-button "$cancel" --defaultno --yesno "$mount_warn_var" 10 60) then
				
				### If user selects to edit partition scheme anyway unmount all partitions turn off any swap and edit with cfdisk
				points=$(echo -e "$points_orig\n$custom $custom-mountpoint")
				(umount -R "$ARCH"
				swapoff -a) &> /dev/null &
				pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R /mnt\Zn" load
				mounted=false
				unset DRIVE
				cfdisk /dev/"$manual_part"
				sleep 0.5
				clear
			fi
		
		### Else block device does not contain any mounted partitions prompt user to edit partition scheme with cfdisk
		elif (dialog --yes-button "$edit" --no-button "$cancel" --yesno "$manual_part_var3" 12 60) then
			cfdisk /dev/"$manual_part"
			sleep 0.5
			clear
		fi

		part_menu
	fi

}

fs_select() {

	if "$vfat" ; then
		FS=$(dialog --menu "$vfat_msg" 11 65 1 \
			"vfat"  "$fs7" 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			part_menu
		fi
		vfat=false
	else
		if [ "$f2fs" -eq "0" ]; then
			FS=$(dialog --nocancel --menu "$fs_msg" 17 65 7 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"btrfs"     "$fs3" \
				"f2fs"		"$fs6" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
		elif "$btrfs" ; then
				FS=$(dialog --nocancel --menu "$fs_msg" 16 65 6 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"btrfs"     "$fs3" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
		else
			FS=$(dialog --nocancel --menu "$fs_msg" 15 65 5 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
				btrfs=true
		fi
	fi

	if [ "$FS" == "f2fs" ]; then
		enable_f2fs=true
	elif [ "$FS" == "btrfs" ]; then
		enable_btrfs=true
	fi

}

update_mirrors() {

	op_title="$mirror_op_msg"
	if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$mirror_msg0" 10 60) then
		
		### Display full list of mirrorlist country codes to user
		### use wget to fetch mirrorlist
		code=$(dialog --nocancel --ok-button "$ok" --menu "$mirror_msg1" 17 60 10 $countries 3>&1 1>&2 2>&3)
		wget --no-check-certificate --append-output=/dev/null "https://www.archlinux.org/mirrorlist/?country=$code&protocol=http" -O /etc/pacman.d/mirrorlist.bak &
		pid=$! pri=0.1 msg="\n$mirror_load0 \n\n \Z1> \Z2wget -O /etc/pacman.d/mirrorlist archlinux.org/mirrorlist/?country=$code\Zn" load
		
		### Use sed to remove comments from mirrorlist and rank the top 6 mirrors into /etc/pacman.d/mirrorlist
		sed -i 's/#//' /etc/pacman.d/mirrorlist.bak
		rankmirrors -n 6 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist &
 		pid=$! pri=0.8 msg="\n$mirror_load1 \n\n \Z1> \Z2rankmirrors -n 6 /etc/pacman.d/mirrorlist\Zn" load
 		mirrors_updated=true
	fi

	prepare_base

}

prepare_base() {
	
	op_title="$install_op_msg"
	if "$mounted" ; then	
		install_menu=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$install_type_msg" 14 64 5 \
			"Arch-Linux-Base" 			"$base_msg0" \
			"Arch-Linux-Base-Devel" 	"$base_msg1" \
			"Arch-Linux-GrSec"			"$grsec_msg" \
			"Arch-Linux-LTS-Base" 		"$LTS_msg0" \
			"Arch-Linux-LTS-Base-Devel" "$LTS_msg1" 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
				main_menu
			else
				prepare_base
			fi
		fi

		case "$install_menu" in
			"Arch-Linux-Base")
				base_install="base sudo"
			;;
			"Arch-Linux-Base-Devel") 
				base_install="base base-devel"
			;;
			"Arch-Linux-GrSec")
				base_install="base linux-grsec sudo"
			;;
			"Arch-Linux-LTS-Base")
				base_install="base linux-lts sudo"
			;;
			"Arch-Linux-LTS-Base-Devel")
				base_install="base base-devel linux-lts"
			;;
		esac

		while (true)
		  do
			bootloader=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$loader_type_msg" 12 64 3 \
				"grub"			"$loader_msg" \
				"syslinux" 		"$loader_msg1" \
				"$none" "-" 3>&1 1>&2 2>&3)
		
			if [ "$?" -gt "0" ]; then
				if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
					main_menu
				fi
			else
				if [ "$bootloader" == "grub" ] || [ "$bootloader" == "syslinux" ]; then
					base_install="$base_install $bootloader" ; break
				else
					if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "$grub_warn_msg0" 10 60) then
						dialog --ok-button "$ok" --msgbox "$grub_warn_msg1" 10 60
						break
					fi
				fi
			fi			
		done

		if "$UEFI" ; then
			base_install="$base_install efibootmgr"
		fi

		if ! "$wifi" ; then
			if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$wifi_option_msg" 10 60) then
				net_menu=true
			fi
		else
			net_menu=true
		fi

		if "$net_menu" ; then
			while (true)
			  do
				net_util=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$wifi_util_msg" 12 64 3 \
					"netctl"			"$net_util_msg0" \
					"networkmanager" 		"$net_util_msg1" \
					"$none" "-" 3>&1 1>&2 2>&3)
		
				if [ "$?" -gt "0" ]; then
					if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
						main_menu
					fi
				else
					if [ "$net_util" == "netctl" ]; then
						base_install="$base_install $net_util wireless_tools wpa_supplicant wpa_actiond dialog" enable_nm=true ; break
					elif [ "$net_util" == "networkmanager" ]; then
						base_install="$base_install $net_util wireless_tools wpa_supplicant wpa_actiond" enable_nm=true ; break
					else
						if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "$net_warn_msg" 10 60) then
							break
						fi
					fi
				fi			
			done
		fi

		if "$bluetooth" ; then
			if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$bluetooth_msg" 10 60) then
				base_install="$base_install bluez bluez-utils"
				enable_bt=true
			fi
		fi
		
		if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$os_prober_msg" 10 60) then
			base_install="$base_install os-prober"
		fi

		if "$enable_f2fs" ; then
			base_install="$base_install f2fs-tools"
		fi
	
	elif "$INSTALLED" ; then
		dialog --ok-button "$ok" --msgbox "\n$install_err_msg0" 10 60
		main_menu
	
	else

		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$install_err_msg1" 10 60) then
			prepare_drives
		else
			dialog --ok-button "$ok" --msgbox "\n$install_err_msg2" 10 60
			main_menu
		fi
	fi
	
	install_base

}

install_base() {

	pacstrap "$ARCH" --print-format='%s' $(echo "$base_install") | sed '1,6d' | awk '{s+=$1} END {print s/1024/1024}' &> /tmp/size.tmp &
	pid=$! pri=0.8 msg="\n$pacman_load \n\n \Z1> \Z2pacman -Sy\Zn" load
	download_size=$(</tmp/size.tmp) ; rm /tmp/size.tmp
	export software_size=$(echo "$download_size Mib")
	cal_rate
	
	if (dialog --yes-button "$install" --no-button "$cancel" --yesno "\n$install_var" 15 60); then
		tmpfile=$(mktemp)
		
		if "$exclude_man" ; then
			man_db=$(echo -e "0" | pacstrap -i $ARCH base | grep -o "....man-db" | awk '{print $1}' | sed 's/)//') &> /dev/null
			man_pages=$(echo -e "0" | pacstrap -i $ARCH base | grep -o "....man-pages" | awk '{print $1}' | sed 's/)//') &> /dev/null
			base_int=$(echo -e "0" | pacstrap -i $ARCH base | grep -o "...members" | awk '{print $1}') &> /dev/null

			if (<<<"$base_install" grep "base-devel" &> /dev/null); then
				(echo -e "1-$((man_db-1)) $((man_pages+1))-$base_int\n\ny" | pacstrap -i "$ARCH" $(echo "$base_install") ; echo "$?" > /tmp/ex_status) &> "$tmpfile" &
			else
				(echo -e "1-$((man_db-1)) $((man_pages+1))-$base_int\ny" | pacstrap -i "$ARCH" $(echo "$base_install") ; echo "$?" > /tmp/ex_status) &> "$tmpfile" &
			fi
		else
			(LANG=C pacstrap "$ARCH" $(echo "$base_install") ; echo "$?" > /tmp/ex_status) &> "$tmpfile" &
		fi
		pid=$! pri=$(echo "$down+1" | bc | sed 's/\..*$//') msg="\n$install_load_var" load_log
		genfstab -U -p "$ARCH" >> "$ARCH"/etc/fstab

		if [ $(</tmp/ex_status) -eq "0" ]; then
			INSTALLED=true
		else
			mv "$tmpfile" /tmp/archNAS.log
			dialog --ok-button "$ok" --msgbox "\n$failed_msg" 10 60
			reset ; tail /tmp/archNAS.log ; exit 1
		fi
		
		if "$enable_f2fs" && ! "$crypted" && ! "$UEFI" ; then
			arch-chroot "$ARCH" mkinitcpio -p linux &> /dev/null &
			pid=$! pri=1 msg="\n$f2fs_config_load \n\n \Z1> \Z2mkinitcpio -p linux\Zn" load
		fi
			
		case "$net_util" in
			networkmanager)	arch-chroot "$ARCH" systemctl enable NetworkManager.service &>/dev/null
        					pid=$! pri=0.1 msg="\n$nwmanager_msg0 \n\n \Z1> \Z2systemctl enable NetworkManager.service\Zn" load
			;;
			netctl)	arch-chroot "$ARCH" systemctl enable netctl.service &>/dev/null &
        			pid=$! pri=0.1 msg="\n$nwmanager_msg1 \n\n \Z1> \Z2systemctl enable netctl.service\Zn" load
			;;
		esac

    	if "$enable_bt" ; then
    	    arch-chroot "$ARCH" systemctl enable bluetooth &>/dev/null &
    	    pid=$! pri=0.1 msg="\n$btenable_msg \n\n \Z1> \Z2systemctl enable bluetooth.service\Zn" load
    	fi
	
		case "$bootloader" in
			grub) grub_config ;;
			syslinux) syslinux_config ;;
		esac

		configure_system
	else
		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
			main_menu
		else
			install_base
		fi
	fi

}

grub_config() {
	
	if "$crypted" ; then
		sed -i 's!quiet!cryptdevice=/dev/lvm/lvroot:root root=/dev/mapper/root!' "$ARCH"/etc/default/grub
	else
		sed -i 's/quiet//' "$ARCH"/etc/default/grub
	fi

	if "$UEFI" ; then
		arch-chroot "$ARCH" grub-install --efi-directory="$esp_mnt" --target=x86_64-efi --bootloader-id=boot &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install --efi-directory="$esp_mnt"\Zn" load
		mv "$ARCH"/"$esp"/EFI/boot/grubx64.efi "$ARCH"/"$esp"/EFI/boot/bootx64.efi
				
		if ! "$crypted" ; then
			arch-chroot "$ARCH" mkinitcpio -p linux &> /dev/null &
			pid=$! pri=1 msg="\n$uefi_config_load \n\n \Z1> \Z2mkinitcpio -p linux\Zn" load
		fi
	else
		arch-chroot "$ARCH" grub-install /dev/"$DRIVE" &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install /dev/$DRIVE\Zn" load
	fi
	arch-chroot "$ARCH" grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null &
	pid=$! pri=0.1 msg="\n$grub_load2 \n\n \Z1> \Z2grub-mkconfig -o /boot/grub/grub.cfg\Zn" load

}

syslinux_config() {

	if "$UEFI" ; then
		esp_part_int=$(<<<"$esp_part" grep -o "[0-9]")
		esp_part=$(<<<"$esp_part" grep -o "sd[a-z]")
		esp_mnt=$(<<<$esp_mnt sed "s!$ARCH!!")
		(mkdir -p ${ARCH}${esp_mnt}/EFI/syslinux
		cp -r "$ARCH"/usr/lib/syslinux/efi64/* ${ARCH}${esp_mnt}/EFI/syslinux/
		cp /usr/share/archNAS/syslinux/syslinux_efi.cfg ${ARCH}${esp_mnt}/EFI/syslinux/syslinux.cfg
		cp /usr/share/archNAS/syslinux/splash.png ${ARCH}${esp_mnt}/EFI/syslinux
		arch-chroot "$ARCH" efibootmgr -c -d /dev/"$esp_part" -p "$esp_part_int" -l /EFI/syslinux/syslinux.efi -L "Syslinux") &> /dev/null &
		pid=$! pri=0.1 msg="\n$syslinux_load \n\n \Z1> \Z2syslinux install efi mode...\Zn" load
		
		if [ "$esp_mnt" != "/boot" ]; then
			dialog --ok-button "$ok" --msgbox "\n$esp_warn_msg" 11 60
			cp "$ARCH"/boot/{vmlinuz-linux,initramfs-linux.img,initramfs-linux-fallback.img} ${ARCH}${esp_mnt} &
			pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2cp "$ARCH"/boot/vmlinuz-linux ${ARCH}${esp_mnt}\Zn" load
		fi
		
	else
		(syslinux-install_update -i -a -m -c "$ARCH"
		cp "$ARCH"/usr/lib/syslinux/bios/vesamenu.c32 "$ARCH"/boot/syslinux/
		cp /usr/share/archNAS/syslinux/{syslinux.cfg,splash.png} "$ARCH"/boot/syslinux) &> /dev/null &
		pid=$! pri=0.1 msg="\n$syslinux_load \n\n \Z1> \Z2syslinux-install_update -i -a -m -c $ARCH\Zn" load
	fi

	if "$crypted" && "$UEFI"; then
			sed -i "s|APPEND.*$|APPEND root=/dev/mapper/root cryptdevice=/dev/lvm/lvroot:root rw|" ${ARCH}${esp_mnt}/EFI/syslinux/syslinux.cfg
	elif "$crypted" ; then
			sed -i "s|APPEND.*$|APPEND root=/dev/mapper/root cryptdevice=/dev/lvm/lvroot:root rw|" "$ARCH"/boot/syslinux/syslinux.cfg
	elif "$UEFI" ; then
		sed -i "s|APPEND.*$|APPEND root=/dev/$ROOT|" ${ARCH}${esp_mnt}/EFI/syslinux/syslinux.cfg
	else
		sed -i "s|APPEND.*$|APPEND root=/dev/$ROOT|" "$ARCH"/boot/syslinux/syslinux.cfg
	fi

}

configure_system() {

	op_title="$config_op_msg"
	if "$crypted" && "$UEFI" ; then
		echo "/dev/$BOOT              $esp           vfat         rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro        0       2" > "$ARCH"/etc/fstab
	elif "$crypted" ; then
		echo "/dev/$BOOT              /boot           $FS         defaults        0       2" > "$ARCH"/etc/fstab
	fi
		
	if "$crypted" ; then
		echo "/dev/mapper/root        /               $FS         defaults        0       1" >> "$ARCH"/etc/fstab
		echo "/dev/mapper/tmp         /tmp            tmpfs        defaults        0       0" >> "$ARCH"/etc/fstab
		echo "tmp	       /dev/lvm/tmp	       /dev/urandom	tmp,cipher=aes-xts-plain64,size=256" >> "$ARCH"/etc/crypttab
		if "$SWAP" ; then
			echo "/dev/mapper/swap     none            swap          sw                    0       0" >> "$ARCH"/etc/fstab
			echo "swap	/dev/lvm/swap	/dev/urandom	swap,cipher=aes-xts-plain64,size=256" >> "$ARCH"/etc/crypttab
		fi
		sed -i 's/k filesystems k/k lvm2 encrypt filesystems k/' "$ARCH"/etc/mkinitcpio.conf
		arch-chroot "$ARCH" mkinitcpio -p linux &> /dev/null &
		pid=$! pri=1 msg="\n$encrypt_load1 \n\n \Z1> \Z2mkinitcpio -p linux\Zn" load
	fi

	sed -i -e "s/#$LOCALE/$LOCALE/" "$ARCH"/etc/locale.gen
	echo LANG="$LOCALE" > "$ARCH"/etc/locale.conf
	arch-chroot "$ARCH" locale-gen &> /dev/null &
	pid=$! pri=0.1 msg="\n$locale_load_var \n\n \Z1> \Z2LANG=$LOCALE ; locale-gen\Zn" load
	
	if [ "$keyboard" != "$default" ]; then
		echo "KEYMAP=$keyboard" > "$ARCH"/etc/vconsole.conf
	fi

	if [ -n "$SUB_SUBZONE" ]; then
		arch-chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE" /etc/localtime &
		pid=$! pri=0.1 msg="\n$zone_load_var \n\n \Z1> \Z2ln -s $ZONE /etc/localtime\Zn" load
	fi

	if [ "$arch" == "x86_64" ]; then
		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n\n$multilib_msg" 11 60) then
			sed -i '/\[multilib]$/ {
			N
			/Include/s/#//g}' /mnt/etc/pacman.conf
		fi
	fi

	if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n\n$dhcp_msg" 11 60) then
		arch-chroot "$ARCH" systemctl enable dhcpcd.service &> /dev/null &
		pid=$! pri=0.1 msg="\n$dhcp_load \n\n \Z1> \Z2systemctl enable dhcpcd\Zn" load
	fi

	set_hostname

}

set_hostname() {

	op_title="$host_op_msg"
	hostname=$(dialog --ok-button "$ok" --nocancel --inputbox "\n$host_msg" 12 55 "archNAS" 3>&1 1>&2 2>&3 | sed 's/ //g')
	
	if (<<<$hostname grep "^[0-9]\|[\[\$\!\'\"\`\\|%&#@()+=<>~;:/?.,^{}]\|]" &> /dev/null); then
		dialog --ok-button "$ok" --msgbox "\n$host_err_msg" 10 60
		set_hostname
	fi
	
	echo "$hostname" > "$ARCH"/etc/hostname
	cp /usr/share/archNAS/.bashrc-root "$ARCH"/root/.bashrc
	cp /usr/share/archNAS/.bashrc "$ARCH"/etc/skel/

	op_title="$passwd_op_msg"
	while [ "$input" != "$input_chk" ]
	  do
		input=$(dialog --nocancel --clear --insecure --passwordbox "$root_passwd_msg0" 11 55 --stdout)
    	input_chk=$(dialog --nocancel --clear --insecure --passwordbox "$root_passwd_msg1" 11 55 --stdout)
	 	
	 	if [ -z "$input" ]; then
	 		dialog --ok-button "$ok" --msgbox "\n$passwd_msg0" 10 55
	 		input_chk=default
	 	
	 	elif [ "$input" != "$input_chk" ]; then
	 	     dialog --ok-button "$ok" --msgbox "\n$passwd_msg1" 10 55
	 	fi
	done

	(printf "$input\n$input" | arch-chroot "$ARCH" passwd) &> /dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2passwd root\Zn" load
	unset input input_chk ; input_chk=default
	add_user

}

add_user() {

	op_title="$user_op_msg"
	if ! "$menu_enter" ; then
		if ! (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$user_msg0" 10 60)
	fi

	user=$(dialog --nocancel --inputbox "\n$user_msg1" 12 55 "" 3>&1 1>&2 2>&3 | sed 's/ //g')
	if [ -z "$user" ]; then
		dialog --ok-button "$ok" --msgbox "\n$user_err_msg" 10 60
		add_user
	elif (<<<$user grep "^[0-9]\|[ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\$\!\'\"\`\\|%&#@()_-+=<>~;:/?.,^{}]\|]" &> /dev/null); then
		dialog --ok-button "$ok" --msgbox "\n$user_err_msg" 10 60
		add_user
	fi

	(arch-chroot "$ARCH" useradd -m -g users -G audio,network,power,storage,optical -s "$sh" "$user") &>/dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2useradd -m -g users -G ... -s /usr/bin/zsh $user\Zn" load

	source "$lang_file"
	op_title="$passwd_op_msg"
	while [ "$input" != "$input_chk" ]
	  do
		input=$(dialog --nocancel --clear --insecure --passwordbox "$user_var0" 11 55 --stdout)
    	input_chk=$(dialog --nocancel --clear --insecure --passwordbox "$user_var1" 11 55 --stdout)
		 
		if [ -z "$input" ]; then
			dialog --ok-button "$ok" --msgbox "\n$passwd_msg0" 10 55
			input_chk=default
		elif [ "$input" != "$input_chk" ]; then
			dialog --ok-button "$ok" --msgbox "\n$passwd_msg1" 10 55
		fi
	done

	(printf "$input\n$input" | arch-chroot "$ARCH" passwd "$user") &> /dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2passwd $user\Zn" load
	unset input input_chk ; input_chk=default
	op_title="$user_op_msg"
	
	if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$sudo_var" 10 60) then
		(sed -i '/%wheel ALL=(ALL) ALL/s/^#//' $ARCH/etc/sudoers
		arch-chroot "$ARCH" usermod -a -G wheel "$user") &> /dev/null &
		pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2usermod -a -G wheel $user\Zn" load
	fi

	if "$menu_enter" ; then
		reboot_system
	fi

}

install_software() {

	op_title="$software_op_msg"
	if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$software_msg0" 10 60) then
		
		until "$software_selected"
		  do
			unset software
			err=false
			if ! "$skip" ; then
				software_menu=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$software_type_msg" 20 63 11 \
					"$internet" "$internet_msg" \
					"$text_editor" "$text_editor_msg" \
					"$shell" "$shell_msg" \
					"$system" "$system_msg" \
					"$done_msg" "$install \Z2============>\Zn" 3>&1 1>&2 2>&3)
			
				if [ "$?" -gt "0" ]; then
					if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "$software_warn_msg" 10 60) then
						software_selected=true
						err=true
						unset software_menu
					else
						err=true
					fi
				fi
			else
				skip=false
			fi

			case "$software_menu" in
				"$internet")
					software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 19 60 9 \
						"transmission-cli" 		"$net0" OFF 3>&1 1>&2 2>&3)
					if [ "$?" -gt "0" ]; then
						err=true
					elif "$desktop" ; then
						if (<<<$download grep "networkmanager"); then
							download=$(<<<$download sed 's/networkmanager/networkmanager network-manager-applet/')
						fi
					fi
				;;
				"$text_editor")
					software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 17 60 7 \
						"vim"			"$edit0" OFF 3>&1 1>&2 2>&3)
					if [ "$?" -gt "0" ]; then
						err=true
					fi
				;;
				"$shell")
					software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 15 50 5 \
						"dash"	"$shell0" OFF \
						"fish"	"$shell1" OFF \
						"mksh"	"$shell2" OFF \
						"tcsh"	"$shell3" OFF \
						"zsh"	"$shell4" OFF 3>&1 1>&2 2>&3)
					if [ "$?" -gt "0" ]; then
						err=true
					fi
				;;
				"$system")
					software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 65 10 \
						"arch-wiki"		"$sys0" ON \
						"apache"		"$sys1" OFF \
						"fetchmirrors"	"$sys10" ON \
						"git"			"$sys2" OFF \
						"htop"			"$sys3" OFF \
						"inxi"			"$sys4" OFF \
						"nmap"			"$sys5" OFF \
						"openssh"		"$sys6" OFF \
						"ranger"		"$sys9" OFF \
						"ufw"			"$sys7" ON \
						"wget"			"$sys8" ON 3>&1 1>&2 2>&3)
					if [ "$?" -gt "0" ]; then
						err=true
					fi

					if (<<<$software grep "arch-wiki" &> /dev/null); then
						pkg=$(ls /usr/share/archNAS/pkg | grep arch-wiki)
						cp /usr/share/archNAS/pkg/"$pkg" "$ARCH"/var/cache/pacman/pkg
						arch-chroot "$ARCH" pacman -U --noconfirm /var/cache/pacman/pkg/"$pkg" &> /dev/null &
						pid=$! pri=0.1 msg="\nInstalling arch-wiki... \n\n \Z1> \Z2pacman -U $pkg\Zn" load
						software=$(<<<$software sed 's/arch-wiki//')
					fi

					if (<<<$software grep "fetchmirrors" &> /dev/null); then
						pkg="$(ls /usr/share/archNAS/pkg | grep fetchmirrors)"
						cp /usr/share/archNAS/pkg/"$pkg" "$ARCH"/var/cache/pacman/pkg
						arch-chroot "$ARCH" pacman -U --noconfirm /var/cache/pacman/pkg/"$pkg" &> /dev/null &
						pid=$! pri=0.1 msg="\nInstalling fetchmirrors... \n\n \Z1> \Z2pacman -U $pkg\Zn" load
						software=$(<<<$software sed 's/fetchmirrors//')
					fi

				;;
				"$done_msg")
					if [ -z "$final_software" ]; then
						if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$software_warn_msg" 10 60) then
							software_selected=true
							err=true
						fi
					else
						download=$(echo "$final_software" | sed 's/\"//g' | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2- | sed 's/$/ /g' | tr -d '\n')
						export download_list=$(echo "$download" |  sed -e 's/^[ \t]*//')
						pacstrap "$ARCH" --print-format='%s' $(echo "$download") | sed '1,6d' | awk '{s+=$1} END {print s/1024/1024}' &> /tmp/size.tmp &
						pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2pacman -S --print-format=%s\Zn" load
						download_size=$(</tmp/size.tmp) ; rm /tmp/size.tmp
						export software_size=$(echo "$download_size Mib")
						export software_int=$(echo "$download" | wc -w)
						cal_rate

						if [ "$software_int" -lt "20" ]; then
							height=17
						else
							height=20
						fi
						
						if (dialog --yes-button "$install" --no-button "$cancel" --yesno "\n$software_confirm_var1" "$height" 65) then
							tmpfile=$(mktemp)
						    pacstrap "$ARCH" $(echo "$download") &> "$tmpfile" &
						    pid=$! pri=$(<<<"$down" sed 's/\..*$//') msg="\n$software_load_var" load_log
	  					    rm "$tmpfile"
	  					    unset final_software
	  					    software_selected=true err=true
						else
							unset final_software
							err=true
						fi
					fi
				;;
			esac
			
			if ! "$err" ; then
				if [ -z "$software" ]; then
					if ! (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "$software_noconfirm_msg ${software_menu}?" 10 60) then
						skip=true
					fi
				else
					add_software=$(echo "$software" | sed 's/\"//g')
					software_list=$(echo "$add_software" | sed -e 's/^[ \t]*//')
					
					pacstrap "$ARCH" --print-format='%s' $(echo "$add_software") | sed '1,6d' | awk '{s+=$1} END {print s/1024/1024}' &> /tmp/size.tmp &
					pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2pacman -S --print-format=%s\Zn" load
					download_size=$(</tmp/size.tmp) ; rm /tmp/size.tmp
					software_size=$(echo "$download_size Mib")
					software_int=$(echo "$add_software" | wc -w)
					source "$lang_file"
				
					if [ "$software_int" -lt "15" ]; then
						height=14
					else
						height=16
					fi

					if (dialog --yes-button "$add" --no-button "$cancel" --yesno "\n$software_confirm_var0" "$height" 60) then
						final_software="$software $final_software"
					fi
				fi
			fi
		done
		err=false
	fi
	
	if ! "$pac_update" ; then
		if [ -f "$ARCH"/var/lib/pacman/db.lck ]; then
			rm "$ARCH"/var/lib/pacman/db.lck &> /dev/null
		fi

		arch-chroot "$ARCH" pacman -Sy &> /dev/null &
		pid=$! pri=0.8 msg="\n$pacman_load \n\n \Z1> \Z2pacman -Sy\Zn" load
		pac_update=true
	fi

	software_selected=false
	reboot_system

}

reboot_system() {

	op_title="$complete_op_msg"
	if "$INSTALLED" ; then
		if [ "$bootloader" == "$none" ]; then
			if (dialog --yes-button "$yes" --no-button "$no" --yesno "$complete_no_boot_msg" 10 60) then
				reset ; exit
			fi
		fi

		reboot_menu=$(dialog --nocancel --ok-button "$ok" --menu "$complete_msg" 16 60 7 \
			"$reboot0" "-" \
			"$reboot6" "-" \
			"$reboot2" "-" \
			"$reboot1" "-" \
			"$reboot3" "-" \
			"$reboot4" "-" \
			"$reboot5" "-" 3>&1 1>&2 2>&3)
		
		case "$reboot_menu" in
			"$reboot0")		umount -R "$ARCH"
							reset ; reboot ; exit
			;;
			"$reboot6")		umount -R "$ARCH"
							reset ; poweroff ; exit
			;;
			"$reboot1")		umount -R "$ARCH"
							reset ; exit
			;;
			"$reboot2")		clear
							echo -e "$arch_chroot_msg" 
							echo "/root" > /tmp/chroot_dir.var
							arch_anywhere_chroot
							clear
			;;
			"$reboot3")		if (dialog --yes-button "$yes" --no-button "$no" --yesno "$user_exists_msg" 10 60); then
								menu_enter=true
								add_user	
							else
								reboot_system
							fi
			;;
			"$reboot4")		if "$desktop" ; then
								if (dialog --yes-button "$yes" --no-button "$no" --yesno "$desktop_exists_msg" 10 60); then
									menu_enter=true
									graphics
								else
									reboot_system
								fi
							else
								if (dialog --yes-button "$yes" --no-button "$no" --yesno "$desktop_exists_msg" 10 60); then
									graphics
								fi
							fi
			;;
			"$reboot5")		install_software
			;;
		esac

	else

		if (dialog --yes-button "$yes" --no-button "$no" --yesno "$not_complete_msg" 10 60) then
			umount -R $ARCH
			reset ; reboot ; exit
		else
			main_menu
		fi
	fi

}

main_menu() {

	op_title="$menu_op_msg"
	menu_item=$(dialog --nocancel --ok-button "$ok" --menu "$menu" 20 60 9 \
		"$menu13" "-" \
		"$menu0"  "-" \
		"$menu1"  "-" \
		"$menu2"  "-" \
		"$menu3"  "-" \
		"$menu4"  "-" \
		"$menu5"  "-" \
		"$menu11" "-" \
		"$menu12" "-" 3>&1 1>&2 2>&3)

	case "$menu_item" in
		"$menu0")	set_locale
		;;
		"$menu1")	set_zone
		;;
		"$menu2")	set_keys
		;;
		"$menu3")	if "$mounted" ; then 
						if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$menu_err_msg3" 10 60); then
							mounted=false ; prepare_drives
						else
							main_menu
						fi
					fi
 					prepare_drives 
		;;
		"$menu4") 	update_mirrors
		;;
		"$menu5")	prepare_base
		;;
		"$menu11") 	reboot_system
		;;
		"$menu12") 	if "$INSTALLED" ; then
						dialog --ok-button "$ok" --msgbox "\n$menu_err_msg4" 10 60
						reset ; exit
					else

						if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$menu_exit_msg" 10 60) then
							reset ; exit
						else
							main_menu
						fi
					fi
		;;
		"$menu13")	echo -e "alias archNAS=exit ; echo -e '$return_msg'" > /tmp/.zshrc
					clear
					ZDOTDIR=/tmp/ zsh
					rm /tmp/.zshrc
					clear
					main_menu
		;;
	esac

}

arch_anywhere_chroot() {

	local char=
    local input=
    local -a history=( )
    local -i histindex=0
	trap ctrl_c INT
	working_dir=$(</tmp/chroot_dir.var)
	
	while (true)
	  do
		echo -n "${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}" ; while IFS= read -r -n 1 -s char
		  do
			if [ "$char" == $'\x1b' ]; then
				while IFS= read -r -n 2 -s rest
          		  do
                	char+="$rest"
                	break
            	done
        	fi

			if [ "$char" == $'\x1b[D' ]; then
				pos=-1

			elif [ "$char" == $'\x1b[C' ]; then
				pos=1

			elif [[ $char == $'\177' ]];  then
				input="${input%?}"
				echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${input}"
			
			elif [ "$char" == $'\x1b[A' ]; then
            # Up
            	if [ $histindex -gt 0 ]; then
                	histindex+=-1
                	input=$(echo -ne "${history[$histindex]}")
					echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ "$char" == $'\x1b[B' ]; then
            # Down
            	if [ $histindex -lt $((${#history[@]} - 1)) ]; then
                	histindex+=1
                	input=$(echo -ne "${history[$histindex]}")
                	echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ -z "$char" ]; then
            # Newline
				echo
            	history+=( "$input" )
            	histindex=${#history[@]}
				break
        	else
            	echo -n "$char"
            	input+="$char"
        	fi  
		done
    	
		if [ "$input" == "archNAS" ] || [ "$input" == "exit" ]; then
        	rm /tmp/chroot_dir.var &> /dev/null
			clear
			break
	    elif (<<<"$input" grep "^cd " &> /dev/null); then 
	    	ch_dir=$(<<<$input cut -c4-)
	        arch-chroot "$ARCH" /bin/bash -c "cd $working_dir ; cd $ch_dir ; pwd > /etc/chroot_dir.var"
	        mv "$ARCH"/etc/chroot_dir.var /tmp/
			working_dir=$(</tmp/chroot_dir.var)
		elif  (<<<"$input" grep "^help" &> /dev/null); then
			echo -e "$arch_chroot_msg"
		else
	    	arch-chroot "$ARCH" /bin/bash -c "cd $working_dir ; $input"
	    fi   
	input=
	done

	reboot_system

}

ctrl_c() {

	echo
	echo "${Red} Exiting and cleaning up..."
	sleep 0.5
	unset input
	rm /tmp/chroot_dir.var &> /dev/null
	clear
	reboot_system

}

dialog() {

	if "$screen_h" ; then
		/usr/bin/dialog --colors --backtitle "$backtitle" --title "$op_title" "$@"
	else
		/usr/bin/dialog --colors --title "$title" "$@"
	fi

}

cal_rate() {
			
	case "$connection_rate" in
		KB/s) 
			down_sec=$(echo "$download_size*1024/$connection_speed" | bc) ;;
		MB/s)
			down_sec=$(echo "$download_size/$connection_speed" | bc) ;;
		*) 
			down_sec="1" ;;
	esac
        
	down=$(echo "$down_sec/100+$cpu_sleep" | bc)
	down_min=$(echo "$down*100/60" | bc)
	
	if ! (<<<$down grep "^[1-9]" &> /dev/null); then
		down=3
		down_min=5
	fi
	
	export down down_min
	source "$lang_file"

}

load() {

	{	int="1"
        	while ps | grep "$pid" &> /dev/null
    	    	do
    	            sleep $pri
    	            echo $int
    	        	if [ "$int" -lt "100" ]; then
    	        		int=$((int+1))
    	        	fi
    	        done
            echo 100
            sleep 1
	} | dialog --gauge "$msg" 9 79 0

}

load_log() {
	
	{	int=1
		pos=1
		pri=$((pri*2))
		while ps | grep "$pid" &> /dev/null
    	    do
    	        sleep 0.5
    	        if [ "$pos" -eq "$pri" ] && [ "$int" -lt "100" ]; then
    	        	pos=0
    	        	int=$((int+1))
    	        fi
    	        log=$(tail -n 1 "$tmpfile" | sed 's/.pkg.tar.xz//')
    	        echo "$int"
    	        echo -e "XXX$msg \n \Z1> \Z2$log\Zn\nXXX"
    	        pos=$((pos+1))
    	    done
            echo 100
            sleep 1
	} | dialog --gauge "$msg" 10 79 0

}

opt="$1"
init
