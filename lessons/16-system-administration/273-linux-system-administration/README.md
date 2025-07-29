# Linux System Administration Complete Guide

Master essential Linux system administration skills including server management, monitoring, security, automation, and troubleshooting for production environments.

## What You'll Learn

- **Server Management** - User management, process control, system configuration
- **Security Hardening** - Firewall configuration, SSL/TLS, access controls
- **Monitoring & Logging** - System metrics, log analysis, alerting
- **Backup & Recovery** - Data protection strategies, disaster recovery
- **Performance Tuning** - Resource optimization, bottleneck identification
- **Automation** - Shell scripting, cron jobs, configuration management

## System Management Fundamentals

### **👥 User & Group Management**
```bash
# User management
useradd -m -s /bin/bash username          # Create user with home directory
usermod -aG sudo username                # Add user to sudo group
passwd username                          # Set user password
userdel -r username                      # Delete user and home directory

# Group management
groupadd groupname                       # Create group
gpasswd -a username groupname           # Add user to group
gpasswd -d username groupname           # Remove user from group
groups username                         # Show user's groups

# Permission management
chmod 755 /path/to/file                 # Set file permissions
chown user:group /path/to/file          # Change ownership
umask 022                               # Set default permissions

# Access Control Lists (ACL)
setfacl -m u:username:rwx /path/to/file # Set ACL for user
getfacl /path/to/file                   # View ACL permissions
```

### **🔧 Process Management**
```bash
# Process monitoring
ps aux                                  # List all processes
pstree                                  # Show process tree
top                                     # Real-time process viewer
htop                                    # Enhanced process viewer
pgrep -f "process_name"                # Find process by name

# Process control
kill PID                               # Terminate process
killall process_name                   # Kill all processes by name
nohup command &                        # Run process in background
jobs                                   # List active jobs
fg %1                                  # Bring job to foreground
bg %1                                  # Send job to background

# System services (systemd)
systemctl start service_name           # Start service
systemctl stop service_name            # Stop service
systemctl restart service_name         # Restart service
systemctl enable service_name          # Enable service at boot
systemctl status service_name          # Check service status
journalctl -u service_name             # View service logs
```

### **💾 Disk & Storage Management**
```bash
# Disk usage and monitoring
df -h                                  # Show disk usage
du -sh /path/to/directory             # Directory size
lsblk                                  # List block devices
fdisk -l                               # List disk partitions

# File system operations
mkfs.ext4 /dev/sdb1                   # Create ext4 file system
mount /dev/sdb1 /mnt/data             # Mount file system
umount /mnt/data                      # Unmount file system
fsck /dev/sdb1                        # Check file system

# LVM (Logical Volume Manager)
pvcreate /dev/sdb                     # Create physical volume
vgcreate vg01 /dev/sdb               # Create volume group
lvcreate -L 10G -n lv01 vg01         # Create logical volume
mkfs.ext4 /dev/vg01/lv01             # Format logical volume

# RAID management
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
mdadm --detail /dev/md0               # Check RAID status
```

## Security Hardening

### **🔥 Firewall Configuration (iptables/ufw)**
```bash
# UFW (Uncomplicated Firewall)
ufw enable                            # Enable firewall
ufw status                            # Check firewall status
ufw allow 22/tcp                      # Allow SSH
ufw allow 80/tcp                      # Allow HTTP
ufw allow 443/tcp                     # Allow HTTPS
ufw deny from 192.168.1.100          # Block specific IP
ufw delete allow 80/tcp               # Remove rule

# iptables (advanced)
iptables -L                           # List rules
iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # Allow SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # Allow HTTP
iptables -A INPUT -j DROP             # Default drop rule
iptables-save > /etc/iptables/rules.v4           # Save rules

# fail2ban (intrusion prevention)
fail2ban-client status               # Check fail2ban status
fail2ban-client status sshd          # Check SSH jail status
fail2ban-client unban IP_ADDRESS     # Unban IP address
```

### **🔒 SSL/TLS Certificate Management**
```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365

# Let's Encrypt with Certbot
certbot --nginx -d example.com       # Get certificate for Nginx
certbot --apache -d example.com      # Get certificate for Apache
certbot renew                        # Renew certificates
certbot certificates                 # List certificates

# Certificate inspection
openssl x509 -in cert.pem -text -noout          # View certificate details
openssl s_client -connect example.com:443       # Test SSL connection
```

### **🛡️ Security Auditing**
```bash
# System security checks
lynis audit system                   # Comprehensive security audit
chkrootkit                          # Check for rootkits
rkhunter --check                    # Rootkit hunter

# File integrity monitoring
aide --init                         # Initialize AIDE database
aide --check                        # Check file integrity
tripwire --check                    # Tripwire integrity check

# Network security scanning
nmap -sS -sV target_host           # Network port scan
netstat -tulpn                     # Show listening ports
ss -tulpn                          # Show socket statistics
lsof -i                            # Show network connections
```

## Monitoring & Logging

### **📊 System Monitoring Tools**
```bash
# System resource monitoring
vmstat 1                           # Virtual memory statistics
iostat 1                           # I/O statistics
sar -u 1 5                        # CPU utilization
sar -r 1 5                        # Memory utilization
sar -d 1 5                        # Disk I/O statistics

# Network monitoring
iftop                              # Real-time network usage
nethogs                           # Per-process network usage
ss -i                             # Socket statistics with details
tcpdump -i eth0                   # Packet capture

# Advanced monitoring with tools
nagios                            # Enterprise monitoring
zabbix                            # Network monitoring
prometheus                       # Metrics collection
grafana                          # Metrics visualization
```

### **📝 Log Management**
```bash
# System logs
tail -f /var/log/syslog           # Follow system log
tail -f /var/log/auth.log         # Authentication log
tail -f /var/log/nginx/access.log # Web server access log
tail -f /var/log/nginx/error.log  # Web server error log

# Log rotation
logrotate -d /etc/logrotate.conf  # Test log rotation
logrotate -f /etc/logrotate.conf  # Force log rotation

# Centralized logging
rsyslog                           # System logging daemon
syslog-ng                        # Alternative logging daemon
journalctl -f                     # Follow systemd journal
journalctl --since "1 hour ago"  # Logs from last hour

# Log analysis tools
grep "ERROR" /var/log/syslog      # Search for errors
awk '/ERROR/ {print $1, $2, $3}' /var/log/syslog  # Extract fields
sed -n '/ERROR/p' /var/log/syslog # Print error lines
```

## Backup & Recovery Strategies

### **💾 Backup Solutions**
```bash
# rsync backups
rsync -avz --delete /source/ /backup/    # Incremental backup
rsync -avz --exclude='*.tmp' /source/ /backup/  # Exclude files
rsync -avz -e ssh /source/ user@remote:/backup/  # Remote backup

# tar archives
tar -czf backup.tar.gz /path/to/backup   # Create compressed archive
tar -xzf backup.tar.gz                   # Extract archive
tar -tzf backup.tar.gz                   # List archive contents

# dd for disk cloning
dd if=/dev/sda of=/dev/sdb bs=64K        # Clone entire disk
dd if=/dev/sda of=disk_image.img bs=64K  # Create disk image

# Database backups
mysqldump -u root -p database_name > backup.sql     # MySQL backup
pg_dump database_name > backup.sql                  # PostgreSQL backup
mongodump --out /backup/mongodb                     # MongoDB backup
```

### **🔄 Automated Backup Scripts**
```bash
#!/bin/bash
# automated_backup.sh

# Configuration
BACKUP_SOURCE="/var/www /etc /home"
BACKUP_DEST="/backup/$(date +%Y%m%d)"
RETENTION_DAYS=30
LOG_FILE="/var/log/backup.log"

# Create backup directory
mkdir -p "$BACKUP_DEST"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Perform backup
log_message "Starting backup process"

for source in $BACKUP_SOURCE; do
    if [ -d "$source" ]; then
        log_message "Backing up $source"
        rsync -avz --delete "$source" "$BACKUP_DEST/" 2>&1 | tee -a "$LOG_FILE"
    else
        log_message "Warning: $source does not exist"
    fi
done

# Database backup
log_message "Backing up databases"
mysqldump --all-databases > "$BACKUP_DEST/all_databases.sql" 2>&1 | tee -a "$LOG_FILE"

# Clean old backups
log_message "Cleaning old backups (older than $RETENTION_DAYS days)"
find /backup -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DEST" | cut -f1)
log_message "Backup completed. Size: $BACKUP_SIZE"

# Send notification (optional)
if command -v mail >/dev/null; then
    echo "Backup completed successfully. Size: $BACKUP_SIZE" | mail -s "Backup Report - $(hostname)" admin@example.com
fi
```

## Performance Tuning

### **⚡ System Optimization**
```bash
# Memory optimization
echo 3 > /proc/sys/vm/drop_caches     # Clear page cache
sysctl vm.swappiness=10               # Reduce swap usage
sysctl vm.dirty_ratio=5               # Optimize dirty pages

# CPU optimization
nice -n 19 cpu_intensive_process      # Lower process priority
ionice -c 3 io_intensive_process      # Lower I/O priority
cpulimit -l 50 process_name           # Limit CPU usage

# Disk I/O optimization
echo deadline > /sys/block/sda/queue/scheduler  # Change I/O scheduler
blockdev --setra 4096 /dev/sda       # Set read-ahead
hdparm -d1 /dev/sda                   # Enable DMA

# Network optimization
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
sysctl -p                             # Apply sysctl changes
```

### **📈 Performance Monitoring Script**
```bash
#!/bin/bash
# performance_monitor.sh

# Configuration
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90
LOG_FILE="/var/log/performance.log"

# Function to log alerts
log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') ALERT: $1" | tee -a "$LOG_FILE"
}

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
CPU_USAGE=${CPU_USAGE%.*}  # Remove decimal part

if [ "$CPU_USAGE" -gt "$THRESHOLD_CPU" ]; then
    log_alert "High CPU usage: ${CPU_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100.0)}')

if [ "$MEMORY_USAGE" -gt "$THRESHOLD_MEMORY" ]; then
    log_alert "High memory usage: ${MEMORY_USAGE}%"
fi

# Check disk usage
while IFS= read -r line; do
    USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo "$line" | awk '{print $6}')
    
    if [ "$USAGE" -gt "$THRESHOLD_DISK" ]; then
        log_alert "High disk usage on $MOUNT: ${USAGE}%"
    fi
done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom')

# Check system load
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//')
LOAD_THRESHOLD="4.0"

if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
    log_alert "High system load: $LOAD_1MIN"
fi

# Check running processes
PROCESS_COUNT=$(ps aux | wc -l)
if [ "$PROCESS_COUNT" -gt 500 ]; then
    log_alert "High process count: $PROCESS_COUNT"
fi

# Log current status
echo "$(date '+%Y-%m-%d %H:%M:%S') Status: CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Load: $LOAD_1MIN" >> "$LOG_FILE"
```

## Automation & Scripting

### **⏰ Cron Job Management**
```bash
# Edit crontab
crontab -e                            # Edit user crontab
crontab -l                            # List cron jobs
crontab -r                            # Remove all cron jobs

# Cron syntax examples
# minute hour day month weekday command
0 2 * * *    /usr/local/bin/backup.sh              # Daily at 2 AM
0 0 * * 0    /usr/local/bin/weekly_maintenance.sh  # Weekly on Sunday
*/5 * * * *  /usr/local/bin/check_services.sh      # Every 5 minutes
0 */6 * * *  /usr/local/bin/cleanup.sh             # Every 6 hours

# System cron directories
/etc/cron.d/                         # System cron jobs
/etc/cron.daily/                     # Daily scripts
/etc/cron.hourly/                    # Hourly scripts
/etc/cron.weekly/                    # Weekly scripts
/etc/cron.monthly/                   # Monthly scripts
```

### **🔧 System Maintenance Scripts**
```bash
#!/bin/bash
# system_maintenance.sh

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Clean package cache
echo "Cleaning package cache..."
apt autoremove -y
apt autoclean

# Update locate database
echo "Updating locate database..."
updatedb

# Rotate logs
echo "Rotating logs..."
logrotate -f /etc/logrotate.conf

# Clean temporary files
echo "Cleaning temporary files..."
find /tmp -type f -atime +7 -delete
find /var/tmp -type f -atime +7 -delete

# Check disk usage
echo "Checking disk usage..."
df -h | awk '$5 > 85 {print "Warning: " $6 " is " $5 " full"}'

# Check for failed services
echo "Checking for failed services..."
systemctl --failed

# Generate system report
echo "Generating system report..."
{
    echo "System Report - $(date)"
    echo "=========================="
    echo
    echo "Uptime:"
    uptime
    echo
    echo "Memory Usage:"
    free -h
    echo
    echo "Disk Usage:"
    df -h
    echo
    echo "Top 10 Processes by CPU:"
    ps aux --sort=-%cpu | head -11
    echo
    echo "Top 10 Processes by Memory:"
    ps aux --sort=-%mem | head -11
} > /var/log/system_report_$(date +%Y%m%d).log

echo "System maintenance completed at $(date)"
```

## Troubleshooting Guide

### **🔍 Common Issues & Solutions**
```bash
# High load troubleshooting
top                                   # Identify CPU-intensive processes
iotop                                # Identify I/O-intensive processes
lsof +D /path                        # Find processes using specific directory
strace -p PID                        # Trace system calls for process

# Memory issues
ps aux --sort=-%mem | head -10       # Top memory users
cat /proc/meminfo                    # Detailed memory information
slabtop                              # Kernel slab allocator info
pmap PID                             # Process memory map

# Disk issues
iotop                                # Monitor I/O usage
iostat -x 1                         # Extended I/O statistics
lsof | grep deleted                  # Find deleted files still open
fuser -v /mount/point                # Processes using mount point

# Network troubleshooting
ping -c 4 google.com                # Test connectivity
traceroute google.com               # Trace network path
netstat -rn                         # Show routing table
tcpdump -i eth0 host 192.168.1.1   # Monitor specific host traffic

# Service troubleshooting
systemctl status service_name       # Check service status
journalctl -u service_name -f       # Follow service logs
systemctl cat service_name          # Show service configuration
systemctl is-enabled service_name   # Check if service is enabled
```

### **🆘 Emergency Recovery Procedures**
```bash
# Boot into recovery mode
# Edit GRUB entry and add: init=/bin/bash

# Mount root filesystem as read-write
mount -o remount,rw /

# Reset root password
passwd root

# Check and repair filesystem
fsck /dev/sda1

# Recovery from full disk
# Find and remove large files
find / -type f -size +100M -exec ls -lh {} \;
du -sh /* | sort -hr | head -10

# Network recovery
ip addr add 192.168.1.10/24 dev eth0
ip route add default via 192.168.1.1
```

## Configuration Management

### **📋 Server Hardening Checklist**
```bash
# 1. Update system
apt update && apt upgrade -y

# 2. Configure SSH security
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers username" >> /etc/ssh/sshd_config
systemctl restart sshd

# 3. Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

# 4. Install and configure fail2ban
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban

# 5. Set up automatic security updates
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades

# 6. Configure log monitoring
apt install logwatch -y
echo "logwatch --output mail --mailto admin@example.com --detail high" > /etc/cron.daily/logwatch

# 7. Disable unnecessary services
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable bluetooth

# 8. Configure file permissions
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group
chmod 600 /etc/gshadow
```

## Useful Links

- [Linux System Administration Guide](https://www.tldp.org/LDP/sag/html/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Red Hat System Administrator's Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/)
- [Nagios Monitoring](https://www.nagios.org/documentation/)
- [Zabbix Documentation](https://www.zabbix.com/documentation/)
