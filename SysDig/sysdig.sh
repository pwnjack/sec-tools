#!/bin/bash

### Configuration ###
# Define your list of hosts
hosts=(
    "host1"
    "host2"
    "host3"
)

# SSH key file path (update this with your SSH key file)
ssh_key="/path/to/your/ssh/key"

# Prompt for encryption key with validation
read -p "Enter encryption key: " -s encryption_key
if [ -z "$encryption_key" ]; then
    echo "Error: Encryption key cannot be empty."
    exit 1
fi
echo

# Prompt for server information with validation
read -p "Enter server (user@your_server:/path/to/save/): " server
if [ -z "$server" ]; then
    echo "Error: Server information cannot be empty."
    exit 1
fi

# Set to true to perform keyword search
read -p "Perform keyword search? (true/false): " search_flag
if [[ "$search_flag" == "true" ]]; then
    read -p "Enter keyword for search: " keyword
    if [ -z "$keyword" ]; then
        echo "Error: Keyword cannot be empty."
        exit 1
    fi
fi

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
        if [[ "$search_flag" == "true" ]]; then
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

# Loop through the hosts
for host in "${hosts[@]}"
do
    echo "Connecting to $host..."

    # Try to connect via SSH and gather information
    if ssh -o ConnectTimeout=10 -i "$ssh_key" "$server" "$(typeset -f gather_info search_keyword); gather_info $host"; then
        log "Connected to $host successfully."
        
        # Encrypt the file using openssl
        openssl enc -aes-256-cbc -salt -in "system_info_$host.txt" -out "system_info_$host.enc" -k "$encryption_key"
        
        # Send the encrypted file back (using SCP)
        scp -i "$ssh_key" "system_info_$host.enc" "$server"

        # Clean up temporary files
        if [ -f "system_info_$host.txt" ]; then
            rm "system_info_$host.txt"
        fi
        if [ -f "system_info_$host.enc" ]; then
            rm "system_info_$host.enc"
        fi
    else
        log "Failed to connect to $host. Check host availability and SSH configuration."
        # Continue to the next host
        continue
    fi
done
