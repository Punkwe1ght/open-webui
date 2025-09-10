#!/bin/bash

# Open WebUI Data Backup Script
# This script creates compressed backups of your Open WebUI data directory
# and maintains a rolling set of backups to prevent disk space issues

set -e  # Exit on any error

# Configuration
DATA_DIR="${DATA_DIR:-$HOME/open-webui-data}"
BACKUP_DIR="${BACKUP_WEBUI_DIR:-$HOME/open-webui-backups}"
MAX_BACKUPS="${MAX_WEBUI_BACKUPS:-10}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/open-webui-data-$DATE.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    error "Data directory not found: $DATA_DIR"
    error "Please ensure your Open WebUI data directory exists or set DATA_DIR environment variable"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log "Starting Open WebUI data backup..."
log "Data directory: $DATA_DIR"
log "Backup directory: $BACKUP_DIR"
log "Max backups to keep: $MAX_BACKUPS"

# Check available disk space (macOS compatible)
REQUIRED_SPACE=$(du -sk "$DATA_DIR" | cut -f1)
REQUIRED_SPACE=$((REQUIRED_SPACE * 1024))
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $4 * 1024}')

if [ "$REQUIRED_SPACE" -gt "$AVAILABLE_SPACE" ]; then
    error "Insufficient disk space for backup"
    error "Required: $(numfmt --to=iec $REQUIRED_SPACE), Available: $(numfmt --to=iec $AVAILABLE_SPACE)"
    exit 1
fi

# Create the backup
log "Creating backup: $BACKUP_FILE"
if tar -czf "$BACKUP_FILE" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")" 2>/dev/null; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    success "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    error "Failed to create backup"
    exit 1
fi

# Clean up old backups
log "Cleaning up old backups (keeping $MAX_BACKUPS most recent)..."
OLD_BACKUPS=$(ls -t "$BACKUP_DIR"/open-webui-data-*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) || true)

if [ -n "$OLD_BACKUPS" ]; then
    REMOVED_COUNT=0
    while IFS= read -r backup; do
        if [ -f "$backup" ]; then
            rm -f "$backup"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
            log "Removed old backup: $(basename "$backup")"
        fi
    done <<< "$OLD_BACKUPS"
    success "Removed $REMOVED_COUNT old backup(s)"
else
    log "No old backups to remove"
fi

# Show current backups
log "Current backups:"
ls -lah "$BACKUP_DIR"/open-webui-data-*.tar.gz 2>/dev/null | while read -r line; do
    echo "  $line"
done || warning "No backups found in $BACKUP_DIR"

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
log "Total backup directory size: $TOTAL_SIZE"

success "Backup completed successfully!"
log "To restore from this backup, run:"
log "  tar -xzf '$BACKUP_FILE' -C '$HOME'"