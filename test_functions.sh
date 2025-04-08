#!/bin/sh

# Set environment variable for logging
LOG_LEVEL="debug"

# Define the functions directly in this script for testing

# Log messages based on LOG_LEVEL
log() {
    level=$1
    shift
    message=$@
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "$LOG_LEVEL" = "debug" ] || { [ "$LOG_LEVEL" = "info" ] && [ "$level" != "debug" ]; }; then
        echo "$timestamp - ${level^^} - $message"
    fi
}

# Get the IP address required for login from the portal page
get_ip() {
    ip=$(curl -s --connect-timeout 3 "http://10.254.7.4/a79.htm" | iconv -f GB2312 -t UTF-8 | grep -o "v46ip='[^']*'" | cut -d"'" -f2)
    # Fallback if v46ip not found (older portal versions?)
    if [ -z "$ip" ]; then
        ip=$(curl -s --connect-timeout 3 "http://10.254.7.4/a79.htm" | iconv -f GB2312 -t UTF-8 | grep -o "v4ip='[^']*'" | cut -d"'" -f2)
    fi
    echo "$ip"
}

# Check if internet is connected by pinging a reliable DNS server
is_internet_connected() {
    # Use ping for broad compatibility, timeout after 1 second, 1 packet.
    if ping -c 1 -W 1 223.6.6.6 > /dev/null 2>&1; then
        return 0 # Success (connected)
    else
        return 1 # Failure (not connected)
    fi
}

# Get the currently logged-in account details
get_account() {
    # Fetch the main portal page and extract uid and NID
    html=$(curl -s --connect-timeout 3 "http://10.254.7.4/")
    if echo "$html" | grep -q "login_method"; then
        # If login form elements are present, likely not logged in
        echo "Not logged in"
        return
    fi
    # Extract uid and NID using sed
    uid=$(echo "$html" | sed -n "s/.*uid='\([^']*\)'.*/\1/p")
    nid=$(echo "$html" | sed -n "s/.*NID='\([^']*\)'.*/\1/p")

    if [ -n "$uid" ] || [ -n "$nid" ]; then
        echo "ID: ${uid:-'N/A'}, Name: ${nid:-'N/A'}"
    else
        # If uid/nid extraction fails but login form wasn't found, assume logged in but couldn't parse
        echo "Logged in (details unavailable)"
    fi
}

# Test each function
echo "===== Testing Helper Functions ====="

echo "\n--- Testing get_ip ---"
echo "Output from get_ip:" 
get_ip
echo "Return code: $?"

echo "\n--- Testing is_internet_connected ---"
if is_internet_connected; then
    echo "Output: Internet is connected"
else
    echo "Output: Internet is not connected"
fi
echo "Return code: $?"

echo "\n--- Testing get_account ---"
echo "Output from get_account:"
get_account
echo "Return code: $?"

echo "\n===== Testing Complete ====="
