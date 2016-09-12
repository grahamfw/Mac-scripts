#!/bin/bash
#
# This script will remove the Gatekeeper plist specified here.
# It will also force an inventory run, which will put the user in a smart group
# that reinstates Gatekeeper. Should be used in combination with the DisableGatekeeper framework.
#
# Written by Graham Wells
# 09-12-2016
#

# Edit this here
companyShortName="somecompany"

# Log file and timestamp function
logFile="/var/sandbox/disableGatekeeper.log"
timestamp ()  { date "+%Y-%m-%d %H:%M:%S" ; }

# Define plists here
plist="/var/sandbox/com.$companyShortName.disabled.gatekeeper.plist"
deferralPlist="/Library/LaunchAgents/com.$companyShortName.deferral.gatekeeper.plist"

# Remove plist that Casper uses to determine that Gatekeeper should be disabled
rm -rf $plist
echo "$(timestamp) Deleted $plist..." >> $logFile

# Run recon
/usr/local/bin/jamf recon
echo "$(timestamp) Re-ran recon..." >> $logFile

# Unload and delete the deferral plist
rm -rf $deferralPlist
echo "$(timestamp) Deleted $deferralPlist..." >> $logFile
/bin/launchctl unload $deferralPlist
echo "$(timestamp) Unloaded $deferralPlist..." >> $logFile
