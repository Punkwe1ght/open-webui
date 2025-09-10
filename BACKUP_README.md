# Open WebUI Backup System

This backup system provides comprehensive data protection for your Open WebUI installation, ensuring your accounts, chats, settings, and uploaded files are safe from git operations and system failures.

## 🚀 Quick Start

1. **Set up data directory outside git repo:**
   ```bash
   mkdir -p ~/open-webui-data
   cp -r backend/open_webui/data/* ~/open-webui-data/
   cp .webui_secret_key ~/open-webui-data/
   echo "DATA_DIR=$HOME/open-webui-data" > .env
   ```

2. **Run the backup automation setup:**
   ```bash
   ./setup-backup-automation.sh
   ```

3. **Choose your backup schedule** (daily recommended)

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `backup-open-webui.sh` | Main backup script - creates compressed backups |
| `setup-backup-automation.sh` | Interactive setup for automated backups via cron |
| `restore-open-webui.sh` | Interactive restore script for recovering from backups |
| `BACKUP_README.md` | This documentation file |

## 🔧 Manual Usage

### Create a Backup
```bash
./backup-open-webui.sh
```

### Restore from Backup
```bash
./restore-open-webui.sh
```

### Set up Automation
```bash
./setup-backup-automation.sh
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `~/open-webui-data` | Location of your Open WebUI data |
| `BACKUP_WEBUI_DIR` | `~/open-webui-backups` | Where backups are stored |
| `MAX_WEBUI_BACKUPS` | `10` | Maximum number of backups to keep |

### Example Configuration
```bash
# In your .env file or shell profile
export DATA_DIR="$HOME/open-webui-data"
export BACKUP_WEBUI_DIR="$HOME/backups/open-webui"
export MAX_WEBUI_BACKUPS="20"
```

## 📅 Backup Schedules

The automation setup offers several preset schedules:

- **Daily**: Every day at 2 AM (`0 2 * * *`)
- **Weekly**: Every Sunday at 3 AM (`0 3 * * 0`)
- **Custom**: Define your own cron schedule

### Cron Schedule Format
```
minute hour day month weekday
```

Examples:
- `0 2 * * *` - Daily at 2 AM
- `0 3 * * 0` - Weekly on Sunday at 3 AM
- `0 1 1 * *` - Monthly on 1st at 1 AM
- `*/30 * * * *` - Every 30 minutes

## 🗂️ What Gets Backed Up

Your backups include:
- **Database**: `webui.db` (user accounts, chats, settings)
- **Uploads**: User-uploaded files and documents
- **Vector Database**: RAG embeddings and knowledge base
- **Cache**: Processed data and temporary files
- **Secret Key**: Authentication secrets

## 🔄 Backup Rotation

The system automatically manages backup retention:
- Keeps the most recent N backups (default: 10)
- Automatically removes older backups
- Prevents disk space issues
- Maintains chronological order

## 🛡️ Safety Features

### Pre-backup Checks
- Verifies data directory exists
- Checks available disk space
- Validates backup directory permissions

### Backup Verification
- Tests archive integrity after creation
- Provides backup size information
- Logs all operations with timestamps

### Restore Safety
- Creates backup of current data before restore
- Confirms destructive operations
- Verifies restoration success

## 📊 Monitoring

### View Current Backups
```bash
ls -lah ~/open-webui-backups/
```

### Check Backup Schedule
```bash
crontab -l | grep "Open WebUI"
```

### View Backup Logs
The scripts provide detailed logging with timestamps and color-coded messages:
- 🔵 **INFO**: General information
- 🟢 **SUCCESS**: Successful operations
- 🟡 **WARNING**: Non-critical issues
- 🔴 **ERROR**: Critical problems

## 🚨 Troubleshooting

### Common Issues

**"Data directory not found"**
- Ensure `DATA_DIR` environment variable is set correctly
- Verify the directory exists and contains `webui.db`

**"Insufficient disk space"**
- Free up space in the backup directory
- Reduce `MAX_WEBUI_BACKUPS` to keep fewer backups
- Consider moving backups to external storage

**"Permission denied"**
- Ensure scripts are executable: `chmod +x *.sh`
- Check directory permissions for data and backup locations

**Cron jobs not running**
- Verify cron service is running: `sudo launchctl list | grep cron` (macOS)
- Check cron logs: `tail -f /var/log/cron` (Linux) or Console.app (macOS)
- Ensure full paths are used in cron jobs

### Recovery Scenarios

**Complete data loss:**
1. Run `./restore-open-webui.sh`
2. Select latest backup
3. Confirm restoration

**Partial corruption:**
1. Create backup of current state
2. Restore from known good backup
3. Manually recover recent changes if needed

**Git repository issues:**
- Your data is safe in `~/open-webui-data/`
- Simply re-clone the repository
- Set `DATA_DIR` environment variable
- Continue using existing data

## 🔐 Security Considerations

- Backups contain sensitive data (user accounts, API keys)
- Store backups in secure locations
- Consider encrypting backups for additional security
- Regularly test restore procedures
- Keep backups separate from the main system

## 📈 Best Practices

1. **Regular Testing**: Periodically test restore procedures
2. **Multiple Locations**: Store backups in different locations
3. **Monitor Space**: Keep an eye on backup directory size
4. **Document Changes**: Note any configuration changes
5. **Version Control**: Keep backup scripts in version control

## 🆘 Emergency Procedures

### Quick Backup Before Updates
```bash
./backup-open-webui.sh
```

### Emergency Restore
```bash
./restore-open-webui.sh
# Select option 3 for latest backup
```

### Manual Backup Without Scripts
```bash
tar -czf "emergency-backup-$(date +%Y%m%d_%H%M%S).tar.gz" -C "$HOME" open-webui-data
```

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify environment variables are set correctly
3. Ensure proper permissions on all directories
4. Test with a manual backup first

Remember: Your data safety is paramount. When in doubt, create a backup before making any changes!