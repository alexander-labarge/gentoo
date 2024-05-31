#!/bin/bash
# einfo_timer_util.sh

# Define a function to handle errors
handle_error() {
  echo "An error occurred in the script at line $1. Do you want to retry? (y/n)"
  read answer
  if [[ "$answer" =~ ^[Yy]$ ]] ;then
    echo "Retrying..."
  else
    exit 1
  fi
}

# Set the trap to catch errors and pass the line number
trap 'handle_error $LINENO' ERR

# Define the einfo function for the chroot environment
function einfo() {
    local blue='\e[1;34m'   # Light blue
    local yellow='\e[1;33m' # Yellow
    local red='\e[1;31m'    # Red
    local reset='\e[0m'     # Reset text formatting
    local hostname=$(hostname)
    local current_datetime=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="install-log-${hostname}-$(date '+%Y-%m-%d').log"

    # Ensure the log file exists in the current directory
    touch "$log_file"

    echo -e "${red}------------------------------------------------------------------------------------------------------------${reset}"
    echo -e "${blue}[${yellow}$(date '+%Y-%m-%d %H:%M:%S')${blue}] $1${reset}"
    echo -e "${red}------------------------------------------------------------------------------------------------------------${reset}"

    # Append the log message to the log file in the current directory
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file" 2>&1
}

function einfo_purple_bold() {
    local purple_bold='\e[1;35m' # Purple and bold
    local reset='\e[0m'          # Reset text formatting
    echo -e "${purple_bold}$1${reset}"
}

# New function to execute commands and log their output and errors
function exec_and_log() {
    local command_output
    local command_error

    # Combine all arguments into one string to log the full command
    local full_command="$*"

    # Log the command being executed
    einfo "Executing command: $full_command"

    # Execute command and capture stdout and stderr
    command_output=$(eval "$full_command" 2>&1)
    command_error=$?

    # Log output
    einfo "$command_output"

    # Check if there was an error
    if [ $command_error -ne 0 ]; then
        einfo "Error (Exit Code: $command_error): $command_output"
    fi
}

function countdown_timer() {
    for ((i = 3; i >= 0; i--)); do
        if [ $i -gt 0 ]; then
            echo -ne "\r\033[K\e[31mContinuing in \e[34m$i\e[31m seconds\e[0m"
        else
            echo -e "\r\033[K\e[1;34mContinuing\e[0m"
        fi
        sleep 1
    done
}