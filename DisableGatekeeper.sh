#!/bin/bash
#
# This script will drop a flat file to indicate the machine should not have Gatekeeper enabled, and set a
# LaunchAgent to automatically re-set Gatekeeper in 20 minutes. The LaunchAgent will really just remove the file
# and re-run inventory, and Casper will consider the deferral period over and move the device back into "normal" mode.
#
# Written by Graham Wells
# graham.wells@gmail.com
# 09-12-2016
#
###################################################################################################################################################

# This is what is required for this to work:
#
#		- Create an extension attribute that looks for the file $gatekeeperFile below (Has the file, Yes/No)
#		- Create a Smart Group of devices that have that file present (Has Gatekeeper File = Yes)
#		- Exclude that Smart Group from whichever configuration profile that enforces Gatekeeper settings 
#		- Set this script up in the JSS and set a policy to run it only for Self Service. You'll also want to deliver the reinstateGatekeeper.sh script
#			as well. See this link: https://github.com/grahamfw/Mac-scripts/blob/master/reinstateGatekeeper.sh
#
###################################################################################################################################################



##### Edit this here
companyShortName="somecompany"
gatekeeperFile="/var/sandbox/com.$companyShortName.disabled.gatekeeper.plist"

# File that we key off of for the Smart group that is excluded from the Gatekeeper config profile
/usr/bin/touch $gatekeeperFile

# Set log file where we can see when this stuff ran
logFile="/var/sandbox/disableGatekeeper.log"

# Run recon so inventory is updated
/usr/local/bin/jamf recon

# Define a few variables 
plist="/Library/LaunchAgents/com.$companyShortName.deferral.gatekeeper.plist"
timestamp ()  { date "+%Y-%m-%d %H:%M:%S" ; }

# Get time that the deferral should be over after adding 20 mins
currentDateInSeconds=`date +%s`
targetDate=`date -v+20M "+%Y-%m-%d %H:%M:%S"`
echo "$(timestamp) Setting Gatekeeper to be disabled until $targetDate..." >> $logFile

# Parse targetDate date/time components into usable variables
targetDate=`echo $targetDate | sed 's/[:-]/ /g'`
IFS=" "
targetDateAndTimeArr=( ${targetDate} )

# Populate year, month, day, hour, minutes, seconds variables from array elements. We are not using all of these.
year=${targetDateAndTimeArr[0]}
month=${targetDateAndTimeArr[1]}
day=${targetDateAndTimeArr[2]}
hour=${targetDateAndTimeArr[3]}
minute=${targetDateAndTimeArr[4]}
second=${targetDateAndTimeArr[5]}

# Unload and delete the plist if it exists already
if [[ -f $plist ]]; then
	/bin/launchctl unload $plist
	echo "$(timestamp) Unloaded $plist..." >> $logFile
	rm -rf $plist
	echo "$(timestamp) Removed $plist..." >> $logFile
fi

# Create a new plist to be run after 20 minutes, then load it
defaults write $plist "<dict>
<key>Label</key>
<string>com.$companyShortName.deferral.gatekeeper</string>
<key>ProgramArguments</key>
<array>
<string>/var/sandbox/reinstateGatekeeper.sh</string>
</array>
<key>StartCalendarInterval</key>
<dict>
<key>Minute</key>
<integer>$minute</integer>
<key>Hour</key>
<integer>$hour</integer>
</dict>
</dict>"

chmod 644 $plist
/bin/launchctl load $plist >> $logFile
echo "$(timestamp) Loaded $plist..."  >> $logFile

# Sleep 10 seconds, then disable Gatekeeper manually.
sleep 10
/usr/sbin/spctl --master-disable
echo "$(timestamp) Slept 10 seconds and disabled Gatekeeper..." >> $logFile


