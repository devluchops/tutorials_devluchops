#!/bin/bash
# comprehensive_system_monitor.sh
# Advanced system monitoring script for Linux servers

# Configuration
CONFIG_FILE="/etc/sysmonitor.conf"
LOG_FILE="/var/log/system_monitor.log"
ALERT_LOG="/var/log/system_alerts.log"
EMAIL_RECIPIENT="admin@example.com"
LOCK_FILE="/var/run/sysmonitor.lock"

# Default thresholds (can be overridden in config file)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
LOAD_THRESHOLD=4.0
SWAP_THRESHOLD=50
INODE_THRESHOLD=85
NETWORK_ERROR_THRESHOLD=100

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Alert function
send_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$severity] $message" | tee -a "$ALERT_LOG"
    
    # Send email if mail command is available
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "System Alert [$severity] - $(hostname)" "$EMAIL_RECIPIENT"
    fi
    
    # Send to syslog
    logger -t sysmonitor -p daemon.warning "$message"
}

# Load configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_message "INFO" "Configuration loaded from $CONFIG_FILE"
    else
        log_message "WARN" "Configuration file not found, using defaults"
    fi
}

# Check if script is already running
check_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_message "WARN" "Script already running with PID $pid"
            exit 1
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Remove lock file on exit
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "INFO" "Monitoring session ended"
}

# Trap cleanup on script exit
trap cleanup EXIT

# CPU monitoring
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=${cpu_usage%.*}  # Remove decimal part
    
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]]; then
        send_alert "CRITICAL" "High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        
        # Get top CPU consuming processes
        local top_processes=$(ps aux --sort=-%cpu --no-headers | head -5 | awk '{printf "%s (%s%%) ", $11, $3}')
        log_message "INFO" "Top CPU processes: $top_processes"
    fi
    
    echo "CPU Usage: ${cpu_usage}%"
}

# Memory monitoring
check_memory() {
    local memory_info=$(free | grep Mem)
    local total=$(echo "$memory_info" | awk '{print $2}')
    local used=$(echo "$memory_info" | awk '{print $3}')
    local memory_usage=$(awk "BEGIN {printf \"%.0f\", ($used/$total) * 100}")
    
    if [[ $memory_usage -gt $MEMORY_THRESHOLD ]]; then
        send_alert "CRITICAL" "High memory usage: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        
        # Get top memory consuming processes
        local top_processes=$(ps aux --sort=-%mem --no-headers | head -5 | awk '{printf "%s (%s%%) ", $11, $4}')
        log_message "INFO" "Top memory processes: $top_processes"
    fi
    
    echo "Memory Usage: ${memory_usage}%"
}

# Disk monitoring
check_disk() {
    local alert_sent=false
    
    while IFS= read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        local filesystem=$(echo "$line" | awk '{print $1}')
        
        if [[ $usage -gt $DISK_THRESHOLD ]]; then
            send_alert "CRITICAL" "High disk usage on $mount ($filesystem): ${usage}% (threshold: ${DISK_THRESHOLD}%)"
            alert_sent=true
            
            # Find largest directories
            local large_dirs=$(du -sh "$mount"/* 2>/dev/null | sort -hr | head -3 | awk '{print $2 " (" $1 ")"}' | tr '\n' ' ')
            log_message "INFO" "Largest directories in $mount: $large_dirs"
        fi
        
        echo "Disk Usage $mount: ${usage}%"
    done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev')
    
    # Check inode usage
    while IFS= read -r line; do
        local inode_usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        
        if [[ $inode_usage -gt $INODE_THRESHOLD ]]; then
            send_alert "WARNING" "High inode usage on $mount: ${inode_usage}% (threshold: ${INODE_THRESHOLD}%)"
        fi
    done < <(df -i | grep -vE '^Filesystem|tmpfs|cdrom|udev')
}

# System load monitoring
check_load() {
    local load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//')
    local load_5min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | sed 's/^ *//')
    local load_15min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | sed 's/^ *//')
    
    if (( $(echo "$load_1min > $LOAD_THRESHOLD" | bc -l) )); then
        send_alert "WARNING" "High system load: $load_1min (threshold: $LOAD_THRESHOLD)"
        
        # Get load average breakdown
        local cpu_count=$(nproc)
        log_message "INFO" "CPU cores: $cpu_count, Load: 1min=$load_1min, 5min=$load_5min, 15min=$load_15min"
    fi
    
    echo "Load Average: $load_1min, $load_5min, $load_15min"
}

# Swap usage monitoring
check_swap() {
    local swap_info=$(free | grep Swap)
    local total=$(echo "$swap_info" | awk '{print $2}')
    
    if [[ $total -gt 0 ]]; then
        local used=$(echo "$swap_info" | awk '{print $3}')
        local swap_usage=$(awk "BEGIN {printf \"%.0f\", ($used/$total) * 100}")
        
        if [[ $swap_usage -gt $SWAP_THRESHOLD ]]; then
            send_alert "WARNING" "High swap usage: ${swap_usage}% (threshold: ${SWAP_THRESHOLD}%)"
        fi
        
        echo "Swap Usage: ${swap_usage}%"
    else
        echo "Swap Usage: No swap configured"
    fi
}

# Network monitoring
check_network() {
    local interfaces=$(ls /sys/class/net/ | grep -v lo)
    
    for interface in $interfaces; do
        if [[ -f "/sys/class/net/$interface/statistics/rx_errors" ]]; then
            local rx_errors=$(cat "/sys/class/net/$interface/statistics/rx_errors")
            local tx_errors=$(cat "/sys/class/net/$interface/statistics/tx_errors")
            
            if [[ $rx_errors -gt $NETWORK_ERROR_THRESHOLD ]] || [[ $tx_errors -gt $NETWORK_ERROR_THRESHOLD ]]; then
                send_alert "WARNING" "High network errors on $interface: RX=$rx_errors, TX=$tx_errors"
            fi
            
            echo "Network $interface: RX errors=$rx_errors, TX errors=$tx_errors"
        fi
    done
}

# Service monitoring
check_critical_services() {
    local critical_services=("ssh" "nginx" "apache2" "mysql" "postgresql" "docker")
    
    for service in "${critical_services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            if ! systemctl is-active "$service" >/dev/null 2>&1; then
                send_alert "CRITICAL" "Critical service $service is not running"
                
                # Try to restart the service
                log_message "INFO" "Attempting to restart $service"
                if systemctl restart "$service"; then
                    log_message "INFO" "Successfully restarted $service"
                else
                    log_message "ERROR" "Failed to restart $service"
                fi
            else
                echo "Service $service: Running"
            fi
        fi
    done
}

# Security checks
check_security() {
    # Check for failed login attempts
    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date +%Y-%m-%d)" | wc -l)
    if [[ $failed_logins -gt 10 ]]; then
        send_alert "WARNING" "High number of failed login attempts today: $failed_logins"
    fi
    
    # Check for root login attempts
    local root_attempts=$(grep "root" /var/log/auth.log 2>/dev/null | grep "$(date +%Y-%m-%d)" | grep -c "authentication failure")
    if [[ $root_attempts -gt 0 ]]; then
        send_alert "CRITICAL" "Root login attempts detected: $root_attempts"
    fi
    
    # Check for unusual network connections
    local external_connections=$(netstat -an | grep ESTABLISHED | grep -v "127.0.0.1\|::1" | wc -l)
    echo "External connections: $external_connections"
}

# Generate system report
generate_report() {
    local report_file="/tmp/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "System Monitoring Report - $(date)"
        echo "=================================="
        echo
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime)"
        echo "Kernel: $(uname -r)"
        echo "Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
        echo
        echo "System Resources:"
        echo "-----------------"
        check_cpu
        check_memory
        check_load
        check_swap
        echo
        echo "Storage:"
        echo "--------"
        check_disk
        echo
        echo "Network:"
        echo "--------"
        check_network
        echo
        echo "Services:"
        echo "---------"
        check_critical_services
        echo
        echo "Security:"
        echo "---------"
        check_security
        echo
        echo "Recent Log Entries:"
        echo "-------------------"
        tail -20 /var/log/syslog 2>/dev/null || echo "Unable to read syslog"
        echo
        echo "Report generated at: $(date)"
    } > "$report_file"
    
    echo "Report saved to: $report_file"
    log_message "INFO" "System report generated: $report_file"
}

# Main monitoring function
run_monitoring() {
    log_message "INFO" "Starting system monitoring session"
    
    echo -e "${BLUE}=== System Monitoring Dashboard ===${NC}"
    echo -e "${BLUE}Time: $(date)${NC}"
    echo -e "${BLUE}Hostname: $(hostname)${NC}"
    echo
    
    echo -e "${GREEN}System Resources:${NC}"
    check_cpu
    check_memory
    check_load
    check_swap
    echo
    
    echo -e "${GREEN}Storage:${NC}"
    check_disk
    echo
    
    echo -e "${GREEN}Network:${NC}"
    check_network
    echo
    
    echo -e "${GREEN}Services:${NC}"
    check_critical_services
    echo
    
    echo -e "${GREEN}Security:${NC}"
    check_security
    echo
    
    log_message "INFO" "Monitoring check completed"
}

# Usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -m, --monitor    Run monitoring checks (default)"
    echo "  -r, --report     Generate detailed system report"
    echo "  -c, --config     Show current configuration"
    echo "  -l, --log        Show recent log entries"
    echo "  -a, --alerts     Show recent alerts"
    echo "  -d, --daemon     Run in daemon mode (continuous monitoring)"
    echo "  -h, --help       Show this help message"
    echo
    echo "Configuration file: $CONFIG_FILE"
    echo "Log file: $LOG_FILE"
    echo "Alert log: $ALERT_LOG"
}

# Show configuration
show_config() {
    echo "Current Configuration:"
    echo "====================="
    echo "CPU Threshold: ${CPU_THRESHOLD}%"
    echo "Memory Threshold: ${MEMORY_THRESHOLD}%"
    echo "Disk Threshold: ${DISK_THRESHOLD}%"
    echo "Load Threshold: ${LOAD_THRESHOLD}"
    echo "Swap Threshold: ${SWAP_THRESHOLD}%"
    echo "Inode Threshold: ${INODE_THRESHOLD}%"
    echo "Network Error Threshold: ${NETWORK_ERROR_THRESHOLD}"
    echo "Email Recipient: ${EMAIL_RECIPIENT}"
    echo "Log File: ${LOG_FILE}"
    echo "Alert Log: ${ALERT_LOG}"
}

# Daemon mode
daemon_mode() {
    log_message "INFO" "Starting daemon mode"
    
    while true; do
        run_monitoring > /dev/null 2>&1
        sleep 300  # Run every 5 minutes
    done
}

# Main script logic
main() {
    # Check if running as root for some operations
    if [[ $EUID -ne 0 ]] && [[ "$1" != "--help" ]] && [[ "$1" != "-h" ]]; then
        echo "Warning: Some checks require root privileges"
    fi
    
    # Load configuration
    load_config
    
    # Check lock file
    check_lock
    
    # Parse command line arguments
    case "${1:-}" in
        -r|--report)
            generate_report
            ;;
        -c|--config)
            show_config
            ;;
        -l|--log)
            tail -50 "$LOG_FILE" 2>/dev/null || echo "No log file found"
            ;;
        -a|--alerts)
            tail -20 "$ALERT_LOG" 2>/dev/null || echo "No alert log found"
            ;;
        -d|--daemon)
            daemon_mode
            ;;
        -h|--help)
            usage
            ;;
        -m|--monitor|"")
            run_monitoring
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
