<a href="https://www.paypal.com/donate/?hosted_button_id=KCZZMSQ67CACG" target="_blank">
<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate" style="height: 30px !important;" align="right" /></a><br/>

# Telegram Bot for ASUS Routers (FreshTomato)

<img src="https://github.com/playmax92/asus-telegram-bot/blob/0cf98a1d3b3654829f898a415b3a070cbbff7262/AX3000_V2.png" style="height: 1000px" /></a>

A lightweight shell-based Telegram bot to monitor your ASUS router running FreshTomato firmware.

---

## ✅ Tested Devices

| Router              | Firmware           |
|---------------------|--------------------|
| ASUS TUF AX3000 V2  | FreshTomato 3.0.0.4.2025_3 |

---

## ✅ Requirements

- ASUS router with [FreshTomato firmware](https://freshtomato.org/)  
- USB drive (min. **4 GB** recommended) formatted as **Ext4** with **swap enabled**
- SSH access to the router
- `curl` utility (built-in)

---

## 🛠️ Installation

### 1. Prepare the USB Drive

Partition and format the USB Drive (e.g. using AOMEI Partition Assistant or Linux `gparted`):

| Partition | Size     | Mount Point   | Format |
|-----------|----------|----------------|--------|
| `sda1`    | 1 GB     | `/opt`         | ext4   |
| `sda2`    | 1 GB     | swap           | swap   |
| `sda3`    | rest     | `/home/ftp`    | ext4   |

### 2. Enable JFFS and SSH

Via web UI:
- Go to **Administration → System**
- Enable **Enable JFFS custom scripts** → `Yes`
- Enable **Enable SSH** → `LAN only` or `LAN & WAN`

### 3. Create post-mount Script

Create the script `/jffs/scripts/post-mount`:
```sh
#!/bin/sh
# Mount USB partitions
mkdir -p /opt
mkdir -p /home/ftp
mount /tmp/mnt/sda1 /opt
mount /tmp/mnt/sda3 /home/ftp
swapon /dev/sda2

# Start Telegram Bot
/opt/telegram-bot/bot.sh &
```

Convert possible Windows line endings:
```sh
sed -i 's/\r$//' /jffs/scripts/post-mount
```

Make it executable:
```sh
chmod +x /jffs/scripts/post-mount
```

### 4. Deploy the Bot

Create the bot folder:
```sh
mkdir -p /opt/telegram-bot
```

Add these two files to `/opt/telegram-bot/`: `bot.sh` and `telegram.env`

Don't forget to put your credentials in the file `telegram.env`

```env
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=123456789
```

Convert possible Windows line endings:
```sh
sed -i 's/\r$//' /opt/telegram-bot/bot.sh
sed -i 's/\r$//' /opt/telegram-bot/telegram.env
```

Set permissions:
```sh
chmod +x /opt/telegram-bot/bot.sh
chmod 600 /opt/telegram-bot/telegram.env
```

---

## 🔁 Auto-start on Boot

When the USB is mounted, `post-mount` will automatically run and launch the bot in the background.  
No additional startup scripts are required.

---

## 📜 Telegram Commands

| Command      | Description              |
|--------------|--------------------------|
| `/status`    | Full router status       |
| `/ram`       | Memory usage             |
| `/cpu`       | CPU load and temp        |
| `/name`      | Router model/firmware    |
| `/clients`   | Connected clients (DHCP) |
| `/log`       | View recent log          |
| `/reboot`    | Reboot router            |
| `/help`      | Show command list        |

---


## 📝 License

Distributed under the MIT License. See [LICENSE](https://raw.githubusercontent.com/playmax92/asus-telegram-bot/refs/heads/main/LICENSE?token=GHSAT0AAAAAADICBVU2DJUXZZ44H3QEY5OC2ELPQFA) file for details.
