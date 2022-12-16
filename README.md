# Automated-Aireplay-ng

# Disclaimer

This is for educational use only and network diagnostics. Do not use this script on networks that you do not own or not have permission to use. Use responsibly. I am not responsible for any trouble you get into.

# Description
This is a script to automate the aireplay-ng de-authentication process. All you have to do is specify the type of device you want to disconnect from your wireless access points and run the script. This script can be used to de-clutter your network or forcibly disconnect unwanted devices from YOUR network.

This script requires aircrack-ng installed on your system.
`sudo apt-get install aircrack-ng`

Works on linux and needs root permission.

To run,
`sudo ./deauthentication -m xx:xx:xx:xx:xx:xx`

-m is required as it specifies the device you want to disconnect from your wireless network. -n flag specifies your wireless adapter if you are using one, most of the time is set too wlan0 by default. -e specifies your network name. If your wifi network is named "Joe's-network" then do ` sudo ./deauthentication -m xx:xx:xx:xx:xx:xx -e Joe's-network`. Remember only use this on your network.

# Command line flags

-n: Network interface, normally wlan0
-m: specify a OUI or specific mac address as a target
-e: specifiy a wifi network, if not all networks are taregeted
