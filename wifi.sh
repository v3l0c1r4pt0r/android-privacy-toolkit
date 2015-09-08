#!/bin/sh
# script to manually manage wifi connections
IFACE=wlan0
ENTROPY=/data/misc/wifi/entropy.bin
SOCKET=/data/misc/wifi/sockets/wpa_wlan0
CONFDIR=/data/root/etc/wifi
MOD=wl12xx_sdio

FAKEMAC=00:11:22:33:44:55
REALMAC=00:00:00:00:00:00

OP=$1

function imod
{
	modprobe $MOD 2>/dev/null;
	if [ $? -ne 0 ]; then
		echo "Failed inserting kernel module. Bye."
		exit 3;
	fi;
	echo "Inserted $MOD module to kernel. Now before using normal wifi operation you have to remove it!"
}

function rmod
{
	rmmod $MOD 2>/dev/null;
	if [ $? -ne 0 ]; then                                            
		echo "Failed removing kernel module. Bye."              
		exit 3;                                                  
	fi;
	echo "Removed $MOD. It is now safe to use wifi normally"
}

if [ $(id | cut -d' ' -f1 | sed 's/^.*=\([0-9]*\).*$/\1/') -ne 0  ]; then
	echo "You have to be root to do this";
	exit 1;
fi;

# disable GUI wifi to avoid crashing it
svc wifi disable

if [ "$OP" == "up" ]; then
	MACOP=$2
	echo "Bringing wifi up...";
	imod;
	MAC=$MACOP
	if [ -n "$MACOP" ]; then
		echo "Masking HW address..."
		ip link set dev $IFACE down
		if [ "$MACOP" == "real" ]; then
			echo "Restoring real address..."
			MAC=$REALMAC
		elif [ "$MACOP" == "fake" ]; then
			echo "Using predefined fake address..."
			MAC=$FAKEMAC
		fi;
		ip link set dev $IFACE address $MAC
		if [ $? -ne 0 ]; then
			echo "Failed to mask! Be CAREFUL!"
			exit 6
		fi;
		echo "Finished masking HW address"
	fi;
elif [ "$OP" == "connect" ]; then
	CONFFILE=$2
	if [ -e $CONFDIR/$CONFFILE.conf ]; then
		echo "Connecting to network...";
	else
		echo "Config file you gave: $CONFFILE not exists";
		exit 2;
	fi;

	imod;

	wpa_supplicant -e$ENTROPY -i$IFACE -Dnl80211 -c$CONFDIR/$CONFFILE.conf -C$SOCKET -B
	if [ $? -ne 0 ]; then
		echo "Supplicant failed to start!"
		exit 3;
	fi;

	echo -n "Wifi connection is being established..."
	for i in {1..10}; do
		LINK=$(iw dev wlan0 link | head -1 | cut -f1 -d' ');
		tmp=$(ps | grep wpa_supplicant);
		PSRET=$?
		if [ "$LINK" == "Connected" ]; then
			break;
		elif [ $PSRET -ne 0 ]; then
			echo "Supplicant crashed"
			exit 4;
		fi;
		sleep 1;
		echo -n .;
	done;
	echo -e "\nWifi connection established";

	dhcpcd -n $IFACE;
	if [ $? -ne 0 ]; then
		echo "DHCP client failed to start"
		exit 4
	fi;
	echo "DHCP started!"
elif [ "$OP" == "disconnect" ]; then
	echo "Disconnecting the network...";
	DHCPPID=$(ps | grep dhcpcd | cut -d' ' -f7)
	kill $DHCPPID 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "Failed to kill DHCP client"
	fi;
	WPAPID=$(ps | grep wpa_supplicant | cut -d' ' -f7)
	kill $WPAPID 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "Failed to kill Supplicant"
	fi;
	rmod;
fi;

