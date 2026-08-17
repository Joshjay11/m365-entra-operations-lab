# Phase 2 Runbook: Access and Policy Posture

**Evidence state:** Design and synthetic validation ready; lab execution pending.

## Purpose

Phase 2 extends the read-only tenant baseline into Microsoft Entra access-policy posture. It collects:

- Conditional Access policy-state, targeting, exclusion, and grant-control counts
- authentication registration and capability counts
- risky-user and risk-detection endpoint availability plus aggregate record counts
- sanitized limitations when permission, role, report, or license dependencies prevent collection

Emergency-access account design and policy-exclusion correctness remain manual review items. The collector deliberately does not identify accounts, policies, groups, roles, or risk records.

## Safety boundary

The collector uses only `Get-*` Microsoft Graph PowerShell commands. It does not create, update, enable, disable, delete, assign, revoke, dismiss risk, or change Conditional Access.

The report contains counts, Boolean availability, collection status, and sanitized limitations only. It rejects forbidden identity properties, GUID-like values, and email-like values. Keep real reports under an ignored `output/` or `reports/` directory. Never move a real report into `samples/`.

## Delegated Microsoft Graph permissions

| Scope | Phase 2 use |
| --- | --- |
| `Policy.Read.All` | Read Conditional Access policies |
| `AuditLog.Read.All` | Read authentication registration details |
| `IdentityRiskyUser.Read.All` | Test risky-user availability and count returned records |
| `IdentityRiskEvent.Read.All` | Test risk-detection availability and count returned records |

The signed-in user also needs a supported Microsoft Entra directory role for each API. Global Reader and Security Reader cover the authentication registration and identity-risk reads. Conditional Access supports several read roles, including Global Reader and Security Reader. Licensing can still make a risk endpoint unavailable.

## Prerequisites

1. Use PowerShell 7 if available. Windows PowerShell 5.1 remains supported by the Phase 2 scripts.
2. Pull the current repository:

   ```powershell
   Set-Location C:\Dev\m365-entra-operations-lab
   git pull --ff-only
   ```

3. Confirm that the stable Graph commands are installed:

   ```powershell
   $Required = @(
       "Connect-MgGraph",
       "Disconnect-MgGraph",
       "Get-MgContext",
       "Get-MgIdentityConditionalAccessPolicy",
       "Get-MgReportAuthenticationMethodUserRegistrationDetail",
       "Get-MgRiskyUser",
       "Get-MgRiskDetection"
   )

   $Required | ForEach-Object {
       [pscustomobject]@{
           Command   = $_
           Available = [bool](Get-Command $_ -ErrorAction SilentlyContinue)
       }
   } | Format-Table -AutoSize
   ```

If a command is missing, update the stable SDK:

```powershell
Update-Module Microsoft.Graph
```

The Phase 2 implementation uses stable Microsoft Graph v1.0 cmdlets. It does not require the beta module.

## Run the synthetic validation first

From the repository root:

```powershell
$Project = ".\projects\01-tenant-discovery-preflight"

& "$Project\scripts\Test-TenantDiscoveryPhase2Report.ps1" `
    -ReportPath "$Project\samples\access-policy-posture.synthetic.json"
```

Expected result:

```text
PASS: Phase 2 report structure, arithmetic, availability, and sanitization checks succeeded.
```

## Collect the lab posture report

Use a timestamped file so a previous private report is not overwritten:

```powershell
$Project = ".\projects\01-tenant-discovery-preflight"
$Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$Output = "$Project\output\access-policy-posture.phase2.$Stamp.json"

& "$Project\scripts\Get-TenantDiscoveryPhase2.ps1" `
    -OutputPath $Output
```

The script opens an interactive Microsoft Graph sign-in, requests the documented delegated scopes, writes the aggregate JSON report, and disconnects its process-scoped Graph session.

To use a Graph session you intentionally opened yourself:

```powershell
Connect-MgGraph -Scopes @(
    "Policy.Read.All",
    "AuditLog.Read.All",
    "IdentityRiskyUser.Read.All",
    "IdentityRiskEvent.Read.All"
) -ContextScope Process -NoWelcome

& "$Project\scripts\Get-TenantDiscoveryPhase2.ps1" `
    -OutputPath $Output `
    -UseExistingConnection

Disconnect-MgGraph
```

## Validate and inspect the lab report

```powershell
& "$Project\scripts\Test-TenantDiscoveryPhase2Report.ps1" `
    -ReportPath $Output

$Report = Get-Content -LiteralPath $Output -Raw -Encoding UTF8 |
    ConvertFrom-Json

[pscustomobject]@{
    ConditionalAccess          = $Report.conditionalAccess.status
    AuthenticationRegistration = $Report.authenticationRegistration.status
    IdentityRisk               = $Report.identityRisk.status
    LimitationCount            = @($Report.limitations).Count
} | Format-List

if ($null -eq (Get-MgContext)) {
    "PASS: Microsoft Graph session disconnected."
}

git status --short
```

Do not publish the real report. Record only section status, validator result, sanitized limitations, portal comparison results, and runtime corrections.

## Manual cross-check

Compare the aggregate report with these administrator views:

| Report section | Suggested control-plane check |
| --- | --- |
| Conditional Access | Entra ID > Conditional Access > Policies, including On, Report-only, and Off states |
| Targeting and exclusions | Open each policy locally and compare all-user targeting plus user, group, and role exclusions |
| Grant controls | Compare MFA, authentication strength, block, compliant-device, and hybrid-join controls |
| Authentication registration | Entra ID > Authentication methods > Registration details |
| Risk availability | Entra ID Protection > Risky users and Risk detections, when licensed |
| Emergency access | Complete `PHASE-2-REVIEW-CHECKLIST.md` without publishing account or policy identifiers |

For every mismatch, record the field, observation time, likely explanation, and follow-up action. Keep all tenant-specific values and screenshots private.

## Interpretation limits

- Conditional Access characteristic counts overlap. A policy can target all users, contain exclusions, and require more than one grant control.
- Policy-state counts are the only mutually exclusive Conditional Access categories and must reconcile with `totalPolicies`.
- The authentication registration API does not return disabled users. `usersReported` is the number of returned registration records, not the Phase 1 tenant user total.
- MFA registered and MFA capable are different measures. A registered method may not be allowed by current policy.
- Risk endpoints depend on delegated permission, supported directory role, and Microsoft Entra ID Protection licensing. A zero count after a successful call is different from an unavailable endpoint.
- Aggregate counts cannot prove that an individual policy is correct or that an emergency-access account is usable.

## Cleanup

1. Confirm `Get-MgContext` returns no process-scoped session opened by the collector.
2. Keep the real JSON report under the ignored `output/` directory.
3. Review `git status` and `git diff --staged` before any public commit.
4. Publish only synthetic or deliberately sanitized evidence.

## Authoritative references

- [List Conditional Access policies](https://learn.microsoft.com/en-us/graph/api/conditionalaccessroot-list-policies?view=graph-rest-1.0)
- [Conditional Access policy resource](https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0)
- [Conditional Access users resource](https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessusers?view=graph-rest-1.0)
- [Conditional Access grant controls resource](https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessgrantcontrols?view=graph-rest-1.0)
- [List authentication registration details](https://learn.microsoft.com/en-us/graph/api/authenticationmethodsroot-list-userregistrationdetails?view=graph-rest-1.0)
- [Authentication registration details resource](https://learn.microsoft.com/en-us/graph/api/resources/userregistrationdetails?view=graph-rest-1.0)
- [List risky users](https://learn.microsoft.com/en-us/graph/api/riskyuser-list?view=graph-rest-1.0)
- [List risk detections](https://learn.microsoft.com/en-us/graph/api/riskdetection-list?view=graph-rest-1.0)
- [Manage emergency access accounts](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)
