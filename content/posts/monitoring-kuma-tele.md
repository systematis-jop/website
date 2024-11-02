+++
title = 'Monitor your homelab and get notified by Telegram!'
date = 2024-08-23T23:00:50+02:00
draft = false
author = "jop"
categories = ["Monitoring"]
tags = ["Uptime Kuma", "Telegram", "Monitoring", "Networking", "Bot", "Homelab", "Docker"]
+++


![Monitoring Setup using Kuma and Telegram Notifications](/images/uptimekumatele.jpg)

This is a detailed guide on setting up **Uptime Kuma** using **Docker** and configuring a **Telegram bot** to receive notifications when monitored URLs go down or have issues. 
   
**Setup time:** 15 minutes (assuming prerequisites are met)

---
**Uptime Kuma is an open-source monitoring tool** for tracking uptime and receiving notifications when websites, APIs, or other services go offline. Paired with a Telegram bot, you can receive **instant notifications on your phone or desktop**. I have tried multiple monitoring tools for my homelab and this one seems to be the easiest one to set up and maintain for my use case.

### Prerequisites
- A Linux instance that can run Docker
- Docker and Docker Compose (compose will make deployments with Docker very easy).
- A Telegram account to set up notifications.
  
### Step 1: Set Up Uptime Kuma in Docker

1. **Create a Directory for Uptime Kuma**
   Start by creating a dedicated directory to store Uptime Kuma’s Docker configuration and persistent data. I use my home directory.
   ```bash
   mkdir uptime-kuma && cd uptime-kuma
   ```

2. **Create a Docker Compose File** 
   Inside this directory, create a `docker-compose.yml` file. Please note: this is a very basic setup of this app. If you need more customization, I recommend browsing the official docs.
   ```yaml
   version: "3"
   services:
      uptime-kuma:
         image: louislam/uptime-kuma:1
         volumes:
            - ./data:/app/data
         ports:
            - 3001:3001
         restart: unless-stopped
   ```

3. **Start Uptime Kuma**:
   Run the Docker container:
   ```bash
   docker-compose up -d
   ```
   Or, if you’re not using Docker Compose:
   ```bash
   docker run -d --restart=always -p 3001:3001 -v $(pwd)/data:/app/data --name uptime-kuma louislam/uptime-kuma:1
   ```

4. **Access the Uptime Kuma Dashboard**:
   Open a web browser and navigate to `http://localhost:3001` (or the server IP if remote). You’ll be prompted to create an account. Complete the account setup, and you’re ready to start adding monitors.

### Step 2: Configure Monitoring in Uptime Kuma

1. **Add a Monitor**:
   - Click on the **Add New Monitor** button.
   - Choose the monitor type (HTTP(s) for URLs).
   - Enter the URL, name, and other optional parameters such as check intervals. In this example I am going to use https://systematis.ch
   - Click **Save** to start monitoring.

### Step 3: Set Up a Telegram Bot for Notifications

To receive notifications through Telegram, create a bot with **BotFather** (Telegram’s official bot management tool).

1. **Create the Telegram Bot**:
   - Open Telegram and search for **BotFather**.
   - Type `/start` to begin, then `/newbot` to create a new bot.
   - Follow BotFather's instructions:
     - Enter a name for your bot.
     - Enter a username for your bot, ending in `bot` (e.g., `MyMonitorBot`).
   - BotFather will respond with a token. Save this token for later; it’s needed to integrate with Uptime Kuma.

2. **Get Your Chat ID**:
   - Open a conversation with your new bot and send a message (any message).
   - Open your browser and navigate to:
     ```
     https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
     ```
     (Replace `<YOUR_BOT_TOKEN>` with your actual bot token from BotFather.)
   - Find the `"chat"` section in the JSON response. The `id` value in `"chat": {"id":123456789, ...}` is your chat ID. Note this down.

### Step 4: Integrate Telegram with Uptime Kuma

1. **Add a Telegram Notification in Uptime Kuma**:
   - Go back to your Uptime Kuma dashboard.
   - Navigate to **Settings > Notification**.
   - Click **Add New Notification** and choose **Telegram** as the notification type.
   
2. **Configure the Telegram Notification**:
   - **Bot Token**: Enter the token you received from BotFather.
   - **Chat ID**: Enter the chat ID you retrieved from the API response.
   - Set up other options if needed, like custom messages for specific monitors.
   - **Save** 

3. **Test the Notification**:
   - Click **Send Test** to ensure the configuration works. You should receive a test message from your bot in Telegram.

### Step 5: Customize Notification Settings in Uptime Kuma

- **Per-Monitor Notifications**: You can enable or disable Telegram notifications on a per-monitor basis by editing each monitor.
- **Custom Alerts**: Set up custom messages or specify notification intervals to avoid getting too many messages if a service is frequently up and down.

### Final Check

1. Confirm that Uptime Kuma is actively monitoring your specified URLs or services. Optional: Take down the monitored service or use a test deployment that can be taken down.
2. Verify that you receive a notification on Telegram when the service goes offline.

---

**Uptime Kuma** and Telegram together make it easy to monitor services and get real-time notifications. 
  
Enjoy your new setup, and **happy monitoring**!  