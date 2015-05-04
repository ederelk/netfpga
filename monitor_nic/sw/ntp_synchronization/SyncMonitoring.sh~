#! /bin/bash

export MON_DIR=$NF_ROOT/projects/monitor_nic/sw

ntptime >> server.txt
$MON_DIR/ntp_synchronization/ntp server.txt

if [ $? -eq 0 ]; then
	regwrite 0x2001200 0xf
	regwrite 0x2001200 0x1
	rm -rf server.txt
        echo Synchronization Complete!!!
else
	echo ERROR:Cannot find NTP server.
fi


