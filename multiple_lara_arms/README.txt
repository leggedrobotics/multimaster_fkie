Instructions for controlling multiple Lara arms from one operator PC

* In the configure_networking_settings.sh script, set the variables for the network interface names
* Run the script
* In fkie_master_sync/launch, set the topics which you want each ros network to receive from the other ros networks
* For each terminal (sub-)window which will run processes for one of the lara arms, add the shell PID to the cgroup corresponding to that arm (see documentation in configure_networking_settings.sh)
* Run the lara-specific launch files from fkie_master_discovery/launch in the cgroups and run the "main" launch file in a regular terminal window
* Do the same for the launch files in fkie_master_sync/launch
* When topics which are specificied in the sync launch file of ros network A are published by ros network B, they will become detectable and subscribable by network A after a few seconds
