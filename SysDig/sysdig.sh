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

# Log file path
log_file="sysdig.log"

# Function to check SSH key permissions
check_ssh_key() {
    if [ ! -f "$ssh_key" ]; then
        echo "Error: SSH key file not found at '$ssh_key'."
        exit 1
    fi
    
    # Check if the SSH key file has correct permissions (600 or 400)
    local permissions=$(stat -c %a "$ssh_key")
    if [ "$permissions" != "600" ] && [ "$permissions" != "400" ]; then
        echo "Error: SSH key file '$ssh_key' should have permissions 600 or 400."
        exit 1
    fi
}

# Prompt for encryption key with validation
while true; do
    read -p "Enter encryption key: " -s encryption_key
    echo
    read -p "Confirm encryption key: " -s confirm_key
    echo

    if [ "$encryption_key" == "$confirm_key" ]; then
        break
    else
        echo "Error: Encryption keys do not match. Please try again."
    fi
done

if [ -z "$encryption_key" ]; then
    echo "Error: Encryption key cannot be empty."
    exit 1
fi

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

# Function to clean up temporary files
cleanup() {
    if [ -f "system_info_$host.txt" ]; then
        rm "system_info_$host.txt"
    fi
    if [ -f "system_info_$host.enc" ]; then
        rm "system_info_$host.enc"
    fi
}

# Set up trap to ensure cleanup on script exit
trap cleanup EXIT

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

# Function to attempt SSH connection
ssh_connect() {
    local host=$1
    local attempts=0
    
    while [ $attempts -lt 3 ]; do
        if ssh -o ConnectTimeout=10 -i "$ssh_key" "$server" "$(typeset -f gather_info search_keyword); gather_info $host"; then
            return 0
        else
            let attempts++
            sleep 5
        fi
    done
    
    return 1
}

### Main Script ###

# Check SSH key permissions
check_ssh_key

# Loop through the hosts
for host in "${hosts[@]}"
do
    echo "Connecting to $host..."

    # Try to connect via SSH and gather information
    if ssh_connect "$host"; then
        log "Connected to $host successfully."
        
        # Encrypt the file using openssl
        openssl enc -aes-256-cbc -salt -in "system_info_$host.txt" -out "system_info_$host.enc" -k "$encryption_key"
        
        # Send the encrypted file back (using SCP)
        scp -i "$ssh_key" "system_info_$host.enc" "$server"
    else
        log "Failed to connect to $host. Check host availability and SSH configuration."
        # Continue to the next host
        continue
    fi
done
