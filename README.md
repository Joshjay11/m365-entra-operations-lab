# Microsoft 365 and Entra Operations Lab

Sanitized Microsoft 365 and Microsoft Entra lab projects focused on tenant discovery, identity administration, migration readiness, operational safety, and repeatable troubleshooting.

This repository connects hands-on lab work to the work expected of a Microsoft 365, Modern Workplace, cloud systems, or identity engineer. It complements 17+ years of production IT experience across managed services, enterprise distribution, higher education, and multi-site support.

## Current flagship project

### 01 - Tenant Discovery and Migration Preflight

Design and build a read-only assessment that inventories the major identity and Microsoft 365 conditions an engineer should understand before taking ownership of a tenant or planning a migration.

**Current status:** The Phase 1 Entra aggregate collector was executed in a lab tenant and all five report sections completed. The offline structure, arithmetic, and sanitization validator passed, and the Graph session disconnected. Administrator-portal cross-check is pending; tenant-specific counts remain private.

The first release will produce an aggregate, redacted report covering:

- tenant and verified-domain readiness
- users, guests, synchronization state, and licensing
- groups and dynamic membership
- privileged role assignments
- Conditional Access policy state
- device identity and management posture
- Exchange Online and collaboration-workload readiness
- findings, limitations, and recommended follow-up checks

[Open the project blueprint](projects/01-tenant-discovery-preflight/README.md)

## What this repository is intended to demonstrate

- Microsoft 365 and Entra administrative reasoning
- PowerShell and Microsoft Graph PowerShell workflows
- least-privilege and read-only discovery patterns
- safe handling of tenant data
- migration discovery, validation, and rollback thinking
- clear runbooks, evidence boundaries, and troubleshooting notes
- the ability to explain why a control or check matters, not merely run a command

## Evidence standard

Every completed project will include:

1. A realistic administrative scenario.
2. Required permissions and safety boundaries.
3. A walkthrough written in plain language.
4. Scripts or configuration artifacts that can be inspected.
5. Sanitized sample output.
6. Validation steps and known limitations.
7. A short explanation of what was learned and what would change in production.

Course exercises and lab work are identified as practice. No lab is represented as a client production engagement, and no SC-300 certification is claimed until the exam is passed.

## Planned project sequence

| Project | Primary signal |
| --- | --- |
| Tenant discovery and migration preflight | M365 operations, Graph/PowerShell, migration readiness, documentation |
| Identity lifecycle automation | Users, groups, licensing, bulk operations, validation and rollback |
| Conditional Access and privileged access review | MFA, risk, PIM, least privilege, break-glass planning |
| Intune device-posture assessment | Enrollment, compliance, device identity, endpoint operations |
| Microsoft 365 migration runbook | Discovery, dependency mapping, cutover, validation, and stabilization |

See the [portfolio roadmap](docs/ROADMAP.md) for the learning and hiring rationale behind the sequence.

## Safety and privacy

This repository must never contain real tenant identifiers, user principal names, access tokens, secrets, certificates, customer names, raw exports, or production screenshots. Generated output is ignored by Git by default. Only synthetic or deliberately sanitized examples belong under `samples/`.

See [SECURITY.md](SECURITY.md) and the [evidence standard](docs/EVIDENCE-STANDARD.md).

## Professional direction

Jason Wiggins is targeting remote U.S. Microsoft 365, Modern Workplace, Entra ID/IAM, cloud systems, Intune, and migration engineering work, including contract, C2C, W2, and permanent opportunities.

- Website: [m365fixer.com](https://m365fixer.com/)
- Contact: [hello@m365fixer.com](mailto:hello@m365fixer.com)
- LinkedIn: [linkedin.com/in/wigginsjason](https://www.linkedin.com/in/wigginsjason)

## Authoritative references

- [Microsoft SC-300 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300)
- [Microsoft Graph PowerShell documentation](https://learn.microsoft.com/en-us/powershell/microsoftgraph/overview)
- [Microsoft 365 documentation](https://learn.microsoft.com/en-us/microsoft-365/)
