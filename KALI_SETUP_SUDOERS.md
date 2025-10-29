# Setting Up Users in Kali Linux Sudoers File

## ⚠️ Important Security Note
**Always use `visudo` to edit sudoers file** - it validates syntax before saving to prevent breaking sudo access.

---

## Step 1: Create the Users (if they don't exist)

```bash
# Create attacker user
sudo useradd -m -s /bin/bash attacker
sudo passwd attacker  # Set password when prompted

# Create normaluser
sudo useradd -m -s /bin/bash normaluser
sudo passwd normaluser  # Set password when prompted
```

---

## Step 2: Edit Sudoers File Safely

```bash
# Use visudo (safest method - validates before saving)
sudo visudo
```

---

## Step 3: Add Users to Sudoers

In the `visudo` editor, scroll to the bottom and add these lines:

### Option A: Full Sudo Access (for testing)

```bash
# Allow attacker and normaluser full sudo access
attacker  ALL=(ALL:ALL) ALL
normaluser ALL=(ALL:ALL) ALL
```

### Option B: Limited Sudo Access (more secure)

For `attacker` - only allow network tools:
```bash
# Attacker can only run network attack tools
attacker  ALL=(ALL) NOPASSWD: /usr/sbin/hping3, /usr/bin/nmap, /usr/bin/nc, /usr/bin/curl
```

For `normaluser` - only allow specific commands:
```bash
# Normaluser can only run legitimate tools
normaluser ALL=(ALL) NOPASSWD: /usr/bin/curl, /usr/bin/nc, /usr/bin/ping, /usr/bin/ssh
```

### Option C: Password-less sudo (convenient for testing)

```bash
# Full sudo without password prompt
attacker  ALL=(ALL:ALL) NOPASSWD: ALL
normaluser ALL=(ALL:ALL) NOPASSWD: ALL
```

---

## Step 4: Save and Exit

1. **In `visudo` editor:**
   - If using `nano`: Press `Ctrl+O` to save, then `Ctrl+X` to exit
   - If using `vi/vim`: Press `Esc`, then type `:wq` and press Enter

2. **If syntax is valid:** File saves successfully

3. **If syntax is invalid:** `visudo` will show an error and prevent saving

---

## Step 5: Verify Users Can Use Sudo

```bash
# Switch to attacker user
su - attacker

# Test sudo access
sudo whoami
# Should output: root

# Test hping3
sudo hping3 --version
# Should show hping3 version

# Exit attacker user
exit

# Switch to normaluser
su - normaluser

# Test sudo access
sudo whoami
# Should output: root

# Test curl (should work without sudo)
curl --version

# Exit normaluser
exit
```

---

## Alternative: Add Users to Sudo Group (Simpler)

Instead of editing sudoers, you can add users to the `sudo` group:

```bash
# Add attacker to sudo group
sudo usermod -aG sudo attacker

# Add normaluser to sudo group
sudo usermod -aG sudo normaluser

# Verify
groups attacker
groups normaluser
# Should show 'sudo' in the list
```

This gives them sudo access but will prompt for their password.

---

## Recommended Setup for Testing

For your testing scenario, I recommend **Option C** (password-less sudo) because:
- Faster testing (no password prompts)
- Easier automation
- Safe in isolated VM environment

**Add to sudoers:**
```bash
attacker  ALL=(ALL:ALL) NOPASSWD: ALL
normaluser ALL=(ALL:ALL) NOPASSWD: ALL
```

---

## Security Considerations

⚠️ **For Production:**
- **DON'T** use password-less sudo
- **DON'T** give full sudo access
- Use **Option B** (limited commands only)
- Consider using specific command paths

✅ **For Testing/VM:**
- Password-less sudo is acceptable
- Full sudo access is fine for development
- Easier to automate testing

---

## Troubleshooting

### "User is not in the sudoers file"
- Double-check spelling in visudo
- Ensure you saved the file (`:wq` in vim or `Ctrl+O` then `Ctrl+X` in nano)
- Log out and log back in as the user
- Try: `sudo visudo -c` to check syntax

### "Syntax error near line X"
- Use `visudo` to edit (not regular editor)
- Check for typos
- Ensure no duplicate entries

### User can't run specific command
- Check command path: `which hping3`
- Use full path in sudoers: `/usr/sbin/hping3` not just `hping3`
- Ensure user has execute permission on the command

---

## Quick Commands Summary

```bash
# Create users
sudo useradd -m -s /bin/bash attacker
sudo useradd -m -s /bin/bash normaluser
sudo passwd attacker
sudo passwd normaluser

# Edit sudoers
sudo visudo
# Add these lines at the end:
attacker  ALL=(ALL:ALL) NOPASSWD: ALL
normaluser ALL=(ALL:ALL) NOPASSWD: ALL
# Save and exit

# Test
su - attacker
sudo whoami  # Should show: root
exit

su - normaluser
sudo whoami  # Should show: root
exit
```

---

## Next Steps

After setting up users:

1. **Login as attacker:**
   ```bash
   su - attacker
   # Now you can run: sudo hping3 ...
   ```

2. **Login as normaluser:**
   ```bash
   su - normaluser
   # Now you can run: curl, ping, etc.
   ```

3. **Install hping3** (if not installed):
   ```bash
   sudo apt update
   sudo apt install -y hping3
   ```

---

## Example Usage After Setup

```bash
# As attacker user
su - attacker
sudo hping3 -S --flood -V -p 80 192.168.1.100

# As normaluser (separate terminal)
su - normaluser
for i in {1..5}; do curl http://192.168.1.100:8000/; sleep 2; done
```

