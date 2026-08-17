# Project 01: Tenant Discovery and Migration Preflight

**Status:** Phase 1 complete and cross-checked. Phase 2 design and synthetic validation ready; lab execution pending.

## Scenario

An engineer is asked to take ownership of an inherited Microsoft 365 tenant or prepare it for a migration. Documentation is incomplete. The first requirement is to establish a reliable baseline without changing tenant configuration.

## Administrative questions

The assessment should answer:

1. What tenant and verified-domain conditions affect identity or mail readiness?
2. How many users, guests, synchronized identities, and cloud-only identities exist?
3. What group types and dynamic-membership patterns are present?
4. How are licenses consumed and where are obvious shortages or anomalies?
5. Which principals hold privileged roles?
6. What is the state of Conditional Access policies?
7. What authentication registration and identity-risk information is available?
8. What device identity and management states are represented?
9. Which Exchange Online and collaboration-workload conditions require deeper discovery?
10. What cannot be concluded from the available permissions, roles, reports, or licenses?

## Safety boundary

The implementation is read-only. It must not create, update, enable, disable, delete, assign, revoke, dismiss risk, migrate, or remediate anything.

Committed sample output is synthetic. Real output belongs in ignored local directories and must be reviewed before any excerpt is published.

## Phase 1 implementation

Phase 1 uses stable Microsoft Graph v1.0 PowerShell cmdlets and produces counts plus collection status only.

| Artifact | Purpose |
| --- | --- |
| [`PHASE-1-RUNBOOK.md`](PHASE-1-RUNBOOK.md) | Prerequisites, permissions, execution, cross-check, and cleanup |
| [`PHASE-1-VALIDATION.md`](PHASE-1-VALIDATION.md) | Completed automated and administrator-portal evidence |
| [`Get-TenantDiscoveryPhase1.ps1`](scripts/Get-TenantDiscoveryPhase1.ps1) | Read-only aggregate collector with identifier checks |
| [`Test-TenantDiscoveryPhase1Report.ps1`](scripts/Test-TenantDiscoveryPhase1Report.ps1) | Offline structure, arithmetic, and sanitization validator |
| [`tenant-baseline.schema.json`](schema/tenant-baseline.schema.json) | Published Phase 1 report contract |
| [`tenant-baseline.synthetic.json`](samples/tenant-baseline.synthetic.json) | Fictional example conforming to schema version 0.2.0 |

Delegated scopes:

- `User.Read.All`
- `Group.Read.All`
- `Organization.Read.All`
- `RoleManagement.Read.Directory`

The scripts are lab-executed evidence from Jason's own tenant. All five report sections completed, the offline validator passed, the Graph session disconnected, and all administrator-portal comparisons passed. No tenant-specific counts or identifiers are published.

## Phase 2 implementation

Phase 2 keeps the same counts-only evidence boundary while adding access and policy posture.

| Artifact | Purpose |
| --- | --- |
| [`PHASE-2-RUNBOOK.md`](PHASE-2-RUNBOOK.md) | Permissions, execution, validation, portal cross-check, and cleanup |
| [`PHASE-2-REVIEW-CHECKLIST.md`](PHASE-2-REVIEW-CHECKLIST.md) | Manual emergency-access, exclusion, authentication, and risk review |
| [`PHASE-2-VALIDATION.md`](PHASE-2-VALIDATION.md) | Artifact checks plus pending lab and portal evidence |
| [`Get-TenantDiscoveryPhase2.ps1`](scripts/Get-TenantDiscoveryPhase2.ps1) | Read-only Conditional Access, registration, and risk collector |
| [`Test-TenantDiscoveryPhase2Report.ps1`](scripts/Test-TenantDiscoveryPhase2Report.ps1) | Offline structure, arithmetic, availability, and sanitization validator |
| [`access-policy-posture.schema.json`](schema/access-policy-posture.schema.json) | Published Phase 2 report contract |
| [`access-policy-posture.synthetic.json`](samples/access-policy-posture.synthetic.json) | Fictional example conforming to schema version 0.1.0 |

Delegated scopes:

- `Policy.Read.All`
- `AuditLog.Read.All`
- `IdentityRiskyUser.Read.All`
- `IdentityRiskEvent.Read.All`

Risk reads are explicitly availability-aware. A successful zero-record result is recorded as zero, while a license-, role-, or permission-dependent failure is recorded as unavailable with a sanitized limitation.

## Planned implementation phases

### Phase 1: Entra aggregate baseline

**Implementation status:** Complete. Collector, validator, runbook, schema, synthetic example, lab execution, offline validation, and administrator-portal comparison passed.

- organization and verified-domain summary
- user and guest counts
- synchronization-state counts
- group-type counts
- subscribed and consumed license units
- privileged-role assignment counts
- synthetic sample report conforming to a published schema

### Phase 2: Access and policy posture

**Implementation status:** Collector, validator, runbook, schema, synthetic example, and manual checklist are ready. Lab execution and portal comparison are pending.

- Conditional Access policy-state and control counts
- authentication registration and capability counts
- risky-user and risk-detection availability
- emergency-access and exclusion review checklist
- explicit reporting of license-, role-, permission-, or report-dependent gaps

### Phase 3: Microsoft 365 workload preflight

- Exchange Online mailbox and accepted-domain summary
- Teams, SharePoint, and OneDrive discovery checklist
- DNS and mail-flow validation points
- migration dependency and follow-up findings

### Phase 4: Device and Intune posture

- registered, Entra joined, and hybrid joined counts
- managed, unmanaged, compliant, and noncompliant summaries
- stale-device criteria and follow-up list kept local

## Report design

Phase 1 conforms to [`tenant-baseline.schema.json`](schema/tenant-baseline.schema.json). Phase 2 conforms to [`access-policy-posture.schema.json`](schema/access-policy-posture.schema.json). Deliberately fictional examples are committed under [`samples/`](samples/).

Both report contracts use `null` plus collection status when data cannot be read. They do not use zero to mean "not collected."

## Validation plan

- validate module and command prerequisites
- record the connected tenant and granted scopes locally, never in committed output
- compare aggregate counts with the Entra and Microsoft 365 admin centers
- test behavior when optional permissions, roles, reports, or licensed features are unavailable
- verify that default output contains no UPNs, object IDs, tenant IDs, domains, policy names, or risk details
- disconnect Graph and service sessions after execution
- document actual results, mismatches, corrections, and limitations

## Walkthrough outcome

At completion, the operator should be able to explain what each discovery check reveals, which Microsoft control plane supplies the data, what permission and role are required, where licensing changes availability, and why the result matters before a migration or operational handoff.
