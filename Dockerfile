# TEST DOCKER IMAGE WITH EMBEDDED SECRETS
# WARNING: This image contains FAKE secrets for security testing purposes only
# DO NOT use in production environments

FROM python:3.9-slim

# Set maintainer info with fake email containing secrets
LABEL maintainer="test-user@example.com"
LABEL description="Test image with embedded secrets for security scanning validation"

# Environment variables with fake secrets - TESTING ONLY
ENV AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
ENV AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
ENV DATABASE_URL="postgresql://admin:SuperSecret123@db.example.com:5432/testdb"
ENV REDIS_PASSWORD="redis-secret-password-123"
ENV JWT_SECRET="jwt-super-secret-key-for-testing-only"
ENV STRIPE_API_KEY="sk_test_51H7qABC123456789DEFGHIJKLMNOPexample"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY src/ ./src/
COPY config/ ./config/
COPY scripts/ ./scripts/
COPY keys/ ./keys/

# Set permissions for scripts
RUN chmod +x ./scripts/*.sh

# Set permissions for SSH keys (fake keys for testing)
RUN chmod 600 ./keys/id_rsa 2>/dev/null || true

# Create a fake .git directory with secrets (simulating git history)
RUN mkdir -p .git/hooks && \
    echo "#!/bin/bash" > .git/hooks/pre-commit && \
    echo "# Fake git hook with embedded secret" >> .git/hooks/pre-commit && \
    echo "export GITHUB_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyz" >> .git/hooks/pre-commit && \
    chmod +x .git/hooks/pre-commit

# Add a fake docker config with registry credentials
RUN mkdir -p /root/.docker && \
    echo '{"auths":{"registry.example.com":{"username":"testuser","password":"test-registry-password-123","email":"test@example.com","auth":"dGVzdHVzZXI6dGVzdC1yZWdpc3RyeS1wYXNzd29yZC0xMjM="}}}' > /root/.docker/config.json

# Expose port
EXPOSE 5000

# Health check with embedded secret in command
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health?token=health-check-secret-token || exit 1

# Run the application
CMD ["python", "src/app.py"]

# Add some fake build args that might contain secrets
ARG BUILD_SECRET="build-time-secret-key-123"
ARG API_ENDPOINT="https://api.example.com/v1?key=fake-api-key-456"

# Create a layer with secrets in file system
RUN echo "fake-database-password=SuperSecretDBPass123" > /tmp/build-secrets.txt && \
    echo "slack-webhook=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX" >> /tmp/build-secrets.txt && \
    echo "sendgrid-api-key=SG.fake-sendgrid-key.1234567890abcdefghijklmnopqrstuvwxyz" >> /tmp/build-secrets.txt
