# Project 01: Tenant Discovery and Migration Preflight

**Status:** Phase 1 lab execution and offline validation complete. Administrator-portal cross-check is next.

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
7. What device identity and management states are represented?
8. Which Exchange Online and collaboration-workload conditions require deeper discovery?
9. What cannot be concluded from the available permissions or licenses?

## Safety boundary

The initial implementation is read-only. It must not create, update, disable, delete, assign, revoke, migrate, or remediate anything.

Committed sample output is synthetic. Real output belongs in ignored local directories and must be reviewed before any excerpt is published.

## Phase 1 implementation

The first implementation uses stable Microsoft Graph v1.0 PowerShell cmdlets and produces counts plus collection status only.

| Artifact | Purpose |
| --- | --- |
| [`PHASE-1-RUNBOOK.md`](PHASE-1-RUNBOOK.md) | Prerequisites, permissions, execution, cross-check, and cleanup |
| [`PHASE-1-VALIDATION.md`](PHASE-1-VALIDATION.md) | Completed automated lab evidence, runtime corrections, and pending portal comparisons |
| [`Get-TenantDiscoveryPhase1.ps1`](scripts/Get-TenantDiscoveryPhase1.ps1) | Read-only aggregate collector with identifier checks |
| [`Test-TenantDiscoveryPhase1Report.ps1`](scripts/Test-TenantDiscoveryPhase1Report.ps1) | Offline structure, arithmetic, and sanitization validator |
| [`tenant-baseline.schema.json`](schema/tenant-baseline.schema.json) | Published Phase 1 report contract |
| [`tenant-baseline.synthetic.json`](samples/tenant-baseline.synthetic.json) | Fictional example that conforms to schema version 0.2.0 |

Delegated scopes:

- `User.Read.All`
- `Group.Read.All`
- `Organization.Read.All`
- `RoleManagement.Read.Directory`

The scripts are lab-executed evidence from Jason's own tenant. All five report sections completed, the offline validator passed, and the Graph session disconnected. No tenant-specific counts or identifiers are published. Administrator-portal comparison remains pending.

## Planned implementation phases

### Phase 1: Entra aggregate baseline

**Implementation status:** Script, validator, runbook, schema, and synthetic example are available. Lab execution and offline validation passed; administrator-portal comparison is pending.

- organization and verified-domain summary
- user and guest counts
- synchronization-state counts
- group-type counts
- subscribed and consumed license units
- privileged-role assignment counts
- synthetic sample report conforming to a published schema

### Phase 2: Access and policy posture

- Conditional Access policy-state counts
- authentication-method and risk-report availability
- emergency-access and exclusion review checklist
- explicit reporting of license- or permission-dependent gaps

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

The Phase 1 aggregate report conforms to [`tenant-baseline.schema.json`](schema/tenant-baseline.schema.json). A deliberately fictional example is provided at [`tenant-baseline.synthetic.json`](samples/tenant-baseline.synthetic.json).

Schema version 0.2.0 uses `null` plus a collection status when a section cannot be read. It does not use zero to mean "not collected."

## Validation plan

- validate module and command prerequisites
- record the connected tenant and granted scopes locally, never in committed output
- compare aggregate counts with the Entra and Microsoft 365 admin centers
- test behavior when optional permissions or licensed features are unavailable
- verify that default output contains no UPNs, object IDs, tenant IDs, or domain names
- disconnect Graph and service sessions after execution
- document actual results, mismatches, and limitations

## Walkthrough outcome

At completion, the operator should be able to explain what each discovery check reveals, which Microsoft control plane supplies the data, what permission is required, and why the result matters before a migration or operational handoff.
