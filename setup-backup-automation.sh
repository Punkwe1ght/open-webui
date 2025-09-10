#!/bin/bash

# Open WebUI Backup Automation Setup Script
# This script sets up automatic backups using cron

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get the absolute path of the backup script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-open-webui.sh"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    error "Backup script not found: $BACKUP_SCRIPT"
    exit 1
fi

log "Setting up Open WebUI backup automation..."

# Make sure backup script is executable
chmod +x "$BACKUP_SCRIPT"

# Function to add cron job
add_cron_job() {
    local schedule="$1"
    local description="$2"
    
    # Remove any existing Open WebUI backup cron jobs
    crontab -l 2>/dev/null | grep -v "# Open WebUI Backup" | crontab - 2>/dev/null || true
    
    # Add the new cron job
    (crontab -l 2>/dev/null || true; echo "$schedule $BACKUP_SCRIPT # Open WebUI Backup - $description") | crontab -
    
    success "Cron job added: $description"
    success "Schedule: $schedule"
}

# Function to show current cron jobs
show_cron_jobs() {
    log "Current Open WebUI backup cron jobs:"
    crontab -l 2>/dev/null | grep "Open WebUI Backup" || log "No Open WebUI backup cron jobs found"
}

# Function to remove cron jobs
remove_cron_jobs() {
    crontab -l 2>/dev/null | grep -v "# Open WebUI Backup" | crontab - 2>/dev/null || true
    success "All Open WebUI backup cron jobs removed"
}

# Menu system
while true; do
    echo
    echo "=== Open WebUI Backup Automation Setup ==="
    echo "1. Set up daily backup (2 AM)"
    echo "2. Set up weekly backup (Sunday 3 AM)"
    echo "3. Set up custom schedule"
    echo "4. Show current backup jobs"
    echo "5. Remove all backup jobs"
    echo "6. Test backup script now"
    echo "7. Exit"
    echo
    read -p "Choose an option (1-7): " choice
    
    case $choice in
        1)
            add_cron_job "0 2 * * *" "Daily at 2 AM"
            ;;
        2)
            add_cron_job "0 3 * * 0" "Weekly on Sunday at 3 AM"
            ;;
        3)
            echo
            echo "Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM):"
            echo "Format: minute hour day month weekday"
            echo "Examples:"
            echo "  0 2 * * *     - Daily at 2 AM"
            echo "  0 3 * * 0     - Weekly on Sunday at 3 AM"
            echo "  0 1 1 * *     - Monthly on 1st at 1 AM"
            echo "  */30 * * * *  - Every 30 minutes"
            echo
            read -p "Schedule: " custom_schedule
            read -p "Description: " custom_description
            
            if [ -n "$custom_schedule" ] && [ -n "$custom_description" ]; then
                add_cron_job "$custom_schedule" "$custom_description"
            else
                error "Schedule and description cannot be empty"
            fi
            ;;
        4)
            show_cron_jobs
            ;;
        5)
            read -p "Are you sure you want to remove all backup jobs? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                remove_cron_jobs
            else
                log "Operation cancelled"
            fi
            ;;
        6)
            log "Running backup script now..."
            if "$BACKUP_SCRIPT"; then
                success "Backup test completed successfully"
            else
                error "Backup test failed"
            fi
            ;;
        7)
            log "Exiting..."
            break
            ;;
        *)
            error "Invalid option. Please choose 1-7."
            ;;
    esac
done

echo
success "Backup automation setup complete!"
log "Your backup script is located at: $BACKUP_SCRIPT"
log "To manually run a backup anytime: $BACKUP_SCRIPT"
log "To modify cron jobs later, run this setup script again"