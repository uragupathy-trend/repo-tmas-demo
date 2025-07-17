# TMAS Policy Evaluation Integration

This document explains the TMAS (Trend Micro Artifact Scanner) policy evaluation integration implemented in the GitHub Actions workflow.

## Overview

The workflow now includes **TMAS Policy Evaluation** that uses Vision One's centralized policy configuration to automatically block merges and deployments when security policy violations are detected, specifically focusing on secrets detection.

## Key Features

### 🛡️ Policy Enforcement
- **Hard Blocking**: Workflow fails immediately when policy violations are detected
- **Vision One Integration**: Uses policies configured in the Vision One TMAS console
- **Secrets Focus**: Specifically evaluates secrets detection policies
- **Merge Protection**: Integrates with GitHub branch protection rules

### 🔍 Policy Evaluation Step
```yaml
- name: TMAS Policy Evaluation - Secrets (Blocking)
  env:
    TMAS_API_KEY: ${{ secrets.TMAS_API_KEY }}
  run: |
    ./tmas scan docker:${{ env.CONTAINER_NAME }}:latest \
      --secrets \
      --evaluatePolicy \
      --region ap-southeast-2 \
      --verbose > policy-evaluation-results.json
```

## How It Works

### 1. **Policy Configuration**
- Policies are configured centrally in the **Vision One TMAS console**
- No local policy files needed - uses `--evaluatePolicy` flag
- Policies determine when to return "block" vs "allow" results

### 2. **Workflow Integration**
- Runs after comprehensive scans (maintains detailed reporting)
- Uses dedicated policy evaluation step for enforcement
- Blocks workflow execution on policy violations
- Provides clear feedback and remediation guidance

### 3. **Policy Results**
The policy evaluation returns detailed results with specific violation types:

#### ✅ **COMPLIANT** - Policy Passed
- No policy violations detected
- Workflow continues normally
- Merge/deployment allowed

#### ❌ **IN-VIOLATION-OF-LOG-AND-BLOCK-RULES** - Policy Violations Detected
- Contains both blocking and/or log-only violations
- **Blocking Violations**: Workflow fails immediately, merge/deployment blocked
- **Log-Only Violations**: Workflow continues, but violations are logged for review
- Detailed breakdown of violation types and counts provided

#### ⚠️ **UNKNOWN** - Unclear Result
- Unable to determine policy result
- Manual review recommended
- Workflow may continue with warnings

## Implementation Details

### Policy Response Structure
The TMAS policy evaluation returns a detailed response structure:
```json
{
  "policyEvaluation": {
    "result": "in-violation-of-log-and-block-rules",
    "policyEvaluated": {
      "name": "Default Policy",
      "version": 8,
      "updatedDateTime": "2025-07-15T02:44:30Z"
    },
    "blockPolicyViolations": {
      "secrets": [
        {
          "rule": {
            "ruleType": "hasSecrets",
            "action": "block"
          },
          "numOfViolations": 57
        }
      ]
    },
    "logPolicyViolations": {
      "malware": [
        {
          "rule": {
            "ruleType": "unscannedArtifactMalware",
            "action": "log"
          }
        }
      ]
    }
  }
}
```

### Policy Evaluation Logic
```bash
# Extract policy evaluation details
POLICY_RESULT=$(jq -r '.policyEvaluation.result // "unknown"' policy-evaluation-results.json)
POLICY_NAME=$(jq -r '.policyEvaluation.policyEvaluated.name // "Unknown Policy"' policy-evaluation-results.json)
POLICY_VERSION=$(jq -r '.policyEvaluation.policyEvaluated.version // "Unknown"' policy-evaluation-results.json)

# Check for blocking violations
BLOCK_VIOLATIONS_COUNT=$(jq -r '.policyEvaluation.blockPolicyViolations | length' policy-evaluation-results.json)
SECRET_VIOLATIONS=$(jq -r '.policyEvaluation.blockPolicyViolations.secrets[0].numOfViolations // 0' policy-evaluation-results.json)

# Block workflow only on actual blocking violations
if [ "$POLICY_RESULT" = "in-violation-of-log-and-block-rules" ] && [ "$BLOCK_VIOLATIONS_COUNT" -gt 0 ]; then
  echo "❌ POLICY VIOLATION: $SECRET_VIOLATIONS secrets detected - Merge blocked"
  exit 1  # This fails the workflow
fi
```

### Workflow Structure
1. **Build & Scan Steps** - Generate detailed reports (continue-on-error: true)
2. **Policy Evaluation** - Enforce blocking (no continue-on-error)
3. **Results Processing** - Upload artifacts and generate summaries
4. **PR Comments** - Include policy status in PR feedback

## Configuration Requirements

### Vision One Console Setup
1. **Access Vision One TMAS Console**
2. **Configure Secrets Detection Policy**
   - Set policy to "block" when secrets are detected
   - Define severity thresholds
   - Configure exception handling

### GitHub Repository Setup
1. **Required Secret**: `TMAS_API_KEY` - Vision One API key
2. **Branch Protection**: Enable required status checks
3. **Workflow Permissions**: Ensure proper permissions for PR comments

## Special Handling for Test Container

Since this repository contains a test container with intentional fake secrets:

### Current Behavior
- Policy evaluation runs without overrides by default
- May block on detection of test secrets
- Provides clear indication this is expected for test scenarios

### Override Options
If needed, the policy evaluation step can be modified to include overrides:
```yaml
./tmas scan docker:${{ env.CONTAINER_NAME }}:latest \
  --secrets \
  --evaluatePolicy \
  --override tmas_overrides.yml \  # Add this line if needed
  --region ap-southeast-2 \
  --verbose > policy-evaluation-results.json
```

## Monitoring and Reporting

### GitHub Actions Summary
- Policy evaluation results displayed in workflow summary
- Clear status indicators (✅ PASS, ❌ BLOCK, ⚠️ UNKNOWN)
- Remediation guidance for policy violations

### PR Comments
- Policy status prominently displayed in PR comments
- Integration with existing scan result summaries
- Clear indication when PRs are blocked

### Artifacts
- Policy evaluation results saved as `policy-evaluation-results.json`
- Available for download and further analysis
- Retained for 30 days with other scan results

## Troubleshooting

### Common Issues

#### Policy Always Blocks
- **Cause**: Vision One policy configured too strictly
- **Solution**: Review and adjust policy in Vision One console

#### Policy Never Blocks
- **Cause**: Policy not configured or too permissive
- **Solution**: Verify policy configuration in Vision One

#### Unknown Policy Result
- **Cause**: API issues or malformed response
- **Solution**: Check API connectivity and TMAS CLI version

### Debug Steps
1. **Check Vision One Console**: Verify policy configuration
2. **Review Workflow Logs**: Examine policy evaluation step output
3. **Download Artifacts**: Analyze `policy-evaluation-results.json`
4. **Test TMAS CLI**: Run policy evaluation locally

## Best Practices

### Policy Configuration
- **Start Permissive**: Begin with warnings, gradually enforce blocking
- **Test Thoroughly**: Validate policy behavior in test environments
- **Document Exceptions**: Clearly document any policy overrides

### Workflow Management
- **Monitor Failures**: Track policy violation trends
- **Regular Reviews**: Periodically review and update policies
- **Team Training**: Ensure team understands policy requirements

### Security Considerations
- **API Key Security**: Protect TMAS API key as repository secret
- **Policy Governance**: Establish clear policy change approval process
- **Audit Trail**: Maintain logs of policy violations and resolutions

## Integration with Existing Features

### Maintains Compatibility
- ✅ All existing scan functionality preserved
- ✅ Detailed reporting continues to work
- ✅ Override system still functional
- ✅ PR comments enhanced with policy status
- ✅ Artifact uploads include policy results

### Enhanced Security
- 🛡️ Automated policy enforcement
- 🚫 Hard blocking on violations
- 📊 Centralized policy management
- 🔍 Clear violation reporting
- 📈 Policy compliance tracking

## Next Steps

1. **Configure Vision One Policy** - Set up appropriate secrets detection policy
2. **Test Policy Behavior** - Validate blocking and allowing scenarios
3. **Enable Branch Protection** - Configure required status checks
4. **Monitor and Adjust** - Fine-tune policy based on results
5. **Team Training** - Educate team on new policy enforcement

---

For questions or issues with TMAS policy evaluation, refer to:
- [Vision One Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-tmas-about)
- [TMAS CLI Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-tmas-cli)
- Repository maintainers for workflow-specific questions
