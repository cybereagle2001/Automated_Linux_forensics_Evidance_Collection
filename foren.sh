#!/bin/bash

# ==============================================================================
# Linux Live Response Triage Collection Script
# Purpose: Collect volatile data, system state, and key logs for anomaly detection.
# WARNING: Running this script alters the system state (creates files, updates atimes).
# ==============================================================================

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script as root (sudo)."
  exit 1
fi

# Define collection directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HOSTNAME=$(hostname)
COLLECT_DIR="/tmp/forensic_triage_${HOSTNAME}_${TIMESTAMP}"

echo "[*] Starting forensic triage collection..."
echo "[*] Target Directory: $COLLECT_DIR"

# Create base directory
mkdir -p "$COLLECT_DIR"
mkdir -p "$COLLECT_DIR/volatile"
mkdir -p "$COLLECT_DIR/system_info"
mkdir -p "$COLLECT_DIR/logs"
mkdir -p "$COLLECT_DIR/user_activity"

# ==============================================================================
# 1. VOLATILE DATA (Highest Priority - RFC 3227)
# ==============================================================================
echo "[*] Collecting volatile data..."

# Running processes (full command lines)
ps auxfww > "$COLLECT_DIR/volatile/ps_auxfww.txt" 2>/dev/null

# Network connections and listening ports
ss -tulpn > "$COLLECT_DIR/volatile/ss_tulpn.txt" 2>/dev/null
netstat -tulpn > "$COLLECT_DIR/volatile/netstat_tulpn.txt" 2>/dev/null

# Established connections
ss -tnp > "$COLLECT_DIR/volatile/ss_established.txt" 2>/dev/null

# Open files and sockets (can be large, but highly valuable)
lsof -n -P > "$COLLECT_DIR/volatile/lsof.txt" 2>/dev/null

# Current logged-in users and what they are doing
w > "$COLLECT_DIR/volatile/w_output.txt" 2>/dev/null
who -a > "$COLLECT_DIR/volatile/who_a.txt" 2>/dev/null

# Kernel ring buffer (dmesg)
dmesg -T > "$COLLECT_DIR/volatile/dmesg.txt" 2>/dev/null

# ==============================================================================
# 2. SYSTEM INFORMATION & CONFIGURATION
# ==============================================================================
echo "[*] Collecting system information..."

uname -a > "$COLLECT_DIR/system_info/uname_a.txt" 2>/dev/null
date > "$COLLECT_DIR/system_info/date.txt" 2>/dev/null
uptime > "$COLLECT_DIR/system_info/uptime.txt" 2>/dev/null
df -h > "$COLLECT_DIR/system_info/df_h.txt" 2>/dev/null
mount > "$COLLECT_DIR/system_info/mount.txt" 2>/dev/null
cat /etc/passwd > "$COLLECT_DIR/system_info/passwd.txt" 2>/dev/null
cat /etc/shadow > "$COLLECT_DIR/system_info/shadow.txt" 2>/dev/null # Requires root
cat /etc/group > "$COLLECT_DIR/system_info/group.txt" 2>/dev/null
cat /etc/hosts > "$COLLECT_DIR/system_info/hosts.txt" 2>/dev/null
cat /etc/crontab > "$COLLECT_DIR/system_info/crontab.txt" 2>/dev/null
ls -la /etc/cron.* > "$COLLECT_DIR/system_info/cron_dirs.txt" 2>/dev/null

# Check for suspicious SUID/SGID binaries (common persistence mechanism)
find / -perm -4000 -type f 2>/dev/null > "$COLLECT_DIR/system_info/suid_bins.txt"
find / -perm -2000 -type f 2>/dev/null > "$COLLECT_DIR/system_info/sgid_bins.txt"

# ==============================================================================
# 3. USER ACTIVITY & HISTORY
# ==============================================================================
echo "[*] Collecting user activity..."

# Bash history for root and common users
for user_dir in /root /home/*; do
    if [ -d "$user_dir" ]; then
        user=$(basename "$user_dir")
        cat "$user_dir/.bash_history" > "$COLLECT_DIR/user_activity/${user}_bash_history.txt" 2>/dev/null
        cat "$user_dir/.ssh/authorized_keys" > "$COLLECT_DIR/user_activity/${user}_ssh_authorized_keys.txt" 2>/dev/null
        cat "$user_dir/.ssh/known_hosts" > "$COLLECT_DIR/user_activity/${user}_ssh_known_hosts.txt" 2>/dev/null
    fi
done

# Login history
last > "$COLLECT_DIR/user_activity/last_logins.txt" 2>/dev/null
lastb > "$COLLECT_DIR/user_activity/lastb_failed_logins.txt" 2>/dev/null

# ==============================================================================
# 4. APPLICATION & SERVICE LOGS
# ==============================================================================
echo "[*] Collecting key logs..."

# Authentication logs (Handles both Debian/Ubuntu and RHEL/CentOS)
cp /var/log/auth.log "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/secure "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/syslog "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/messages "$COLLECT_DIR/logs/" 2>/dev/null

# SSH Daemon logs (if separate)
cp /var/log/secure "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/auth.log "$COLLECT_DIR/logs/" 2>/dev/null

# FTP Logs (vsftpd, proftpd)
cp /var/log/vsftpd.log "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/proftpd/* "$COLLECT_DIR/logs/" 2>/dev/null
cp /var/log/xferlog "$COLLECT_DIR/logs/" 2>/dev/null

# Web Server Logs (Apache/Nginx)
cp -r /var/log/apache2/ "$COLLECT_DIR/logs/" 2>/dev/null
cp -r /var/log/httpd/ "$COLLECT_DIR/logs/" 2>/dev/null
cp -r /var/log/nginx/ "$COLLECT_DIR/logs/" 2>/dev/null

# Sudo usage
cp /var/log/sudo.log "$COLLECT_DIR/logs/" 2>/dev/null
grep sudo /var/log/auth.log > "$COLLECT_DIR/logs/sudo_auth_extract.txt" 2>/dev/null

# ==============================================================================
# 5. PACKAGING AND INTEGRITY
# ==============================================================================
echo "[*] Packaging and hashing collection..."

# Create a tarball of the collection
TARBALL_NAME="forensic_triage_${HOSTNAME}_${TIMESTAMP}.tar.gz"
tar -czf "/tmp/$TARBALL_NAME" -C "/tmp" "$(basename "$COLLECT_DIR")"

# Generate SHA-256 hash of the tarball for chain of custody
sha256sum "/tmp/$TARBALL_NAME" > "/tmp/${TARBALL_NAME}.sha256"

# Clean up the raw directory to save space (optional, comment out if you want to keep both)
rm -rf "$COLLECT_DIR"

echo "[+] Collection complete!"
echo "[+] Archive Location: /tmp/$TARBALL_NAME"
echo "[+] Hash File: /tmp/${TARBALL_NAME}.sha256"
echo "[!] NEXT STEP: Securely transfer this archive to your forensic workstation immediately."
echo "[!] Verify the hash after transfer: sha256sum -c ${TARBALL_NAME}.sha256"
