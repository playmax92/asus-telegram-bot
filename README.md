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

Create the script file:
```sh
touch /jffs/scripts/post-mount
```
Copy the script in`/jffs/scripts/post-mount`:

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

Or a command in the terminal for copying.

```sh
cat > /jffs/scripts/post-mount <<'EOF'
#!/bin/sh
# Mount USB partitions
mkdir -p /opt
mkdir -p /home/ftp
mount /tmp/mnt/sda1 /opt
mount /tmp/mnt/sda3 /home/ftp
swapon /dev/sda2

# Start Telegram Bot
/opt/telegram-bot/bot.sh &
EOF
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

Add these two files `bot.sh` and `telegram.env` to `/opt/telegram-bot/`:

Go to bot directory
```sh
cd /tmp/mnt/sdb1/telegram-bot
```

Download bot.sh
```sh
wget https://raw.githubusercontent.com/playmax92/asus-telegram-bot/refs/heads/main/bot.sh -O bot.sh
```

Download telegram.env
```sh
wget https://raw.githubusercontent.com/playmax92/asus-telegram-bot/refs/heads/main/telegram.env -O telegram.env
```

Don't forget to put your credentials in the file `telegram.env`

Convert possible Windows line endings:
```sh
sed -i 's/\r$//' /opt/telegram-bot/bot.sh
```
```sh
sed -i 's/\r$//' /opt/telegram-bot/telegram.env
```

Set permissions:
```sh
chmod +x /opt/telegram-bot/bot.sh
```
```sh
chmod 600 /opt/telegram-bot/telegram.env
```

---

### Editing the `telegram.env` file

After downloading the file, you need to insert your bot credentials:
```env
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=123456789
```

On the router, the only available text editor is **vi**.  
To edit the file:
```bash
vi /opt/telegram-bot/telegram.env
```

**Basic vi commands:**
- Press `i` to enter **INSERT** mode
- Insert or modify the content:
  ```env
  TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN
  TELEGRAM_CHAT_ID=YOUR_CHAT_ID
  ```
- Press `Esc` to exit **INSERT** mode
- Type `:wq` and press **Enter** to **save changes and quit**
- To **exit without saving changes**:
  - Press `Esc`
  - Type `:q!` and press **Enter**

Convert possible Windows line endings:
```bash
cat /opt/telegram-bot/telegram.env
```

Set permissions:
```sh
chmod 600 /opt/telegram-bot/telegram.env
```

---

## ✅ Auto-start on Boot

When the USB is mounted, `post-mount` will automatically run and launch the bot in the background.  
No additional startup scripts are required.

---

## 🔁 Restarting the Bot

Sometimes you may need to restart the bot to apply updates or test changes.  
Here are the commands you can use:

1. Stop all running bot processes
```bash
ps | grep "[b]ot.sh" | awk '{print $1}' | xargs kill -9
```

2. Start the bot in the background
```bash
nohup sh bot.sh >/tmp/mnt/sdb1/telegram-bot/bot.log 2>&1 &
```

3. Verify that the bot is running
```bash
ps | grep bot.sh
```
---

## Note:
When you start the bot manually via SSH, it will only run while your SSH session is open. After closing the terminal, the bot stops.

However, thanks to the /jffs/scripts/post-mount script, the bot will start automatically every time the router is rebooted.

## 📜 Telegram Commands

<img src="https://github.com/playmax92/asus-telegram-bot/blob/b0bad29f20ec6fc509f173f4dc81743eabfe7f9a/Telegram_Output.jpg" style="height: 1000px" /></a>

| Command      | Description                                 |
|--------------|---------------------------------------------|
| `/start`     | Welcome message                             |
| `/status`    | Full router status                          |
| `/ram`       | Memory usage (RAM and Swap)                 |
| `/cpu`       | CPU load and temp                           |
| `/name`      | Router model and firmware                   |
| `/clients`   | Connected clients (WiFi and LAN separated)  |
| `/log`       | View recent log  (10 latest messages)       |
| `/reboot`    | Reboot router                               |
| `/help`      | Show command list                           |

---


## 📝 License

Distributed under the MIT License. See [LICENSE](https://github.com/playmax92/asus-telegram-bot/blob/main/LICENSE) file for details.
