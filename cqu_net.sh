#!/bin/sh

# --- Configuration ---
# Read from environment variables or set defaults
ACCOUNT=${ACCOUNT:-""}
PASSWORD=${PASSWORD:-""}
TERM_TYPE=${TERM_TYPE:-"pc"} # 'pc' or 'android'
LOG_LEVEL=${LOG_LEVEL:-"info"} # 'info' or 'debug'
INTERVAL=${INTERVAL:-5} # Check interval in seconds

# --- Helper Functions ---

# Log messages based on LOG_LEVEL
log() {
    level=$1
    shift
    message=$@
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [ "$LOG_LEVEL" = "debug" ] || { [ "$LOG_LEVEL" = "info" ] && [ "$level" != "debug" ]; }; then
        echo "$timestamp - $(echo $level | tr '[:lower:]' '[:upper:]') - $message"
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
    # Adjust ping command based on OS if needed. This works for macOS/Linux.
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

# Perform the login action
login() {
    local account=$1
    local password=$2
    local term_type=$3
    local ip=$4
    local callback="dr1004" # Default callback for PC
    local user_account_prefix="%2C0%2C" # Default prefix for PC
    local ua="Mozilla%2F5.0%20(Windows%20NT%2010.0%3B%20Win64%3B%20x64)%20AppleWebKit%2F537.36%20(KHTML%2C%20like%20Gecko)%20Chrome%2F134.0.0.0%20Safari%2F537.36%20Edg%2F134.0.0.0"
    local term_type_code="1" # Default type code for PC
    local v_param="9875" # Default v parameter for PC

    if [ "$term_type" = "android" ]; then
        callback="dr1005"
        user_account_prefix="%2C1%2C"
        ua="Mozilla%2F5.0%20(Linux%3B%20Android%208.0.0%3B%20SM-G955U%20Build%2FR16NW)%20AppleWebKit%2F537.36%20(KHTML%2C%20like%20Gecko)%20Chrome%2F134.0.0.0%20Mobile%20Safari%2F537.36%20Edg%2F134.0.0.0"
        term_type_code="2"
        v_param="9451"
    fi

    login_url="http://10.254.7.4:801/eportal/portal/login?callback=${callback}&login_method=1&user_account=${user_account_prefix}${account}&user_password=${password}&wlan_user_ip=${ip}&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&ua=${ua}&term_type=${term_type_code}&jsVersion=4.2&terminal_type=${term_type_code}&lang=zh-cn&v=${v_param}&lang=zh"

    log debug "Login URL: $login_url"

    # Send login request and capture response
    response=$(curl -s --connect-timeout 5 "$login_url" \
        -H 'Accept: */*' \
        -H 'Accept-Language: zh-CN,zh;q=0.9' \
        -H 'Connection: keep-alive' \
        -H 'Referer: http://10.254.7.4/' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
        --insecure)

    log debug "Login response: $response"

    # Extract result and message using sed
    # 1. Remove dr100x(...) wrapper -> {"result":X,"msg":"..."}
    # 2. Extract "result":X -> X
    # 3. Extract "msg":"..." -> ...
    json_part=$(echo "$response" | sed -n 's/^dr[0-9]*(\(.*\));$/\1/p')
    result=$(echo "$json_part" | sed -n 's/.*"result":\([0-9]*\).*/\1/p')
    msg=$(echo "$json_part" | sed -n 's/.*"msg":"\([^"]*\)".*/\1/p')

    # Check if parsing failed
    if [ -z "$result" ] || [ -z "$msg" ]; then
        log warning "Failed to parse login response: $response"
        echo "0,Unknown error parsing response" # Return failure, unknown message
        return
    fi

    echo "$result,$msg" # Return result and message comma-separated
}

# --- Main Logic ---

# Check required variables
if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ]; then
    log error "ACCOUNT or PASSWORD environment variables not set."
    exit 1
fi

# Trap SIGINT and SIGTERM to allow graceful exit
trap 'log info "Exiting script."; exit 0' INT TERM

log info "Starting CQU Net Helper..."
log info "Account: $ACCOUNT, Term Type: $TERM_TYPE, Check Interval: ${INTERVAL}s, Log Level: $LOG_LEVEL"
log info "Press CTRL+C to stop."

while true; do
    log debug "Checking internet connection..."
    if is_internet_connected; then
        account_info=$(get_account)
        log info "Network connected. Current Status: $account_info. Checking again in ${INTERVAL}s."
        sleep $INTERVAL
        continue
    fi

    log info "Network disconnected. Attempting to log in..."

    # Get IP for login
    log debug "Fetching IP address..."
    ip=$(get_ip)
    if [ -z "$ip" ]; then
        log warning "Failed to get IP address from portal. Retrying in ${INTERVAL}s."
        sleep $INTERVAL
        continue
    fi
    log debug "Got IP: $ip"

    # Attempt login
    log info "Attempting login for account '$ACCOUNT' (IP: $ip, Type: $TERM_TYPE)..."
    login_output=$(login "$ACCOUNT" "$PASSWORD" "$TERM_TYPE" "$ip")

    # Parse login result (comma-separated)
    result=$(echo "$login_output" | cut -d',' -f1)
    msg=$(echo "$login_output" | cut -d',' -f2-) # Get the rest of the string after the first comma

    # Check login result
    if [ "$result" = "1" ]; then
        log info "Login successful: $msg"
        # Optionally verify connection again immediately
        sleep 1 # Short pause before checking status again
        account_info=$(get_account)
        log info "Current Status: $account_info. Checking again in ${INTERVAL}s."
    else
        log warning "Login failed: $msg"
        # Check for fatal errors
        if echo "$msg" | grep -q -e "账号不存在" -e "密码错误"; then
            log error "Fatal error: $msg. Exiting."
            exit 1
        fi
        log info "Retrying in ${INTERVAL}s."
    fi

    sleep $INTERVAL
done