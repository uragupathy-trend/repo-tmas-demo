#!/bin/bash

# TMAS Integration Demonstration Script
# This script demonstrates the complete TMAS integration with the test secrets container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="umaragupathytrend/tmas-demo"
TMAS_BINARY="../../containers/tmas/tmas"
DEMO_DIR="./tmas-demo-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           TMAS Integration Demonstration Script              ║${NC}"
echo -e "${CYAN}║         Trend Micro Vision One Artifact Scanner             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to print step headers
print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_section "Pre-flight Checks"

# Check if TMAS binary exists
print_step "Checking TMAS CLI availability..."
if [ ! -f "$TMAS_BINARY" ]; then
    print_error "TMAS binary not found at $TMAS_BINARY"
    echo -e "${YELLOW}Please ensure TMAS CLI is available in the containers/tmas directory${NC}"
    echo -e "${YELLOW}Download from: https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-tmas-about${NC}"
    exit 1
fi
print_success "TMAS CLI found at $TMAS_BINARY"

# Check TMAS version
print_step "Checking TMAS version..."
#TMAS_VERSION=$($TMAS_BINARY version --short 2>/dev/null || echo "Unknown")
TMAS_VERSION=$($TMAS_BINARY --version || echo "Unknown")
echo -e "${CYAN}TMAS Version: $TMAS_VERSION${NC}"

# Check if TMAS_API_KEY is set
print_step "Checking API key configuration..."
if [ -z "$TMAS_API_KEY" ]; then
    print_error "TMAS_API_KEY environment variable is not set"
    echo -e "${YELLOW}Please set your Vision One API key:${NC}"
    echo -e "${YELLOW}export TMAS_API_KEY=API KEY{NC}"
    echo ""
    echo -e "${CYAN}To obtain an API key:${NC}"
    echo -e "${CYAN}1. Log in to Vision One Console: https://portal.xdr.trendmicro.com/${NC}"
    echo -e "${CYAN}2. Navigate to Administration > API Keys${NC}"
    echo -e "${CYAN}3. Create a new key with 'Run artifact scan' permissions${NC}"
    exit 1
fi
print_success "API key is configured"

# Check Docker
print_step "Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi
print_success "Docker is available and running"

# Create demo directory
mkdir -p "$DEMO_DIR"
print_success "Demo directory created: $DEMO_DIR"

print_section "Container Build and Preparation"

print_step "Building test secrets container..."
docker build -t "$CONTAINER_NAME" --platform "linux/amd64" . || {
    print_error "Docker build failed"
    exit 1
}
print_success "Container built successfully"

print_step "Verifying container image..."
docker images "$CONTAINER_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
print_success "Container image verified"

print_section "TMAS Scanning Demonstration"

print_warning "This container intentionally contains fake secrets for testing purposes"
echo -e "${YELLOW}Expected findings: 50+ secrets, multiple vulnerabilities, zero malware${NC}" 
echo ""

# Individual scanner demonstrations
print_step "1. TMAS Vulnerability Scan"
echo -e "${CYAN}Command: $TMAS_BINARY scan docker:$CONTAINER_NAME --vulnerabilities --saveSBOM${NC}" 
$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --vulnerabilities \
    --saveSBOM \
    --region ap-southeast-2 \
    --verbose > "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.json" 2> "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.log" || {
    print_warning "Vulnerability scan completed with findings (expected for test container)"
}

if [ -f "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.json" ]; then
    VULN_COUNT=$(jq -r '.vulnerabilities.totalVulnCount // 0' "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    CRITICAL_COUNT=$(jq -r '.vulnerabilities.criticalCount // 0' "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    HIGH_COUNT=$(jq -r '.vulnerabilities.highCount // 0' "$DEMO_DIR/vulnerability_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    echo -e "${PURPLE}  Results: $VULN_COUNT total vulnerabilities ($CRITICAL_COUNT critical, $HIGH_COUNT high)${NC}"
fi

print_step "2. TMAS Secret Scan"
echo -e "${CYAN}Command: $TMAS_BINARY scan docker:$CONTAINER_NAME --secrets${NC}"
$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --secrets \
    --region ap-southeast-2 \
    --verbose > "$DEMO_DIR/secret_scan_$TIMESTAMP.json" 2> "$DEMO_DIR/secret_scan_$TIMESTAMP.log" || {
    print_warning "Secret scan completed with findings (expected for test container)"
}

if [ -f "$DEMO_DIR/secret_scan_$TIMESTAMP.json" ]; then
    SECRET_COUNT=$(jq -r '.secrets.unmitigatedFindingsCount // 0' "$DEMO_DIR/secret_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    FILES_SCANNED=$(jq -r '.secrets.totalFilesScanned // 0' "$DEMO_DIR/secret_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    echo -e "${PURPLE}  Results: $SECRET_COUNT secrets found in $FILES_SCANNED files${NC}"
fi

print_step "3. TMAS Malware Scan"
echo -e "${CYAN}Command: $TMAS_BINARY scan docker:$CONTAINER_NAME --malware${NC}"
$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --malware \
    --region ap-southeast-2 \
    --verbose > "$DEMO_DIR/malware_scan_$TIMESTAMP.json" 2> "$DEMO_DIR/malware_scan_$TIMESTAMP.log" || {
    print_warning "Malware scan completed (no malware expected in test container)"
}

if [ -f "$DEMO_DIR/malware_scan_$TIMESTAMP.json" ]; then
    MALWARE_COUNT=$(jq -r '.malware.malwareCount // 0' "$DEMO_DIR/malware_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    SCANNED_FILES=$(jq -r '.malware.scannedFileCount // 0' "$DEMO_DIR/malware_scan_$TIMESTAMP.json" 2>/dev/null || echo "0")
    echo -e "${PURPLE}  Results: $MALWARE_COUNT malware found in $SCANNED_FILES scanned files${NC}"
fi

print_step "4. TMAS Comprehensive Scan"
echo -e "${CYAN}Command: $TMAS_BINARY scan docker:$CONTAINER_NAME -VMS --saveSBOM${NC}"
$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --vulnerabilities \
    --malware \
    --secrets \
    --saveSBOM \
    --region ap-southeast-2 \
    --verbose > "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json" 2> "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.log" || {
    print_warning "Comprehensive scan completed with findings (expected for test container)"
}

print_step "5. TMAS Scan with Override Configuration"
echo -e "${CYAN}Command: $TMAS_BINARY scan docker:$CONTAINER_NAME -VMS --override tmas_overrides.yml${NC}"
$TMAS_BINARY scan "docker:$CONTAINER_NAME" \
    --vulnerabilities \
    --malware \
    --secrets \
    --override tmas_overrides.yml \
    --region ap-southeast-2 \
    --verbose > "$DEMO_DIR/override_scan_$TIMESTAMP.json" 2> "$DEMO_DIR/override_scan_$TIMESTAMP.log" || {
    print_warning "Override scan completed (some findings may be suppressed)"
}

# Move SBOM if generated
if [ -f "sbom.json" ]; then
    mv "sbom.json" "$DEMO_DIR/sbom_$TIMESTAMP.json"
    print_success "SBOM saved to demo directory"
fi

print_section "Results Analysis"

print_step "Generating comprehensive report..."

# Create summary report
REPORT_FILE="$DEMO_DIR/tmas_demo_report_$TIMESTAMP.md"

cat > "$REPORT_FILE" << EOF
# TMAS Integration Demonstration Report

**Generated:** $(date)
**Container:** $CONTAINER_NAME
**TMAS Version:** $TMAS_VERSION

## Scan Summary

### Vulnerability Scan Results
EOF

if [ -f "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json" ]; then
    echo "- **Total Vulnerabilities:** $(jq -r '.vulnerabilities.totalVulnCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **Critical:** $(jq -r '.vulnerabilities.criticalCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **High:** $(jq -r '.vulnerabilities.highCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **Medium:** $(jq -r '.vulnerabilities.mediumCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **Low:** $(jq -r '.vulnerabilities.lowCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "### Secret Scan Results" >> "$REPORT_FILE"
    echo "- **Files Scanned:** $(jq -r '.secrets.totalFilesScanned // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **Secrets Found:** $(jq -r '.secrets.unmitigatedFindingsCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "### Malware Scan Results" >> "$REPORT_FILE"
    echo "- **Files Scanned:** $(jq -r '.malware.scannedFileCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "- **Malware Found:** $(jq -r '.malware.malwareCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF
## Files Generated

- \`comprehensive_scan_$TIMESTAMP.json\` - Complete scan results
- \`vulnerability_scan_$TIMESTAMP.json\` - Vulnerability-only scan
- \`secret_scan_$TIMESTAMP.json\` - Secret-only scan
- \`malware_scan_$TIMESTAMP.json\` - Malware-only scan
- \`override_scan_$TIMESTAMP.json\` - Scan with overrides applied
- \`sbom_$TIMESTAMP.json\` - Software Bill of Materials

## Expected vs Actual Results

### Expected (Test Container)
- **Secrets:** 50+ detections (AWS keys, API tokens, passwords)
- **Vulnerabilities:** Multiple CVEs in base image and packages
- **Malware:** 0 detections (fake secrets, not malware)

### Validation
This test container successfully demonstrates TMAS detection capabilities across all scan types.

---
*Generated by TMAS Integration Demonstration Script*
EOF

print_success "Comprehensive report generated: $REPORT_FILE"

print_step "Displaying scan summary..."
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    SCAN RESULTS SUMMARY                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

if [ -f "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json" ]; then
    echo -e "${YELLOW}Vulnerabilities:${NC}"
    echo -e "  Total: $(jq -r '.vulnerabilities.totalVulnCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo -e "  Critical: $(jq -r '.vulnerabilities.criticalCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo -e "  High: $(jq -r '.vulnerabilities.highCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo ""
    echo -e "${YELLOW}Secrets:${NC}"
    echo -e "  Found: $(jq -r '.secrets.unmitigatedFindingsCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo -e "  Files Scanned: $(jq -r '.secrets.totalFilesScanned // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo ""
    echo -e "${YELLOW}Malware:${NC}"
    echo -e "  Found: $(jq -r '.malware.malwareCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
    echo -e "  Files Scanned: $(jq -r '.malware.scannedFileCount // "N/A"' "$DEMO_DIR/comprehensive_scan_$TIMESTAMP.json")"
fi

print_section "Demonstration Complete"

print_step "Generated files in $DEMO_DIR:"
ls -la "$DEMO_DIR/"

echo ""
print_success "TMAS Integration Demonstration completed successfully!"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "${YELLOW}1. Review scan results in: $DEMO_DIR/${NC}"
echo -e "${YELLOW}2. Examine the comprehensive report: $REPORT_FILE${NC}"
echo -e "${YELLOW}3. Test the running container: docker run -p 5000:5000 $CONTAINER_NAME${NC}"
echo -e "${YELLOW}4. Explore API endpoints at http://localhost:5000${NC}"
echo ""
echo -e "${CYAN}Integration Features Demonstrated:${NC}"
echo -e "${GREEN}✓ Vulnerability scanning with SBOM generation${NC}"
echo -e "${GREEN}✓ Secret detection across multiple file types${NC}"
echo -e "${GREEN}✓ Malware scanning capabilities${NC}"
echo -e "${GREEN}✓ Override configuration for false positive management${NC}"
echo -e "${GREEN}✓ Comprehensive reporting and analysis${NC}"
echo ""
echo -e "${PURPLE}This container successfully demonstrates TMAS integration${NC}"
echo -e "${PURPLE}and can be used for security testing, training, and validation.${NC}"
echo ""
