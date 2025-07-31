#!/bin/sh

# Developed by playmax92

. /opt/telegram-bot/telegram.env
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Нет данных Telegram (TOKEN или CHAT_ID)"
    exit 1
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
OFFSET_FILE="/opt/telegram-bot/bot_offset"
[ -f "$OFFSET_FILE" ] || echo 0 > "$OFFSET_FILE"

send_msg() {
    TEXT="$1"
    curl -s -X POST "$API/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$TEXT" >/dev/null
}

get_status() {
    MODEL=$(nvram get wps_device_name)
    FW=$(nvram get webs_state_info_am)
    [ -z "$FW" ] && FW=$(nvram get firmver)
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

    UPTIME=$(uptime | sed 's/.*\([0-9]\+ days\), \([0-9]\+\):\([0-9]\+\).*/\1, \2 hours, \3 minutes/')
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
    FW=$(nvram get webs_state_info_am)
    [ -z "$FW" ] && FW=$(nvram get firmver)
    printf "📡 <b>Router</b>\n- Model: %s\n- Firmware: %s" "$MODEL" "$FW"
}

get_clients() {
    if [ -f /var/lib/misc/dnsmasq.leases ]; then
        CLIENTS=$(awk '{host=$4; if(host=="*") host="Unknown"; printf "- IP: %s | MAC: %s | Host: %s\n",$3,$2,host}' /var/lib/misc/dnsmasq.leases)
    else
        CLIENTS="Нет данных о клиентах"
    fi
    [ -z "$CLIENTS" ] && CLIENTS="Нет клиентов"
    printf "👥 <b>Clients</b>\n%s" "$CLIENTS"
}

get_log() {
    LOG=$(tail -n 20 /jffs/syslog.log 2>/dev/null)
    [ -z "$LOG" ] && LOG="Нет логов"
    printf "📜 <b>Logs</b>\n%s" "$LOG"
}

do_reboot() {
    printf "🔄 Перезагрузка..."
    reboot &
}

get_help() {
    printf "/status - Full status\n/ram - Memory\n/cpu - CPU Info\n/name - Model and Firmware\n/clients - Connected clients\n/log - Last log entries\n/reboot - Reboot router\n/help - This help"
}

while true; do
    OFFSET=$(cat "$OFFSET_FILE")
    UPDATES=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=10")
    NEW_OFFSET=$(echo "$UPDATES" | grep -o '"update_id":[0-9]*' | tail -1 | awk -F: '{print $2}')
    [ -n "$NEW_OFFSET" ] && echo $((NEW_OFFSET+1)) > "$OFFSET_FILE"

    COMMAND=$(echo "$UPDATES" | grep -o '"text":"[^"]*"' | tail -1 | cut -d: -f2 | tr -d '"')
    case "$COMMAND" in
        "/status") send_msg "$(get_status)" ;;
        "/ram") send_msg "$(get_ram)" ;;
        "/cpu") send_msg "$(get_cpu)" ;;
        "/name") send_msg "$(get_name)" ;;
        "/clients") send_msg "$(get_clients)" ;;
        "/log") send_msg "$(get_log)" ;;
        "/reboot") send_msg "$(do_reboot)" ;;
        "/help") send_msg "$(get_help)" ;;
    esac
    sleep 2
done
