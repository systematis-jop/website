+++
title = 'Ansible Vault for Secure Credential Management!'
date = 2024-11-04T22:00:50+02:00
draft = false
author = "jop"
categories = ["Automation"]
tags = ["Ansible", "Security", "Automation", "Homelab"]
+++


![Ansible Vault](/images/ansible-vault.jpg)
---

While writing the blog post about homelab server patching with Ansible, I figured there is a need for setup instructions of ansible-vault. So, here's a quick guide on setting up and using Ansible Vault to secure sensitive data, like `become` passwords, for use in playbooks.
Obviously, Ansible needs to be installed for this.


### Step 1: Create a vault password file

To streamline running the playbook without being prompted for a vault password every time:

1. **Create a vault password file**:
```bash
ansible-vault create vaulted_vars.yaml
```

2. **Put in your environment variables**:

First, open up the vault file:
```bash
ansible-vault edit vaulted_vars.yaml
```
Then, add your secrets:
```yaml
host_become_pass: password
```
### Step 2: Reference the variable in the inventory file:
```yaml
[hostgroup]
host1 ansible_host=10.10.10.10
host2 ansible_host=10.10.10.11

[hostgroup:vars]
ansible_become_pass='{{ hostgroup_become_pass }}'
```

### Step 3: Use the vault password file when running playbooks

Run your Ansible playbook, referencing the vault password file with the `--vault-password-file` option:

```bash
ansible-playbook -i inventory.yaml -l host1 playbook.yaml --ask-vault-pass -e@vaulted_vars.yaml
```
---

This setup ensures your sensitive credentials, like `become` passwords, remain encrypted and secure when using Ansible.