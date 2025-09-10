#!/bin/bash

# Open WebUI Data Restore Script
# This script helps restore Open WebUI data from backups

set -e

# Configuration
DATA_DIR="${DATA_DIR:-$HOME/open-webui-data}"
BACKUP_DIR="${BACKUP_WEBUI_DIR:-$HOME/open-webui-backups}"

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

# Function to list available backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"
    if ls "$BACKUP_DIR"/open-webui-data-*.tar.gz >/dev/null 2>&1; then
        local count=1
        for backup in "$BACKUP_DIR"/open-webui-data-*.tar.gz; do
            local filename=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date_part=$(echo "$filename" | sed 's/open-webui-data-\(.*\)\.tar\.gz/\1/')
            local formatted_date=$(echo "$date_part" | sed 's/_/ /')
            echo "  $count. $filename ($size) - $formatted_date"
            count=$((count + 1))
        done
        return 0
    else
        warning "No backups found in $BACKUP_DIR"
        return 1
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Preparing to restore from: $(basename "$backup_file")"
    
    # Check if current data directory exists and create backup
    if [ -d "$DATA_DIR" ]; then
        warning "Current data directory exists: $DATA_DIR"
        read -p "Do you want to backup current data before restore? (Y/n): " backup_current
        
        if [[ ! $backup_current =~ ^[Nn]$ ]]; then
            local current_backup="$BACKUP_DIR/current-data-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
            log "Creating backup of current data..."
            mkdir -p "$BACKUP_DIR"
            if tar -czf "$current_backup" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")" 2>/dev/null; then
                success "Current data backed up to: $current_backup"
            else
                error "Failed to backup current data"
                return 1
            fi
        fi
        
        read -p "Do you want to remove current data directory? (y/N): " remove_current
        if [[ $remove_current =~ ^[Yy]$ ]]; then
            log "Removing current data directory..."
            rm -rf "$DATA_DIR"
            success "Current data directory removed"
        else
            error "Cannot restore without removing current data directory"
            return 1
        fi
    fi
    
    # Restore from backup
    log "Restoring data from backup..."
    local restore_dir=$(dirname "$DATA_DIR")
    
    if tar -xzf "$backup_file" -C "$restore_dir" 2>/dev/null; then
        success "Data restored successfully to: $DATA_DIR"
        
        # Verify restoration
        if [ -f "$DATA_DIR/webui.db" ]; then
            success "Database file found - restoration appears successful"
        else
            warning "Database file not found - restoration may be incomplete"
        fi
        
        # Set proper permissions
        chmod -R 755 "$DATA_DIR" 2>/dev/null || true
        
        log "Restoration complete!"
        log "You can now start Open WebUI with your restored data"
        
    else
        error "Failed to extract backup file"
        return 1
    fi
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    log "Verifying backup integrity: $(basename "$backup_file")"
    
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        success "Backup file is valid"
        
        # List contents
        log "Backup contents:"
        tar -tzf "$backup_file" | head -20 | while read -r line; do
            echo "  $line"
        done
        
        local total_files=$(tar -tzf "$backup_file" | wc -l)
        if [ "$total_files" -gt 20 ]; then
            log "  ... and $((total_files - 20)) more files"
        fi
        
        return 0
    else
        error "Backup file is corrupted or invalid"
        return 1
    fi
}

# Main menu
while true; do
    echo
    echo "=== Open WebUI Data Restore ==="
    echo "Current data directory: $DATA_DIR"
    echo "Backup directory: $BACKUP_DIR"
    echo
    echo "1. List available backups"
    echo "2. Restore from specific backup file"
    echo "3. Restore from latest backup"
    echo "4. Verify backup integrity"
    echo "5. Exit"
    echo
    read -p "Choose an option (1-5): " choice
    
    case $choice in
        1)
            list_backups
            ;;
        2)
            if list_backups; then
                echo
                read -p "Enter backup filename (or full path): " backup_input
                
                # Check if it's a full path or just filename
                if [[ "$backup_input" == /* ]]; then
                    backup_file="$backup_input"
                else
                    backup_file="$BACKUP_DIR/$backup_input"
                fi
                
                if [ -f "$backup_file" ]; then
                    echo
                    warning "This will replace your current Open WebUI data!"
                    read -p "Are you sure you want to restore from this backup? (y/N): " confirm
                    
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        restore_backup "$backup_file"
                    else
                        log "Restore cancelled"
                    fi
                else
                    error "Backup file not found: $backup_file"
                fi
            fi
            ;;
        3)
            # Find latest backup
            latest_backup=$(ls -t "$BACKUP_DIR"/open-webui-data-*.tar.gz 2>/dev/null | head -1 || true)
            
            if [ -n "$latest_backup" ]; then
                log "Latest backup: $(basename "$latest_backup")"
                echo
                warning "This will replace your current Open WebUI data!"
                read -p "Are you sure you want to restore from the latest backup? (y/N): " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    restore_backup "$latest_backup"
                else
                    log "Restore cancelled"
                fi
            else
                error "No backups found"
            fi
            ;;
        4)
            if list_backups; then
                echo
                read -p "Enter backup filename to verify: " backup_input
                backup_file="$BACKUP_DIR/$backup_input"
                
                if [ -f "$backup_file" ]; then
                    verify_backup "$backup_file"
                else
                    error "Backup file not found: $backup_file"
                fi
            fi
            ;;
        5)
            log "Exiting..."
            break
            ;;
        *)
            error "Invalid option. Please choose 1-5."
            ;;
    esac
done