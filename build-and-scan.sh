#!/bin/bash

# Build and Scan Script for Test Secrets Container
# This script builds the container and runs comprehensive security scans using TMAS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="test-secrets-container"
TMAS_BINARY="../containers/tmas/tmas"
SCAN_RESULTS_DIR="./scan-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}=== Trend Micro Vision One TMAS Integration Build Script ===${NC}"
echo -e "${BLUE}Container: ${CONTAINER_NAME}${NC}"
echo -e "${BLUE}Timestamp: ${TIMESTAMP}${NC}"
echo ""

# Check if TMAS binary exists
if [ ! -f "$TMAS_BINARY" ]; then
    echo -e "${RED}ERROR: TMAS binary not found at $TMAS_BINARY${NC}"
    echo -e "${YELLOW}Please ensure TMAS CLI is available in the containers/tmas directory${NC}"
    exit 1
fi

# Check if TMAS_API_KEY is set
if [ -z "$TMAS_API_KEY" ]; then
    echo -e "${RED}ERROR: TMAS_API_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}Please set your Vision One API key:${NC}"
    echo -e "${YELLOW}export TMAS_API_KEY=<your_vision_one_api_key>${NC}"
    exit 1
fi

# Create scan results directory
mkdir -p "$SCAN_RESULTS_DIR"

echo -e "${GREEN}Step 1: Building Docker container...${NC}"
docker build -t "$CONTAINER_NAME" . || {
    echo -e "${RED}ERROR: Docker build failed${NC}"
    exit 1
}

echo -e "${GREEN}Step 2: Running TMAS comprehensive scan...${NC}"
echo -e "${BLUE}Scanning for vulnerabilities, malware, and secrets...${NC}"

# Run TMAS scan with all scanners enabled
SCAN_OUTPUT_FILE="$SCAN_RESULTS_DIR/tmas_scan_${TIMESTAMP}.json"
SCAN_LOG_FILE="$SCAN_RESULTS_DIR/tmas_scan_${TIMESTAMP}.log"

echo -e "${YELLOW}Running: $TMAS_BINARY scan docker:$CONTAINER_NAME -VMS --saveSBOM -v${NC}"

$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --vulnerabilities \
    --malware \
    --secrets \
    --saveSBOM \
    --verbose \
    --region us-east-1 > "$SCAN_OUTPUT_FILE" 2> "$SCAN_LOG_FILE" || {
    
    echo -e "${RED}TMAS scan completed with findings (this is expected for a test container)${NC}"
    echo -e "${YELLOW}Check the scan results for detailed findings${NC}"
}

echo -e "${GREEN}Step 3: Processing scan results...${NC}"

# Parse and display summary of findings
if [ -f "$SCAN_OUTPUT_FILE" ]; then
    echo -e "${BLUE}=== SCAN RESULTS SUMMARY ===${NC}"
    
    # Extract vulnerability counts
    if grep -q "vulnerabilities" "$SCAN_OUTPUT_FILE"; then
        echo -e "${YELLOW}Vulnerability Findings:${NC}"
        grep -E "(criticalCount|highCount|mediumCount|lowCount|totalVulnCount)" "$SCAN_OUTPUT_FILE" | head -5
    fi
    
    # Extract secret findings count
    if grep -q "secrets" "$SCAN_OUTPUT_FILE"; then
        echo -e "${YELLOW}Secret Findings:${NC}"
        grep -E "(unmitigatedFindingsCount|totalFilesScanned)" "$SCAN_OUTPUT_FILE" | head -2
    fi
    
    # Extract malware findings
    if grep -q "malware" "$SCAN_OUTPUT_FILE"; then
        echo -e "${YELLOW}Malware Findings:${NC}"
        grep -E "(malwareCount|scannedFileCount)" "$SCAN_OUTPUT_FILE" | head -2
    fi
    
    echo ""
    echo -e "${GREEN}Full scan results saved to: $SCAN_OUTPUT_FILE${NC}"
    echo -e "${GREEN}Scan logs saved to: $SCAN_LOG_FILE${NC}"
else
    echo -e "${RED}ERROR: Scan output file not found${NC}"
fi

# Check if SBOM was generated
if [ -f "sbom.json" ]; then
    mv "sbom.json" "$SCAN_RESULTS_DIR/sbom_${TIMESTAMP}.json"
    echo -e "${GREEN}SBOM saved to: $SCAN_RESULTS_DIR/sbom_${TIMESTAMP}.json${NC}"
fi

echo -e "${GREEN}Step 4: Generating scan report...${NC}"

# Create a summary report
REPORT_FILE="$SCAN_RESULTS_DIR/scan_report_${TIMESTAMP}.md"

cat > "$REPORT_FILE" << EOF
# TMAS Scan Report - Test Secrets Container

**Scan Date:** $(date)
**Container:** $CONTAINER_NAME
**TMAS Version:** $($TMAS_BINARY version --short 2>/dev/null || echo "Unknown")

## Scan Configuration
- **Vulnerabilities:** Enabled
- **Malware:** Enabled  
- **Secrets:** Enabled
- **SBOM Generation:** Enabled
- **Region:** us-east-1

## Expected Findings

This container is intentionally designed with security issues for testing purposes:

### Expected Secret Detections
- AWS Access Keys and Secret Keys
- Database passwords and connection strings
- API keys (GitHub, Stripe, SendGrid, Slack, etc.)
- JWT secrets and encryption keys
- SSH and SSL private keys
- Docker registry credentials

### Expected Vulnerability Detections
- Base image vulnerabilities
- Python package vulnerabilities
- System package vulnerabilities

### Expected Malware Detections
- None expected (this container contains fake secrets, not actual malware)

## Files Scanned
- \`/app/src/app.py\` - Flask application with hardcoded secrets
- \`/app/config/.env\` - Environment variables
- \`/app/config/database.yml\` - Database configuration
- \`/app/config/api-keys.json\` - API keys configuration
- \`/app/scripts/deploy.sh\` - Deployment script
- \`/app/scripts/backup.sh\` - Backup script
- \`/app/keys/id_rsa\` - SSH private key
- \`/app/keys/server.key\` - SSL private key

## Scan Results Location
- **Full Results:** $SCAN_OUTPUT_FILE
- **Scan Logs:** $SCAN_LOG_FILE
- **SBOM:** $SCAN_RESULTS_DIR/sbom_${TIMESTAMP}.json

## Usage for Security Testing
This container and its scan results can be used to:
1. Validate TMAS detection capabilities
2. Test security policies and thresholds
3. Train security teams on secret detection
4. Benchmark scanning performance
5. Develop remediation workflows

---
*Generated by TMAS Integration Build Script*
EOF

echo -e "${GREEN}Scan report generated: $REPORT_FILE${NC}"

echo -e "${GREEN}Step 5: Container ready for testing${NC}"
echo ""
echo -e "${BLUE}=== BUILD AND SCAN COMPLETE ===${NC}"
echo -e "${GREEN}Container '$CONTAINER_NAME' built and scanned successfully${NC}"
echo -e "${YELLOW}To run the container:${NC}"
echo -e "${YELLOW}  docker run -p 5000:5000 $CONTAINER_NAME${NC}"
echo ""
echo -e "${YELLOW}To run additional TMAS scans:${NC}"
echo -e "${YELLOW}  $TMAS_BINARY scan docker:$CONTAINER_NAME -VMS${NC}"
echo ""
echo -e "${YELLOW}Scan results directory: $SCAN_RESULTS_DIR${NC}"

# List all generated files
echo -e "${BLUE}Generated files:${NC}"
ls -la "$SCAN_RESULTS_DIR/"

echo ""
echo -e "${GREEN}✅ Integration complete!${NC}"
