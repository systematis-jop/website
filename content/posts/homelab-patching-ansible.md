+++
title = 'Ansible Server Patching utilizing Ansible Vault'
date = 2025-03-07T23:00:50+02:00
draft = false
author = "jop"
categories = ["Homelab","Linux","Security","Automation"]
tags = ["Ansible", "Linux", "", "Networking", "Edgerouter", "LXC", "Linux", "Mullvad"]
+++


![Ansible Server Patching utilizing Ansible Vault](/images/ansible.jpg)


This quick guide shows how to use an Ansible playbook to patch a bunch of servers. This approach still is not fully automated, as it needs user input for the execution and provision of secrets from ansible-vault.


### Prerequisites

1. **Ansible installed**: Make sure Ansible is installed on the machine that will run the playbook. If you are on MacOS like me, just use `brew install ansible`.
2. **Vault setup**: Install and configure Ansible Vault for handling sensitive data. Find a setup instructions [here.]({{< ref "/posts/ansible-vault-setup.md" >}}) 
3. **SSH access and sudo privileges**: The user running the playbook must have SSH access and sudo privileges on the target servers.

### Step 1: Setting up an inventory file with vaulted passwords

First, we need an inventory file that defines the hosts we want to patch and includes an encrypted `become` password variable. Here's a typical structure:

1. **Create inventory file** (`inventory.yaml`):
   - Define groups or specific hosts.
   - Specify variables to hold the vaulted password information.

```yaml
    [vpn]
    ansible_host: 10.10.10.10

    [vpn:vars]
    ansible_user=user
    ansible_ssh_port=22
    ansible_ssh_private_key_file=~/.ssh/id_rsa
    ansible_become_pass='{{ vpn_become_pass }}'
```

> **Note**: The vaulted strings above are placeholders. You’ll need to create your own encrypted passwords in your vault. Also, this assumes your ssh key has already been copied to the to be patched server.

### Step 2: Writing the playbook for server patching

The playbook file, `patch_servers.yaml`, will include tasks for updating packages, cleaning up, checking for a reboot, and handling SSH keys.

```yaml
---
- hosts: hostgroup
  become: true
  gather_facts: true

  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        force_apt_get: yes
        cache_valid_time: 3600

    - name: Upgrade all packages
      apt:
        upgrade: dist

    # Step 2.3: Clean Up
    - name: Remove old packages and clean cache
      apt:
        autoremove: yes
        autoclean: yes
        clean: yes

    # Step 2.4: Reboot if Required
    - name: Check if reboot is required
      register: reboot_required_file
      stat: path=/var/run/reboot-required

    - name: Reboot if kernel updated
      reboot:
        msg: "Reboot initiated by Ansible for kernel updates"
        connect_timeout: 5
        reboot_timeout: 300
        pre_reboot_delay: 0
        post_reboot_delay: 30
        test_command: uptime
      when: reboot_required_file.stat.exists
```

### Step 4: Running the Playbook with Ansible Vault

Run the playbook with the following command, referencing the vault password file:

```bash
ansible-playbook -i inventory.yaml patch_servers.yaml --ask-vault-pass -e@vaulted_vars.yml
```

### Explanation of Inventory File Configuration

- **Inventory File**:
  - `ansible_host`: Specifies the IP or hostname of the target server.
  - `ansible_user`: The SSH user to connect as.
  - `ansible_become_pass`: The `become` (sudo) password for privilege escalation, encrypted with Ansible Vault.

### Conclusion

That's it already. Obviously there is more automated ways to this, like setting up a HashiCorp Vault instance and any automation server that fetches the secrets from there and patches your machines regularly. I found this approach very useful though, so I am sharing it.