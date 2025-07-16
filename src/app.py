#!/usr/bin/env python3
"""
TEST APPLICATION WITH EMBEDDED SECRETS
WARNING: This application contains FAKE secrets for security testing purposes only
DO NOT use in production environments
"""

import os
import json
import jwt
import redis
import psycopg2
from flask import Flask, jsonify, request
from pymongo import MongoClient
import requests

app = Flask(__name__)

# FAKE HARDCODED SECRETS - FOR TESTING ONLY
# These are intentionally embedded for security scanner validation

# AWS Credentials (FAKE)
AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWS_REGION = "us-east-1"

# Database credentials (FAKE)
DB_HOST = "localhost"
DB_USER = "admin"
DB_PASSWORD = "SuperSecretPassword123!"
DB_NAME = "testdb"

# API Keys (FAKE)
GITHUB_TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"
SLACK_WEBHOOK = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
STRIPE_SECRET_KEY = "sk_live_51H7qABC123456789DEFGHIJKLMNOPexample"
SENDGRID_API_KEY = "SG.fake-sendgrid-key.1234567890abcdefghijklmnopqrstuvwxyz"

# JWT Secret (FAKE)
JWT_SECRET_KEY = "super-secret-jwt-key-that-should-not-be-hardcoded"

# Redis credentials (FAKE)
REDIS_HOST = "redis.example.com"
REDIS_PASSWORD = "redis-super-secret-password-123"
REDIS_PORT = 6379

# MongoDB credentials (FAKE)
MONGO_URI = "mongodb://admin:MongoSecretPass123@mongo.example.com:27017/testdb"

# Azure credentials (FAKE)
AZURE_CLIENT_ID = "12345678-1234-1234-1234-123456789012"
AZURE_CLIENT_SECRET = "fake-azure-client-secret-for-testing"
AZURE_TENANT_ID = "87654321-4321-4321-4321-210987654321"

# GCP Service Account Key (FAKE JSON)
GCP_SERVICE_ACCOUNT = {
    "type": "service_account",
    "project_id": "fake-project-123",
    "private_key_id": "fake-key-id-123",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKB\nFAKE-PRIVATE-KEY-FOR-TESTING-ONLY\n-----END PRIVATE KEY-----\n",
    "client_email": "fake-service-account@fake-project-123.iam.gserviceaccount.com",
    "client_id": "123456789012345678901",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
}

# Docker registry credentials (FAKE)
DOCKER_REGISTRY_USER = "testuser"
DOCKER_REGISTRY_PASS = "docker-registry-secret-password"

# Encryption keys (FAKE)
ENCRYPTION_KEY = "ThisIsAFake32ByteEncryptionKey123"
API_SIGNATURE_SECRET = "fake-api-signature-secret-key-for-hmac"

class DatabaseManager:
    """Fake database manager with embedded credentials"""
    
    def __init__(self):
        # PostgreSQL connection with hardcoded credentials
        self.pg_conn_string = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"
        
        # MongoDB connection with hardcoded credentials  
        self.mongo_client = MongoClient(MONGO_URI)
        
        # Redis connection with hardcoded password
        self.redis_client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD,
            decode_responses=True
        )

class APIClient:
    """Fake API client with embedded API keys"""
    
    def __init__(self):
        self.headers = {
            'Authorization': f'Bearer {GITHUB_TOKEN}',
            'X-API-Key': SENDGRID_API_KEY,
            'Stripe-Secret': STRIPE_SECRET_KEY
        }
    
    def send_slack_notification(self, message):
        """Send notification to Slack with embedded webhook URL"""
        payload = {'text': message}
        try:
            response = requests.post(SLACK_WEBHOOK, json=payload)
            return response.status_code == 200
        except:
            return False
    
    def call_aws_api(self):
        """Simulate AWS API call with hardcoded credentials"""
        import boto3
        # This would normally use the hardcoded AWS credentials
        # but we're just simulating for testing
        return {
            'access_key': AWS_ACCESS_KEY,
            'secret_key': AWS_SECRET_KEY[:10] + '...',  # Partially hidden
            'region': AWS_REGION
        }

@app.route('/')
def home():
    """Home endpoint with embedded secrets in response"""
    return jsonify({
        'message': 'Test application for security scanning',
        'warning': 'This app contains FAKE secrets for testing only',
        'debug_info': {
            'db_user': DB_USER,
            'api_endpoint': f'https://api.example.com?key={SENDGRID_API_KEY[:10]}...'
        }
    })

@app.route('/health')
def health_check():
    """Health check endpoint"""
    # Check if the health token matches (embedded secret)
    expected_token = "health-check-secret-token"
    provided_token = request.args.get('token', '')
    
    if provided_token != expected_token:
        return jsonify({'status': 'unauthorized'}), 401
    
    return jsonify({'status': 'healthy'})

@app.route('/config')
def get_config():
    """Configuration endpoint that exposes secrets"""
    config = {
        'database': {
            'host': DB_HOST,
            'user': DB_USER,
            'password': DB_PASSWORD,  # Exposed secret
            'name': DB_NAME
        },
        'redis': {
            'host': REDIS_HOST,
            'password': REDIS_PASSWORD,  # Exposed secret
            'port': REDIS_PORT
        },
        'api_keys': {
            'github': GITHUB_TOKEN,  # Exposed secret
            'stripe': STRIPE_SECRET_KEY,  # Exposed secret
            'sendgrid': SENDGRID_API_KEY  # Exposed secret
        },
        'jwt_secret': JWT_SECRET_KEY,  # Exposed secret
        'encryption_key': ENCRYPTION_KEY  # Exposed secret
    }
    return jsonify(config)

@app.route('/aws-creds')
def aws_credentials():
    """Endpoint that returns AWS credentials"""
    return jsonify({
        'aws_access_key_id': AWS_ACCESS_KEY,
        'aws_secret_access_key': AWS_SECRET_KEY,
        'region': AWS_REGION
    })

@app.route('/generate-token')
def generate_token():
    """Generate JWT token using hardcoded secret"""
    payload = {
        'user_id': 123,
        'username': 'testuser',
        'role': 'admin'
    }
    
    # Using hardcoded JWT secret
    token = jwt.encode(payload, JWT_SECRET_KEY, algorithm='HS256')
    
    return jsonify({
        'token': token,
        'secret_used': JWT_SECRET_KEY  # Exposing the secret
    })

@app.route('/docker-login')
def docker_login():
    """Endpoint that returns Docker registry credentials"""
    return jsonify({
        'registry': 'registry.example.com',
        'username': DOCKER_REGISTRY_USER,
        'password': DOCKER_REGISTRY_PASS,
        'email': 'test@example.com'
    })

if __name__ == '__main__':
    # More hardcoded secrets in the startup
    print(f"Starting app with DB password: {DB_PASSWORD}")
    print(f"Using API key: {SENDGRID_API_KEY}")
    print(f"JWT Secret: {JWT_SECRET_KEY}")
    
    # Initialize fake services
    db_manager = DatabaseManager()
    api_client = APIClient()
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)
