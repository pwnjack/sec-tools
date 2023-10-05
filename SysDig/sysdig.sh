#!/bin/bash

### Configuration ###
# Define your list of hosts
hosts=(
    "host1"
    "host2"
    "host3"
)

# Encryption key for openssl
encryption_key="your_encryption_key"

# Server for file transfer
server="user@your_server:/path/to/save/"

# Set to true to perform keyword search
search_flag=false

# Define the keyword for searching
keyword="password"

# Log file path
log_file="sysdig.log"

### Functions ###

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Function to gather system information
gather_info() {
    {
        uname -a
        cat /etc/*-release
        df -h
        free -h
        lspci
        lsusb
        ifconfig -a
        netstat -tuln
        ps aux
        systemctl list-units
        systemctl list-unit-files
        crontab -l
        uname -r
        iptables -L -n
        lsmod
        lscpu
        cat /proc/meminfo
        cat /proc/cpuinfo
        lsblk
        dmidecode
        fdisk -l
        mount
        route -n
        uptime
        who
        w
        last
        cat /etc/passwd
        cat /etc/group
        cat /etc/fstab
        cat /etc/hostname
        cat /etc/resolv.conf
        cat /etc/hosts
        cat /etc/sudoers
        cat /etc/environment
        cat /etc/security/limits.conf
        cat /etc/sysctl.conf
        ip addr show
        ip route show
        ss -tuln
        arp -a
        date
        hostname
        uname -m
        uptime
        uptime -p
        env
        set
        history
        id
        groups
        echo $SHELL
        echo $HOME
        echo $USER
        echo $LOGNAME
        echo $PATH
        echo $LD_LIBRARY_PATH
        echo $PS1
        echo $PS2
        echo $TERM
        if [ "$search_flag" = true ]; then
            search_keyword $1
        fi
    } >> "system_info_$1.txt"
}

# Function to search for keyword in files
search_keyword() {
    echo "Searching for '$keyword' in files..."
    grep -r "$keyword" / >> "system_info_$1.txt"
    echo "Search complete."
}

### Main Script ###

# Error handling
set -e

# Loop through the hosts
for host in "${hosts[@]}"
do
    echo "Connecting to $host..."

    # Try to connect via SSH and gather information
    if ssh "$host" "$(typeset -f gather_info search_keyword); gather_info $host"; then
        log "Connected to $host successfully."
    else
        log "Failed to connect to $host."
        continue  # Move to the next host
    fi

    # Encrypt the file using openssl
    openssl enc -aes-256-cbc -salt -in "system_info_$host.txt" -out "system_info_$host.enc" -k "$encryption_key"
    
    # Send the encrypted file back (using SCP)
    scp "system_info_$host.enc" "$server"

    # Clean up temporary files
    rm "system_info_$host.txt"
    rm "system_info_$host.enc"
done
