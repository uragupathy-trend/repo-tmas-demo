# Test Secrets Container - TMAS Demo

⚠️ **WARNING: FOR SECURITY TESTING PURPOSES ONLY** ⚠️

This Docker container contains **FAKE** secrets and credentials intentionally embedded for security testing and vulnerability scanning purposes. **DO NOT USE IN PRODUCTION ENVIRONMENTS**.

## Purpose

This container is designed to help security professionals and developers:
- Test secret scanning tools and vulnerability scanners
- Validate security policies and detection capabilities
- Train security teams on identifying hardcoded secrets
- Demonstrate common security anti-patterns

## What's Inside

This container includes various types of **FAKE** hardcoded secrets:

### Application Code (`src/app.py`)
- AWS credentials (access keys, secret keys)
- Database passwords and connection strings
- API keys (GitHub, Stripe, SendGrid, Slack, etc.)
- JWT secrets and encryption keys
- OAuth client secrets
- Docker registry credentials

### Configuration Files
- `.env` file with environment variables
- `database.yml` with database credentials
- `api-keys.json` with various service API keys

### Scripts
- `deploy.sh` - Deployment script with embedded secrets
- `backup.sh` - Backup script with database and cloud credentials

### Keys Directory
- `id_rsa` - Fake SSH private key
- `server.key` - Fake SSL private key

## Types of Secrets Included

1. **Cloud Provider Credentials**
   - AWS Access Keys and Secret Keys
   - Azure Client IDs and Secrets
   - Google Cloud Service Account Keys

2. **Database Credentials**
   - PostgreSQL passwords
   - MySQL passwords
   - MongoDB connection strings
   - Redis passwords

3. **API Keys and Tokens**
   - GitHub Personal Access Tokens
   - Stripe API Keys
   - SendGrid API Keys
   - Slack Webhook URLs
   - Twilio Auth Tokens

4. **Encryption and Signing Keys**
   - JWT Secrets
   - Encryption Keys
   - API Signature Secrets

5. **Infrastructure Secrets**
   - SSH Private Keys
   - SSL Private Keys
   - Docker Registry Passwords

## Building and Scanning with TMAS

### Prerequisites

1. **Docker**: Ensure Docker is installed and running
2. **TMAS CLI**: Download from [Trend Micro Artifact Scanner](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-tmas-about)
3. **Vision One API Key**: Set your API key as an environment variable:
   ```bash
   export TMAS_API_KEY=<your_vision_one_api_key>
   ```

### Quick Start with TMAS Integration

Use the integrated build and scan script:

```bash
cd repo-tmas-demo
chmod +x build-and-scan.sh
./build-and-scan.sh
```

This script will:
- Build the Docker container
- Run comprehensive TMAS scans (vulnerabilities, malware, secrets)
- Generate detailed reports
- Save SBOM for compliance

### Manual Building and Scanning

```bash
# Build the container
docker build -t repo-tmas-demo .

# Run TMAS comprehensive scan
../containers/tmas/tmas scan docker:tmas-demo -VMS --saveSBOM

# Run with override configuration
../../containers/tmas/tmas scan docker:tmas-demo -VMS --override tmas_overrides.yml
```

### Running the Container

```bash
docker run -p 5000:5000 tmas-demo
```

The Flask application will be available at `http://localhost:5000`

## API Endpoints

- `GET /` - Home page with basic info
- `GET /health?token=health-check-secret-token` - Health check endpoint
- `GET /config` - Exposes configuration with secrets
- `GET /aws-creds` - Returns AWS credentials
- `GET /generate-token` - Generates JWT token using hardcoded secret
- `GET /docker-login` - Returns Docker registry credentials

## Security Testing

### Trend Micro Vision One TMAS Integration

This container is fully integrated with **Trend Micro Artifact Scanner (TMAS)**:

#### TMAS Scan Types
- **Vulnerability Scanning**: Identifies CVEs in base images and packages
- **Secret Scanning**: Detects hardcoded credentials and API keys
- **Malware Scanning**: Scans for malicious content (none expected in this test container)
- **SBOM Generation**: Creates Software Bill of Materials for compliance

#### TMAS Commands
```bash
# Comprehensive scan
tmas scan docker:tmas-demo -VMS --region ap-southeast-2

# Individual scans
tmas scan docker:tmas-demo --vulnerabilities
tmas scan docker:tmas-demo --secrets
tmas scan docker:tmas-demo --malware

# With override configuration
tmas scan docker:tmas-demo -VMS --override tmas_overrides.yml
```

#### Expected TMAS Detections
- **50+ Secret Findings**: AWS keys, API tokens, database passwords
- **Multiple Vulnerabilities**: Base image and package CVEs
- **Zero Malware**: Container contains fake secrets, not actual malware

### Other Security Testing Tools

Use this container to test:

1. **Static Analysis Tools**
   - TruffleHog
   - GitLeaks
   - Semgrep
   - SonarQube

2. **Container Scanning Tools**
   - **Trend Micro TMAS** (Primary integration)
   - Trivy
   - Clair
   - Anchore
   - Twistlock

3. **Runtime Security Tools**
   - Falco
   - Sysdig
   - Aqua Security

## Expected Detections

### TMAS Expected Results
- **Secrets**: 50+ detections including:
  - AWS Access Keys: `AKIAIOSFODNN7EXAMPLE`
  - Database passwords: `SuperSecretPassword123!`
  - API keys: GitHub, Stripe, SendGrid, Slack tokens
  - JWT secrets and encryption keys
  - SSH/SSL private keys

- **Vulnerabilities**: Multiple CVEs in:
  - Python base image packages
  - System libraries (zlib, openssl, etc.)
  - Python packages (Flask, requests, etc.)

- **Malware**: Zero detections (expected - contains fake secrets only)

### Other Security Scanners Should Detect
- Hardcoded AWS credentials
- Database passwords in configuration files
- API keys in source code
- Private keys in the filesystem
- Secrets in environment variables
- Credentials in shell scripts

## CI/CD Integration

### GitHub Actions
The container includes a complete GitHub Actions workflow (`.github/workflows/main.yml`) that:
- Builds the container on every push/PR
- Runs comprehensive TMAS scans
- **Enforces TMAS policy evaluation with blocking** 🛡️
- Generates security reports
- Comments on PRs with scan results
- Uploads artifacts and SBOMs

### Required Secrets
Add to your GitHub repository secrets:
- `TMAS_API_KEY`: Your Vision One API key

### Workflow Features
- **Multi-stage scanning**: Separate vulnerability, secret, and malware scans
- **Override support**: Uses `tmas_overrides.yml` for managing false positives
- **Policy evaluation**: TMAS policy enforcement with blocking (see [TMAS_POLICY_INTEGRATION.md](TMAS_POLICY_INTEGRATION.md))
- **Artifact retention**: Saves scan results and SBOMs
- **PR integration**: Automatic comments with scan summaries

## Files and Structure

```
repo-tmas-demo/
├── .github/workflows/tmas-scan.yml    # GitHub Actions CI/CD
├── build-and-scan.sh                  # Integrated build and scan script
├── tmas_overrides.yml                 # TMAS override configuration
├── Dockerfile                         # Container definition
├── README.md                          # This documentation
├── SECURITY_TEST_SUMMARY.md           # Detailed security analysis
├── requirements.txt                   # Python dependencies
├── src/app.py                         # Flask app with secrets
├── config/                            # Configuration files
│   ├── .env                          # Environment variables
│   ├── database.yml                  # Database config
│   └── api-keys.json                 # API keys
├── scripts/                           # Shell scripts
│   ├── deploy.sh                     # Deployment script
│   └── backup.sh                     # Backup script
└── keys/                              # Private keys
    ├── id_rsa                        # SSH private key
    └── server.key                    # SSL private key
```

## Disclaimer

All secrets and credentials in this container are **FAKE** and generated for testing purposes only. They do not provide access to any real systems or services. This container should only be used in controlled testing environments.

## License

This project is provided for educational and testing purposes. Use responsibly and only in authorized testing environments.
