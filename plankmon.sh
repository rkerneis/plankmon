#!/bin/bash

# primary monitor ID
primarymon='eDP-1'

# flag to keep track of current monitor setup
dualmon=false

# reconfigure plank for a dual monitor setup
switchToDualMonitor () {
	dualmon=true
	echo $(date '+%d/%m/%Y %H:%M:%S') "Switching to dual monitor $1"
	
	# copy the main dock configuration to dock2
	cp -r ~/.config/plank/dock1 ~/.config/plank/dock2
	# set secondary monitor ID in dock2 settings
	echo "$1" > ~/.config/plank/dock2/settings
	
	# copy the main dock gnome settings to new dock2 directory
	dconf dump /net/launchpad/plank/docks/dock1/ > dock_settings
	dconf load /net/launchpad/plank/docks/dock2/ < dock_settings
	rm dock_settings
	# enable dock2 in gnome settings
	dconf write /net/launchpad/plank/enabled-docks "['dock1','dock2']"
	# set secondary monitor ID in dock2 gnome settings
	dconf write /net/launchpad/plank/docks/dock2/monitor "'$1'"
	
	# kill and relaunch plank for changes to take effect
	restartPlank
}

switchToSingleMonitor () {
	dualmon=false
	echo $(date '+%d/%m/%Y %H:%M:%S') "Switching to single monitor"
	
	# remove dock2 configuration
	rm -rf ~/.config/plank/dock2
	
	# disable dock2 in gnome settings
	dconf write /net/launchpad/plank/enabled-docks "['dock1']"
	# remove dock2 directory in gnome settings
	dconf reset -f /net/launchpad/plank/docks/dock2/
	
	# kill and relaunch plank for changes to take effect
	restartPlank
}

restartPlank () {
	killall -9 plank
	nohup plank > /dev/null 2>&1 &
}

switchToSingleMonitor

# actual script
while true
do
	# poll connected monitors other than primary monitor
	secondarymon=$(xrandr | grep -oP '.*(?= connected)' | grep -v "$primarymon")
	
	if [ -z "$secondarymon" ]
	then
		if $dualmon; then switchToSingleMonitor; fi
	else
		if ! $dualmon; then switchToDualMonitor "$secondarymon"; fi
	fi

	# loop indefinitely every second
    sleep 1s
done
