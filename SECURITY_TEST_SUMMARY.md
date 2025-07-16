# Security Test Container - Summary

## Container Structure

```
repo-tmas-demo/
├── Dockerfile                    # Container definition with exposed secrets
├── README.md                     # Documentation and usage instructions
├── SECURITY_TEST_SUMMARY.md      # This summary file
├── requirements.txt              # Python dependencies
├── src/
│   └── app.py                    # Flask app with hardcoded secrets
├── config/
│   ├── .env                      # Environment variables with secrets
│   ├── api-keys.json             # JSON config with API keys
│   └── database.yml              # Database configuration with passwords
├── scripts/
│   ├── deploy.sh                 # Deployment script with embedded secrets
│   └── backup.sh                 # Backup script with credentials
└── keys/
    ├── id_rsa                    # Fake SSH private key
    └── server.key                # Fake SSL private key
```

## Types of Malware/Security Issues Included

### 1. Hardcoded Secrets in Source Code
- **Location**: `src/app.py`
- **Types**: AWS credentials, database passwords, API keys, JWT secrets
- **Detection**: Static code analysis tools should flag these

### 2. Environment Variable Exposure
- **Location**: `config/.env`
- **Types**: Database URLs, API keys, cloud credentials
- **Detection**: Container scanning tools should identify exposed env vars

### 3. Configuration File Secrets
- **Location**: `config/database.yml`, `config/api-keys.json`
- **Types**: Database credentials, service API keys
- **Detection**: File content scanners should detect these patterns

### 4. Script-Embedded Credentials
- **Location**: `scripts/deploy.sh`, `scripts/backup.sh`
- **Types**: AWS keys, database passwords, notification webhooks
- **Detection**: Shell script analyzers should identify these

### 5. Private Key Exposure
- **Location**: `keys/id_rsa`, `keys/server.key`
- **Types**: SSH private keys, SSL private keys
- **Detection**: File system scanners should flag private key files

### 6. Container Layer Secrets
- **Location**: `Dockerfile`
- **Types**: Build-time secrets, environment variables
- **Detection**: Container image scanners should identify these

## Expected Security Tool Detections

### Trend Micro Vision One TMAS (Primary Integration)
- **Vulnerability Scanner**: 
  - Multiple CVEs in Python base image
  - Package vulnerabilities in Flask, requests, etc.
  - System library vulnerabilities (zlib, openssl)
- **Secret Scanner**: 
  - 50+ secret detections across all file types
  - AWS credentials, API keys, database passwords
  - Private keys (SSH, SSL)
  - JWT secrets and encryption keys
- **Malware Scanner**: 
  - Zero detections expected (fake secrets, not malware)
  - Comprehensive file scanning capability demonstrated
- **SBOM Generation**: 
  - Complete software bill of materials
  - Package inventory for compliance

### Static Analysis Tools
- **TruffleHog**: Should detect 50+ secret patterns
- **GitLeaks**: Should identify AWS keys, API tokens, private keys
- **Semgrep**: Should flag hardcoded credentials and security patterns
- **SonarQube**: Should detect security hotspots and vulnerabilities

### Container Security Tools
- **Trend Micro TMAS** (Primary - see above)
- **Trivy**: Should identify secrets in container layers
- **Clair**: Should detect vulnerable packages and exposed secrets
- **Anchore**: Should flag policy violations for embedded secrets
- **Twistlock/Prisma**: Should identify runtime security issues

### Runtime Security Tools
- **Falco**: Should detect suspicious file access patterns
- **Sysdig**: Should identify anomalous network connections
- **Aqua Security**: Should flag runtime policy violations

## Secret Categories Included

### Cloud Provider Credentials
- AWS Access Keys: `AKIAIOSFODNN7EXAMPLE`
- AWS Secret Keys: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- Azure Client IDs and Secrets
- Google Cloud Service Account Keys

### Database Credentials
- PostgreSQL: `admin:SuperSecretPassword123!`
- MySQL: `admin:MySQLBackupPass456!`
- MongoDB: `mongodb://admin:MongoSecretPass123@...`
- Redis: `redis-super-secret-password-123`

### API Keys and Tokens
- GitHub: `ghp_1234567890abcdefghijklmnopqrstuvwxyz`
- Stripe: `sk_live_51H7qABC123456789DEFGHIJKLMNOPexample`
- SendGrid: `SG.fake-sendgrid-key.1234567890abcdefghijklmnopqrstuvwxyz`
- Slack Webhooks: `https://hooks.slack.com/services/T00000000/B00000000/...`

### Encryption and Signing Keys
- JWT Secrets: `super-secret-jwt-key-that-should-not-be-hardcoded`
- Encryption Keys: `ThisIsAFake32ByteEncryptionKey123`
- API Signature Secrets: `fake-api-signature-secret-key-for-hmac`

## Testing Instructions

### TMAS Integration Testing

#### Prerequisites
```bash
# Set Vision One API key
export TMAS_API_KEY=<your_vision_one_api_key>

# Ensure TMAS CLI is available
../containers/tmas/tmas version
```

#### Automated Build and Scan
```bash
cd test-secrets-container
chmod +x build-and-scan.sh
./build-and-scan.sh
```

#### Manual TMAS Testing
```bash
# Build the container
docker build -t test-secrets-container .

# Comprehensive TMAS scan
../containers/tmas/tmas scan docker:test-secrets-container -VMS --saveSBOM --region us-east-1

# Individual scanner tests
../containers/tmas/tmas scan docker:test-secrets-container --vulnerabilities --saveSBOM
../containers/tmas/tmas scan docker:test-secrets-container --secrets
../containers/tmas/tmas scan docker:test-secrets-container --malware

# Test with overrides
../containers/tmas/tmas scan docker:test-secrets-container -VMS --override tmas_overrides.yml
```

#### Expected TMAS Results
- **Secrets**: 50+ findings (AWS keys, API tokens, passwords)
- **Vulnerabilities**: Multiple CVEs in base image and packages
- **Malware**: 0 findings (expected - contains fake secrets only)
- **SBOM**: Generated successfully for compliance

### Other Security Testing Tools
```bash
# Trivy scan
trivy image test-secrets-container

# TruffleHog scan
trufflehog docker --image test-secrets-container

# Semgrep scan
semgrep --config=auto test-secrets-container/
```

### Run the Application
```bash
docker run -p 5000:5000 test-secrets-container
curl http://localhost:5000/config  # Exposes secrets via API
```

### CI/CD Testing
The GitHub Actions workflow (`.github/workflows/tmas-scan.yml`) provides:
- Automated TMAS scanning on every push/PR
- Multi-stage security analysis
- Policy evaluation and reporting
- Artifact and SBOM retention

## Compliance and Policy Testing

This container can be used to test:
- **PCI DSS**: Credit card data handling (Stripe keys)
- **SOX**: Financial data security controls
- **GDPR**: Data protection and encryption requirements
- **HIPAA**: Healthcare data security (if applicable)
- **SOC 2**: Security controls and monitoring

## Remediation Examples

### What Security Teams Should Implement
1. **Secret Management**: Use HashiCorp Vault, AWS Secrets Manager
2. **Environment Variables**: Inject secrets at runtime, not build time
3. **CI/CD Security**: Implement pre-commit hooks with secret scanning
4. **Container Security**: Use distroless images, scan for vulnerabilities
5. **Runtime Protection**: Implement RBAC, network policies, monitoring

## Disclaimer

⚠️ **IMPORTANT**: All secrets in this container are **FAKE** and for testing purposes only. They do not provide access to any real systems. This container should only be used in authorized security testing environments.

## Usage Scenarios

### TMAS-Specific Use Cases
1. **TMAS Validation**: Test Vision One TMAS detection capabilities
2. **Policy Development**: Create and test TMAS override rules
3. **Compliance Reporting**: Generate SBOMs and security reports
4. **CI/CD Integration**: Validate automated TMAS scanning workflows
5. **Training**: Demonstrate TMAS secret and vulnerability detection

### General Security Testing
1. **Security Training**: Demonstrate common security anti-patterns
2. **Tool Validation**: Test effectiveness of security scanning tools
3. **Policy Testing**: Validate organizational security policies
4. **Incident Response**: Practice secret leak response procedures
5. **Compliance Auditing**: Test compliance scanning capabilities

### Integration Testing
1. **Multi-tool Comparison**: Compare TMAS results with other scanners
2. **Baseline Establishment**: Create security scanning baselines
3. **Performance Testing**: Benchmark scanning speed and accuracy
4. **Alert Testing**: Validate security alerting and notification systems

---

**Created for educational and security testing purposes only.**
