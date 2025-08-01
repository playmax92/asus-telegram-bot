#!/bin/sh

# Developed by playmax92

. /opt/telegram-bot/telegram.env
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "No Telegram data (TOKEN or CHAT_ID)"
    exit 1
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
OFFSET_FILE="/opt/telegram-bot/bot_offset"
[ -f "$OFFSET_FILE" ] || echo 0 > "$OFFSET_FILE"

WAN_IP_FILE="/opt/telegram-bot/wan_ip_last"
[ -f "$WAN_IP_FILE" ] || echo "" > "$WAN_IP_FILE"

send_msg() {
    TEXT="$1"
    curl -s -X POST "$API/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        -d text="$TEXT" >/dev/null
}

check_wan_ip_change() {
    CURRENT_IP=$(nvram get wan0_ipaddr)
    LAST_IP=$(cat "$WAN_IP_FILE")
    if [ "$CURRENT_IP" != "$LAST_IP" ] && [ -n "$CURRENT_IP" ]; then
        echo "$CURRENT_IP" > "$WAN_IP_FILE"
        send_msg "🌐 <b>WAN IP changed</b>\nOld: $LAST_IP\nNew: $CURRENT_IP"
    fi
}

get_status() {
    MODEL=$(nvram get wps_device_name)
    FW_MAIN=$(nvram get firmver)
    FW_BUILD=$(nvram get buildno)
    FW="${FW_MAIN}.${FW_BUILD}"
    WAN_IP=$(nvram get wan0_ipaddr)
    LAN_IP=$(nvram get lan_ipaddr)
    SSID_24=$(nvram get wl0_ssid)
    SSID_5=$(nvram get wl1_ssid)
    IF24=$(nvram get wl0_ifname)
    IF5=$(nvram get wl1_ifname)

    TEMP_CPU_VAL=$(cat /sys/class/thermal/thermal_zone0/temp | awk '{print int($1/1000)}')
    TEMP_CPU="${TEMP_CPU_VAL}º"
    TEMP_WIFI24=$(wl -i $IF24 phy_tempsense 2>/dev/null | awk '{print $1/2+20"º"}')
    TEMP_WIFI5=$(wl -i $IF5 phy_tempsense 2>/dev/null | awk '{print $1/2+20"º"}')

    if [ "$TEMP_CPU_VAL" -gt 60 ]; then
        BANNER="🔥 $MODEL | CPU: $TEMP_CPU 🔥"
    else
        BANNER="❄️ $MODEL | CPU: $TEMP_CPU ❄️"
    fi

    UPTIME_SECONDS=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
    DAYS=$((UPTIME_SECONDS/86400))
    HOURS=$(( (UPTIME_SECONDS%86400)/3600 ))
    MINUTES=$(( (UPTIME_SECONDS%3600)/60 ))
    if [ "$DAYS" -gt 0 ]; then
        UPTIME="${DAYS}d ${HOURS}h ${MINUTES}m"
    else
        UPTIME="${HOURS}h ${MINUTES}m"
    fi

    CPU_LOAD=$(cut -d " " -f1-3 /proc/loadavg)
    RAM_USED_PERCENTAGE=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')
    RAM_FREE_PERCENTAGE=$(free | awk '/Mem:/ {printf "%.2f", $4/$2*100}')
    SWAP_USED=$(free | awk '/Swap:/ {if ($2==0) print "0.00"; else printf "%.2f", $3/$2*100}')
    SIGN_DATE=$(nvram get bwdpi_sig_ver)

    printf "<b>%s</b>\n\n📊 <b>Status</b>\n- CPU Temp: %s\n- WLAN 2.4 Temp: %s\n- WLAN 5 Temp: %s\n- Uptime: %s\n- Load CPU: %s\n- RAM Used: %s%% / Free: %s%%\n- Swap Used: %s%%\n\n📃 <b>Info</b>\n- Model: %s\n- Firmware: %s\n- SSID 2.4GHz: %s\n- SSID 5GHz: %s\n- IP WAN: %s\n- IP LAN: %s\n- Trend Micro sign: %s" \
        "$BANNER" "$TEMP_CPU" "$TEMP_WIFI24" "$TEMP_WIFI5" "$UPTIME" "$CPU_LOAD" "$RAM_USED_PERCENTAGE" "$RAM_FREE_PERCENTAGE" "$SWAP_USED" "$MODEL" "$FW" "$SSID_24" "$SSID_5" "$WAN_IP" "$LAN_IP" "$SIGN_DATE"
}

get_ram() {
    RAM_USED=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')
    RAM_FREE=$(free | awk '/Mem:/ {printf "%.2f", $4/$2*100}')
    SWAP_USED=$(free | awk '/Swap:/ {if ($2==0) print "0.00"; else printf "%.2f", $3/$2*100}')
    printf "🧠 <b>RAM</b>\n- Used: %s%%\n- Free: %s%%\n- Swap Used: %s%%" "$RAM_USED" "$RAM_FREE" "$SWAP_USED"
}

get_cpu() {
    TEMP_CPU_VAL=$(cat /sys/class/thermal/thermal_zone0/temp | awk '{print int($1/1000)}')
    TEMP_CPU="${TEMP_CPU_VAL}º"
    LOAD=$(cut -d " " -f1-3 /proc/loadavg)
    printf "🖥 <b>CPU</b>\n- Load: %s\n- Temp: %s" "$LOAD" "$TEMP_CPU"
}

get_name() {
    MODEL=$(nvram get wps_device_name)
    FW_MAIN=$(nvram get firmver)
    FW_BUILD=$(nvram get buildno)
    FW="${FW_MAIN}.${FW_BUILD}"
    printf "📡 <b>Router</b>\n- Model: %s\n- Firmware: %s" "$MODEL" "$FW"
}

get_clients() {
    IF24=$(nvram get wl0_ifname)
    IF5=$(nvram get wl1_ifname)

    MAC_24=$(wl -i $IF24 assoclist | awk '{print $2}')
    WIFI24_LIST=""
    for mac in $MAC_24; do
        HOST=$(grep -i "$mac" /var/lib/misc/dnsmasq.leases | awk '{print $4}')
        [ "$HOST" = "*" ] && HOST="Unknown"
        IP=$(grep -i "$mac" /var/lib/misc/dnsmasq.leases | awk '{print $3}')
        WIFI24_LIST="${WIFI24_LIST}- IP: $IP | MAC: $mac | Host: $HOST
"
    done

    MAC_5=$(wl -i $IF5 assoclist | awk '{print $2}')
    WIFI5_LIST=""
    for mac in $MAC_5; do
        HOST=$(grep -i "$mac" /var/lib/misc/dnsmasq.leases | awk '{print $4}')
        [ "$HOST" = "*" ] && HOST="Unknown"
        IP=$(grep -i "$mac" /var/lib/misc/dnsmasq.leases | awk '{print $3}')
        WIFI5_LIST="${WIFI5_LIST}- IP: $IP | MAC: $mac | Host: $HOST
"
    done

    LAN_LIST=""
    for mac in $(awk '/0x2/ {print $4}' /proc/net/arp | grep -v "00:00:00:00:00:00"); do
        if ! echo "$MAC_24 $MAC_5" | grep -qi "$mac"; then
            IP=$(awk -v m="$mac" '$4 == m {print $1}' /proc/net/arp)
            if ping -c1 -W1 "$IP" >/dev/null 2>&1; then
                HOST=$(grep -i "$mac" /var/lib/misc/dnsmasq.leases | awk '{print $4}')
                [ "$HOST" = "*" ] && HOST="Unknown"
                LAN_LIST="${LAN_LIST}- IP: $IP | MAC: $mac | Host: $HOST
"
            fi
        fi
    done

    if [ -n "$LAN_LIST" ]; then
        printf "👥 <b>Clients</b>\n\n<b>Wi-Fi 2.4 GHz:</b>\n%s\n<b>Wi-Fi 5 GHz:</b>\n%s\n<b>LAN:</b>\n%s" \
            "$WIFI24_LIST" "$WIFI5_LIST" "$LAN_LIST"
    else
        printf "👥 <b>Clients</b>\n\n<b>Wi-Fi 2.4 GHz:</b>\n%s\n<b>Wi-Fi 5 GHz:</b>\n%s" \
            "$WIFI24_LIST" "$WIFI5_LIST"
    fi
}

get_log() {
    LOG=$(tail -n 20 /tmp/syslog.log 2>/dev/null)
    [ -z "$LOG" ] && LOG="No logs available"
    printf "📜 <b>Logs</b>\n%s" "$LOG"
}

do_reboot() {
    send_msg "🔄 Router is going to reboot now..."
    reboot &
}

get_help() {
    printf "/start - Welcome message\n/status - Full status\n/ram - Memory\n/cpu - CPU Info\n/name - Model and Firmware\n/clients - Connected clients\n/log - Last log entries\n/reboot - Reboot router\n/help - This help"
}

while true; do
    check_wan_ip_change
    OFFSET=$(cat "$OFFSET_FILE")
    UPDATES=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=10")
    NEW_OFFSET=$(echo "$UPDATES" | grep -o '"update_id":[0-9]*' | tail -1 | awk -F: '{print $2}')
    [ -n "$NEW_OFFSET" ] && echo $((NEW_OFFSET+1)) > "$OFFSET_FILE"
    COMMAND=$(echo "$UPDATES" | grep -o '"text":"[^"]*"' | tail -1 | cut -d: -f2 | tr -d '"')
    case "$COMMAND" in
        "/start") send_msg "🤖 Router bot started and ready.
Use /help to see available commands." ;;
        "/status") send_msg "$(get_status)" ;;
        "/ram") send_msg "$(get_ram)" ;;
        "/cpu") send_msg "$(get_cpu)" ;;
        "/name") send_msg "$(get_name)" ;;
        "/clients") send_msg "$(get_clients)" ;;
        "/log") send_msg "$(get_log)" ;;
        "/reboot") do_reboot ;;
        "/help") send_msg "$(get_help)" ;;
    esac
    sleep 2
done
