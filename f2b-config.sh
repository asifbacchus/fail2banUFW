#!/bin/bash

#######
### Copy customized jails, filters and action configuration files to fail2ban
### directory and activate them
#######


### set script output colours
normal="\e[0m"
bold="\e[1m"
default="\e[39m"
err="\e[1;31m"
warn="\e[1;93m"
ok="\e[32m"
lit="\e[93m"
op="\e[39m"
info="\e[96m"
note="\e[95m"


### functions

### end of functions


### pre-requisites
# exit script if fail2ban is not installed
if ! [ -x "$(command -v fail2ban-client)" ]; then
    echo
    echo -e "${err}Cannot find fail2ban, is it installed? Exiting script." \
        "${normal}"
    echo
    exit 1
fi

# check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${err}This script MUST be run as ROOT. Exiting.${normal}"
    echo
    exit 2
fi


### default values for variables
F2B-DIR='/etc/fail2ban'