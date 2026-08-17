# Phase 2 Manual Review Checklist

Use this checklist only after the counts-only collector and offline validator pass. Complete the review in the administrator portals. Do not copy account names, user principal names, object IDs, policy names, tenant domains, or screenshots into public evidence.

## Emergency-access design

- [ ] At least two cloud-only emergency-access accounts are designated.
- [ ] Each account has a permanent active Global Administrator assignment.
- [ ] Each account is independent of on-premises federation and synchronization.
- [ ] Strong, phishing-resistant authentication is configured and recoverable.
- [ ] Credentials and authentication devices are stored under separate, controlled custody.
- [ ] Use and configuration changes generate monitored alerts.
- [ ] A recurring sign-in test is documented and produces private evidence.
- [ ] The organization has a tested recovery procedure for lost credentials or devices.

## Conditional Access exclusions

- [ ] Every enabled and report-only policy was checked for emergency-access impact.
- [ ] Emergency-access accounts are excluded from policies that could block or prevent recovery sign-in.
- [ ] Exclusions were verified by local object ID, not by display-name assumptions.
- [ ] User, group, and role exclusions have a documented operational reason.
- [ ] No broad exclusion silently bypasses more controls than intended.
- [ ] Policy changes are staged in report-only mode when practical.
- [ ] A rollback path and responsible operator are documented before enforcement.

## Authentication and privileged access

- [ ] MFA registered and MFA capable counts were compared with Registration details.
- [ ] Privileged accounts without an allowed strong method were reviewed privately.
- [ ] Passwordless-capable coverage was reviewed for administrators and recovery operators.
- [ ] PIM active and eligible assignments from Phase 1 were considered during the review.
- [ ] The emergency-access procedure does not depend on PIM activation.

## Identity risk

- [ ] Risky-user endpoint availability was recorded as available or unavailable.
- [ ] Risk-detection endpoint availability was recorded as available or unavailable.
- [ ] A successful zero-record result was not confused with an unavailable endpoint.
- [ ] License, permission, and directory-role limitations were recorded without raw error text.
- [ ] Any tenant-specific risk investigation remained private.

## Public completion record

Publish only these sanitized outcomes in `PHASE-2-VALIDATION.md`:

- collector and offline-validator Pass or Fail
- section status: Complete, Partial, or Unavailable
- manual comparison: Pass, Fail, Not applicable, or Blocked
- sanitized mismatch category and correction
- PowerShell and Microsoft.Graph versions
- confirmation that the Graph session disconnected

Do not publish counts, names, domains, identifiers, screenshots, or raw report content.
