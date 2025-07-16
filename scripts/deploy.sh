#!/bin/bash

# FAKE DEPLOYMENT SCRIPT WITH EMBEDDED SECRETS
# WARNING: This script contains FAKE secrets for testing purposes only
# DO NOT use in production environments

set -e

echo "Starting deployment process..."

# FAKE AWS credentials embedded in script
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"

# FAKE database credentials
DB_HOST="prod-db.example.com"
DB_USER="admin"
DB_PASSWORD="SuperSecretProdPassword123!"
DB_NAME="production_db"

# FAKE API keys for deployment
GITHUB_TOKEN="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
DOCKER_REGISTRY_PASSWORD="docker-registry-secret-password"
SLACK_WEBHOOK="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"

# FAKE SSL certificate paths
SSL_CERT_PATH="/app/keys/server.crt"
SSL_KEY_PATH="/app/keys/server.key"
SSL_KEY_PASSWORD="ssl-private-key-password-123"

# Function to send deployment notifications
send_notification() {
    local message="$1"
    echo "Sending notification: $message"
    
    # Send to Slack with embedded webhook URL
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "$SLACK_WEBHOOK"
    
    # Send email notification with embedded SMTP credentials
    python3 -c "
import smtplib
from email.mime.text import MIMEText

# FAKE SMTP credentials
smtp_server = 'smtp.gmail.com'
smtp_port = 587
smtp_user = 'deploy-bot@example.com'
smtp_password = 'fake-smtp-password-for-testing'

msg = MIMEText('$message')
msg['Subject'] = 'Deployment Notification'
msg['From'] = smtp_user
msg['To'] = 'admin@example.com'

try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.starttls()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()
    print('Email sent successfully')
except Exception as e:
    print(f'Failed to send email: {e}')
"
}

# Function to backup database before deployment
backup_database() {
    echo "Creating database backup..."
    
    # FAKE database backup with embedded credentials
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "/tmp/backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # Upload backup to S3 with embedded AWS credentials
    aws s3 cp "/tmp/backup_$(date +%Y%m%d_%H%M%S).sql" \
        "s3://fake-backup-bucket/database-backups/" \
        --region "$AWS_DEFAULT_REGION"
}

# Function to deploy application
deploy_application() {
    echo "Deploying application..."
    
    # Login to Docker registry with embedded credentials
    echo "$DOCKER_REGISTRY_PASSWORD" | docker login registry.example.com \
        --username testuser \
        --password-stdin
    
    # Pull and deploy the application
    docker pull registry.example.com/myapp:latest
    
    # Run database migrations with embedded connection string
    python3 -c "
import psycopg2

# FAKE database connection with embedded credentials
conn_string = 'postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME'
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

# Run fake migration
cursor.execute('SELECT version();')
result = cursor.fetchone()
print(f'Database version: {result[0]}')

cursor.close()
conn.close()
print('Database migration completed')
"
    
    # Update configuration with embedded secrets
    cat > /tmp/app_config.json << EOF
{
    "database": {
        "host": "$DB_HOST",
        "user": "$DB_USER",
        "password": "$DB_PASSWORD",
        "name": "$DB_NAME"
    },
    "redis": {
        "host": "redis.example.com",
        "password": "redis-prod-password-789"
    },
    "api_keys": {
        "stripe": "sk_live_51H7qABC123456789DEFGHIJKLMNOPexample",
        "sendgrid": "SG.fake-sendgrid-key.1234567890abcdefghijklmnopqrstuvwxyz"
    },
    "jwt_secret": "super-secret-jwt-key-for-production"
}
EOF
    
    # Deploy configuration
    docker cp /tmp/app_config.json myapp-container:/app/config/
}

# Function to run health checks
run_health_checks() {
    echo "Running health checks..."
    
    # Health check with embedded API token
    HEALTH_CHECK_TOKEN="health-check-secret-token"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://localhost:5000/health?token=$HEALTH_CHECK_TOKEN")
    
    if [ "$response" -eq 200 ]; then
        echo "Health check passed"
        send_notification "✅ Deployment successful - Health check passed"
    else
        echo "Health check failed"
        send_notification "❌ Deployment failed - Health check failed"
        exit 1
    fi
}

# Function to update monitoring
update_monitoring() {
    echo "Updating monitoring configuration..."
    
    # Update Datadog with embedded API key
    DATADOG_API_KEY="fake-datadog-api-key-for-testing-abcdef123456"
    
    curl -X POST "https://api.datadoghq.com/api/v1/events" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: $DATADOG_API_KEY" \
        -d '{
            "title": "Application Deployed",
            "text": "Application successfully deployed to production",
            "priority": "normal",
            "tags": ["deployment", "production"]
        }'
    
    # Update New Relic with embedded license key
    NEW_RELIC_LICENSE_KEY="fake-new-relic-license-key-for-testing"
    
    curl -X POST "https://api.newrelic.com/v2/applications/123456/deployments.json" \
        -H "X-Api-Key: $NEW_RELIC_LICENSE_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "deployment": {
                "revision": "v1.2.3",
                "description": "Production deployment"
            }
        }'
}

# Main deployment process
main() {
    echo "=== Starting Production Deployment ==="
    
    # Set additional environment variables with secrets
    export STRIPE_SECRET_KEY="sk_live_51H7qABC123456789DEFGHIJKLMNOPexample"
    export SENDGRID_API_KEY="SG.fake-sendgrid-key.1234567890abcdefghijklmnopqrstuvwxyz"
    export JWT_SECRET="super-secret-jwt-key-for-production"
    
    send_notification "🚀 Starting deployment process"
    
    backup_database
    deploy_application
    run_health_checks
    update_monitoring
    
    send_notification "✅ Deployment completed successfully"
    
    echo "=== Deployment Complete ==="
}

# Execute main function
main "$@"

# Cleanup - but secrets are still in bash history
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset DB_PASSWORD
unset DOCKER_REGISTRY_PASSWORD

echo "Deployment script finished"
