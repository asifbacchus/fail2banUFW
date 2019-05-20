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

function backupFiles {
    # check if file exists
    if [ -f "${F2B-DIR}/$1" ]; then
        if [ "$(cp "${F2B-DIR}/$1" "${F2B-DIR}/$1.original")" -ne 0 ]; then
            echo
            echo -e "${err}There was a problem backing up your current" \
                "configuration."
            echo -e "This suggests some kind of permissions error. Please" \
                "remedy this and rerun"
            echo -e "this script."
            echo
            echo -e "${note}Error backing up file: ${lit}$1"
            echo
            echo -e "${err}Exiting.${normal}"
            echo
            exit 100
        fi
    fi
}

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


### user info preamble
echo
echo -e "${note}------------------------------------------------------------" \
    "--------------------${normal}"
echo -e "${info}This script will copy customized configuration files to your" \
    "fail2ban"
echo -e "configuration directory.  It will backup any existing files with the" \
    "extension"
echo -e "${note}'.original'${info}.${normal}"
echo
echo -e "${info}Please ensure you have reviewed the ${note}README${info} in" \
    "this git archive and/or it's"
echo -e "associated wiki or the blog post at${note}" \
    "https://mytechiethoughts.com${info} to understand"
echo -e "how to customize these template files.${normal}"
echo -e "${note}------------------------------------------------------------" \
    "--------------------${normal}"
echo


### copy template files
