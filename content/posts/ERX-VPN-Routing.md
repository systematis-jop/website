+++
title = 'Routing Traffic Through a VPN Container'
date = 2025-03-07T23:00:50+02:00
draft = false
author = "jop"
categories = ["Homelab","Networking"]
tags = ["Wireguard", "Proxmox", "VPN", "Networking", "Edgerouter", "LXC", "Linux", "Mullvad"]
+++


![Routing Traffic Through a VPN Container on Proxmox and EdgeRouter X](/images/wgvpn-iot.jpg)


My IP was blocked from Growatt's servers recently, because I started fetching my own data from them. This didn't make sense to me, but anyways. I can't change my public IP and it's only rotated every once in a while.
This meant I had to be creative.

In this post, we’ll walk through setting up a Proxmox Linux container (CT) to run WireGuard with a Mullvad configuration and then configuring an EdgeRouter X to force specific devices’ traffic through that VPN container. In my example, the IoT host has a static IP of **10.10.10.71**. We use firewall‑based policy-based routing (PBR) on the EdgeRouter to achieve this.

> **Prerequisites:**  
> - A Proxmox server  
> - A working EdgeRouter X running EdgeOS v2.x (just my version, might work with others too) 
> - A Linux CT on that Proxmox host (I was running Ubuntu)
> - A Mullvad subscription (for WireGuard configs)

---

## Step 1: Create and Prepare the Proxmox Linux CT

1. **Create a New CT**  
   Use the Proxmox web interface to create a new container. In our case, we’re using an Ubuntu 22.02 image. Ensure the container is assigned a static IP on your LAN.

2. **Get Shell Access**  
   Once the CT is created, open the console or SSH into it.

3. **Update the System and Install WireGuard**  
   Update your package list and install WireGuard along with DNS tools:
   ```bash
   apt update
   apt install wireguard wireguard-tools resolvconf -y
   ```

4. **Download and Install Your Mullvad Configuration**  
   Log in to your Mullvad account and add a device. Mullvad will provide you with an archive of valid WireGuard configs. Extract and place your chosen config at:
   ```
   /etc/wireguard/wg0.conf
   ```

5. **Start the WireGuard Interface**  
   Bring up the WireGuard interface with:
   ```bash
   wg-quick up wg0
   ```
   Then, confirm it’s active by checking your public IP:
   ```bash
   curl ifconfig.me
   ```
   The returned IP should match your chosen Mullvad VPN server’s exit IP.

6. **Enable IP Forwarding**  
   To allow the CT to forward traffic (necessary for VPN gateway functionality), enable IP forwarding:
   ```bash
   echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
   sysctl -p
   ```

7. **Set Up NAT Masquerading**  
   Configure iptables to masquerade outbound traffic on the WireGuard interface:
   ```bash
   iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
   ```

8. **Add a Policy Routing Rule for Forwarded Traffic**  
   You can add an IP rule on the CT so that traffic from a specific host (my client at **10.10.10.71**) uses an alternate routing table. For example:
   ```bash
   ip rule add from 10.10.10.71/32 table 100
   ```
   (Later, you can configure table 100 with a default route via wg0 if you want to affect only forwarded traffic.)

---

## Step 2: Configure the EdgeRouter X for VPN Routing

I wanted the EdgeRouter to send all traffic from a specific IoT device (**10.10.10.71**) to our VPN container at **10.10.10.70**.

1. **Enter Configuration Mode on the EdgeRouter:**
   ```shell
   configure
   ```

2. **Add Firewall Modify PBR Rules**  
   Create a rule that matches the client’s IP and directs its traffic to an alternate routing table. For our example, we’re using table **100** (which must have a default route pointing to 10.10.10.70). For host **10.10.10.71**, run:
   ```shell
   set firewall modify PBR rule 10 description "Route IoT 10.10.10.71 via VPN"
   set firewall modify PBR rule 10 source address 10.10.10.71/32
   set firewall modify PBR rule 10 modify table 100
   ```
   *(You can replicate similar rules for additional IP addresses by using different rule numbers.)*

3. **Commit and Save the Changes:**
   ```shell
   commit
   save
   ```

4. **Apply the PBR Rules to the LAN Interface**  
   Attach the modify group (named **PBR**) to the inbound direction of your LAN interface. For example, if your LAN is on the **eth1** interface:
   ```shell
   configure
   set interfaces eth1 firewall in modify PBR
   commit
   save
   exit
   ```
   This ensures that traffic arriving on the LAN interface matching our PBR rule (source 10.10.10.71) is routed according to table 100.

---

## Step 3: Verification and Testing

**Test the VPN Functionality:**  
   Inside the CT and on the other client as well, run:
   ```bash
   curl ifconfig.me
   ```
   Confirm that it shows your Mullvad server’s exit IP.

## Conclusion

Pretty easy, wasn't it? If you encounter any problems, please check again if you have replaced all IP addresses with your own.
