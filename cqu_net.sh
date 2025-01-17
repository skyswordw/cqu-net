#!/bin/sh

# 设置默认值
CHECK_INTERVAL=${CHECK_INTERVAL:-60}

while true; do
    if ! ping -c 1 www.baidu.com > /dev/null 2>&1; then
        echo "网络断开，尝试重新登录..."
        curl "http://10.254.7.4:801/eportal/portal/login?callback=dr1004&login_method=1&user_account=%2C0%2C${USER_ACCOUNT}&user_password=${USER_PASSWORD}&wlan_user_ip=${USER_IP}&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.2&terminal_type=1&lang=zh-cn&v=2190&lang=zh" \
            -H 'Accept: */*' \
            -H 'Accept-Language: zh-CN,zh;q=0.9' \
            -H 'Connection: keep-alive' \
            -H 'Referer: http://10.254.7.4/' \
            -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
            --insecure
        echo "登录请求已发送"
    else
        echo "网络连接正常"
    fi
    sleep $CHECK_INTERVAL
done 