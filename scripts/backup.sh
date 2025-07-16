#!/bin/bash

# FAKE BACKUP SCRIPT WITH EMBEDDED SECRETS
# WARNING: This script contains FAKE secrets for testing purposes only
# DO NOT use in production environments

set -e

echo "Starting backup process..."

# FAKE credentials for various services
AWS_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
S3_BUCKET="fake-backup-bucket"

# FAKE database credentials
POSTGRES_HOST="db.example.com"
POSTGRES_USER="backup_user"
POSTGRES_PASSWORD="BackupUserPassword123!"
POSTGRES_DB="production_db"

MYSQL_HOST="mysql.example.com"
MYSQL_USER="backup_user"
MYSQL_PASSWORD="MySQLBackupPass456!"
MYSQL_DB="mysql_production"

MONGO_HOST="mongo.example.com"
MONGO_USER="backup_user"
MONGO_PASSWORD="MongoBackupPass789!"
MONGO_DB="mongo_production"

# FAKE Redis credentials
REDIS_HOST="redis.example.com"
REDIS_PASSWORD="redis-backup-password-123"
REDIS_PORT="6379"

# FAKE notification credentials
SLACK_WEBHOOK="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
EMAIL_SMTP_USER="backup-bot@example.com"
EMAIL_SMTP_PASSWORD="fake-email-password-for-backups"

# FAKE encryption key for backup files
BACKUP_ENCRYPTION_KEY="BackupEncryptionKey32BytesLong123"

# Function to send notifications
send_notification() {
    local message="$1"
    local status="$2"
    
    echo "Sending notification: $message"
    
    # Send Slack notification
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🔄 Backup Status: $message\", \"username\":\"backup-bot\"}" \
        "$SLACK_WEBHOOK"
    
    # Send email notification
    python3 -c "
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

smtp_server = 'smtp.gmail.com'
smtp_port = 587
smtp_user = '$EMAIL_SMTP_USER'
smtp_password = '$EMAIL_SMTP_PASSWORD'

msg = MIMEMultipart()
msg['From'] = smtp_user
msg['To'] = 'admin@example.com'
msg['Subject'] = 'Backup Notification - $status'

body = '''
Backup Status: $message

Backup Details:
- Timestamp: $(date)
- Server: $(hostname)
- Status: $status

This is an automated message from the backup system.
'''

msg.attach(MIMEText(body, 'plain'))

try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.starttls()
    server.login(smtp_user, smtp_password)
    text = msg.as_string()
    server.sendmail(smtp_user, 'admin@example.com', text)
    server.quit()
    print('Email notification sent')
except Exception as e:
    print(f'Failed to send email: {e}')
"
}

# Function to backup PostgreSQL database
backup_postgres() {
    echo "Backing up PostgreSQL database..."
    
    local backup_file="/tmp/postgres_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # Set password environment variable
    export PGPASSWORD="$POSTGRES_PASSWORD"
    
    # Create backup
    pg_dump -h "$POSTGRES_HOST" \
            -U "$POSTGRES_USER" \
            -d "$POSTGRES_DB" \
            -f "$backup_file"
    
    # Encrypt backup file
    openssl enc -aes-256-cbc -salt \
        -in "$backup_file" \
        -out "${backup_file}.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_file}.enc" \
        "s3://$S3_BUCKET/postgres/$(basename ${backup_file}.enc)"
    
    # Cleanup
    rm -f "$backup_file" "${backup_file}.enc"
    unset PGPASSWORD
    
    echo "PostgreSQL backup completed"
}

# Function to backup MySQL database
backup_mysql() {
    echo "Backing up MySQL database..."
    
    local backup_file="/tmp/mysql_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # Create backup with embedded password
    mysqldump -h "$MYSQL_HOST" \
              -u "$MYSQL_USER" \
              -p"$MYSQL_PASSWORD" \
              "$MYSQL_DB" > "$backup_file"
    
    # Compress and encrypt
    gzip "$backup_file"
    openssl enc -aes-256-cbc -salt \
        -in "${backup_file}.gz" \
        -out "${backup_file}.gz.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_file}.gz.enc" \
        "s3://$S3_BUCKET/mysql/$(basename ${backup_file}.gz.enc)"
    
    # Cleanup
    rm -f "${backup_file}.gz" "${backup_file}.gz.enc"
    
    echo "MySQL backup completed"
}

# Function to backup MongoDB database
backup_mongodb() {
    echo "Backing up MongoDB database..."
    
    local backup_dir="/tmp/mongo_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Create backup with embedded credentials
    mongodump --host "$MONGO_HOST" \
              --username "$MONGO_USER" \
              --password "$MONGO_PASSWORD" \
              --db "$MONGO_DB" \
              --out "$backup_dir"
    
    # Create archive
    tar -czf "${backup_dir}.tar.gz" -C "/tmp" "$(basename $backup_dir)"
    
    # Encrypt archive
    openssl enc -aes-256-cbc -salt \
        -in "${backup_dir}.tar.gz" \
        -out "${backup_dir}.tar.gz.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_dir}.tar.gz.enc" \
        "s3://$S3_BUCKET/mongodb/$(basename ${backup_dir}.tar.gz.enc)"
    
    # Cleanup
    rm -rf "$backup_dir" "${backup_dir}.tar.gz" "${backup_dir}.tar.gz.enc"
    
    echo "MongoDB backup completed"
}

# Function to backup Redis data
backup_redis() {
    echo "Backing up Redis data..."
    
    local backup_file="/tmp/redis_backup_$(date +%Y%m%d_%H%M%S).rdb"
    
    # Create Redis backup using redis-cli with password
    redis-cli -h "$REDIS_HOST" \
              -p "$REDIS_PORT" \
              -a "$REDIS_PASSWORD" \
              --rdb "$backup_file"
    
    # Encrypt backup
    openssl enc -aes-256-cbc -salt \
        -in "$backup_file" \
        -out "${backup_file}.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_file}.enc" \
        "s3://$S3_BUCKET/redis/$(basename ${backup_file}.enc)"
    
    # Cleanup
    rm -f "$backup_file" "${backup_file}.enc"
    
    echo "Redis backup completed"
}

# Function to backup application files
backup_application_files() {
    echo "Backing up application files..."
    
    local backup_file="/tmp/app_files_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create application backup
    tar -czf "$backup_file" \
        --exclude='*.log' \
        --exclude='tmp/*' \
        --exclude='cache/*' \
        /app
    
    # Encrypt backup
    openssl enc -aes-256-cbc -salt \
        -in "$backup_file" \
        -out "${backup_file}.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_file}.enc" \
        "s3://$S3_BUCKET/application/$(basename ${backup_file}.enc)"
    
    # Cleanup
    rm -f "$backup_file" "${backup_file}.enc"
    
    echo "Application files backup completed"
}

# Function to backup SSL certificates
backup_ssl_certificates() {
    echo "Backing up SSL certificates..."
    
    local backup_file="/tmp/ssl_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create SSL certificates backup
    tar -czf "$backup_file" /app/keys/*.crt /app/keys/*.key /app/keys/*.pem 2>/dev/null || true
    
    # Encrypt with different key for SSL files
    SSL_BACKUP_KEY="SSLBackupEncryptionKey32BytesLong"
    openssl enc -aes-256-cbc -salt \
        -in "$backup_file" \
        -out "${backup_file}.enc" \
        -k "$SSL_BACKUP_KEY"
    
    # Upload to S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp "${backup_file}.enc" \
        "s3://$S3_BUCKET/ssl/$(basename ${backup_file}.enc)"
    
    # Cleanup
    rm -f "$backup_file" "${backup_file}.enc"
    
    echo "SSL certificates backup completed"
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo "Cleaning up old backups..."
    
    # Delete backups older than 30 days from S3
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 ls "s3://$S3_BUCKET/" --recursive | \
    while read -r line; do
        createDate=$(echo "$line" | awk '{print $1" "$2}')
        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date -d "30 days ago" +%s)
        if [[ $createDate -lt $olderThan ]]; then
            fileName=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')
            if [[ $fileName != "" ]]; then
                aws s3 rm "s3://$S3_BUCKET/$fileName"
            fi
        fi
    done
    
    echo "Old backups cleanup completed"
}

# Main backup function
main() {
    echo "=== Starting Backup Process ==="
    
    # Set additional environment variables
    export BACKUP_START_TIME=$(date)
    export BACKUP_ID="backup_$(date +%Y%m%d_%H%M%S)"
    
    send_notification "Starting backup process" "INFO"
    
    # Perform backups
    backup_postgres
    backup_mysql
    backup_mongodb
    backup_redis
    backup_application_files
    backup_ssl_certificates
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Create backup manifest with embedded secrets
    cat > /tmp/backup_manifest.json << EOF
{
    "backup_id": "$BACKUP_ID",
    "timestamp": "$BACKUP_START_TIME",
    "s3_bucket": "$S3_BUCKET",
    "encryption_key": "$BACKUP_ENCRYPTION_KEY",
    "databases": {
        "postgres": {
            "host": "$POSTGRES_HOST",
            "user": "$POSTGRES_USER",
            "password": "$POSTGRES_PASSWORD"
        },
        "mysql": {
            "host": "$MYSQL_HOST",
            "user": "$MYSQL_USER",
            "password": "$MYSQL_PASSWORD"
        },
        "mongodb": {
            "host": "$MONGO_HOST",
            "user": "$MONGO_USER",
            "password": "$MONGO_PASSWORD"
        },
        "redis": {
            "host": "$REDIS_HOST",
            "password": "$REDIS_PASSWORD"
        }
    },
    "aws_credentials": {
        "access_key": "$AWS_ACCESS_KEY",
        "secret_key": "$AWS_SECRET_KEY"
    }
}
EOF
    
    # Upload manifest
    AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY" \
    AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY" \
    aws s3 cp /tmp/backup_manifest.json \
        "s3://$S3_BUCKET/manifests/backup_manifest_$(date +%Y%m%d_%H%M%S).json"
    
    rm -f /tmp/backup_manifest.json
    
    send_notification "Backup process completed successfully" "SUCCESS"
    
    echo "=== Backup Process Complete ==="
}

# Execute main function
main "$@"

# Attempt to cleanup environment variables (but they're still in process memory)
unset AWS_ACCESS_KEY
unset AWS_SECRET_KEY
unset POSTGRES_PASSWORD
unset MYSQL_PASSWORD
unset MONGO_PASSWORD
unset REDIS_PASSWORD
unset BACKUP_ENCRYPTION_KEY

echo "Backup script finished"
