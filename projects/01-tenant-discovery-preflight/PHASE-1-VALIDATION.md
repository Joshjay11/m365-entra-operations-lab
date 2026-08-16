# Phase 1 Validation Record

**Current evidence state:** Design-only

**Lab execution status:** Not run

This record separates checks completed against the repository artifacts from checks that require Jason's Microsoft 365 lab tenant.

## Artifact checks

| Check | Result | Evidence |
| --- | --- | --- |
| Schema JSON parses | Pass | `tenant-baseline.schema.json` loaded successfully |
| Synthetic report JSON parses | Pass | `tenant-baseline.synthetic.json` loaded successfully |
| Synthetic report conforms to schema 0.2.0 | Pass | Required fields, types, constants, conditionals, and additional-property rules checked |
| Synthetic arithmetic reconciles | Pass | Identity, group, license, and privileged-access relationships checked |
| Relative Markdown links resolve | Pass | Repository-local documentation links checked |
| PowerShell delimiter and quote balance | Pass | Static source scan completed |
| PowerShell runtime parse | Not run | PowerShell was not available in the artifact-build environment |
| Microsoft Graph execution | Not run | Requires interactive access to Jason's lab tenant |

The artifact checks do not prove that the Microsoft Graph commands execute successfully in the lab. Runtime and tenant evidence remain pending.

## Runtime issue log

| Date | Environment | Observation | Correction | Retest |
| --- | --- | --- | --- | --- |
| 2026-08-16 | Windows PowerShell | The validator resolved a relative report path against the process start directory instead of PowerShell's current location. A later `ConvertFrom-Json -Depth` call would also have required PowerShell 7. | Resolve relative input and output paths against `Get-Location`, and use the Windows PowerShell-compatible `ConvertFrom-Json` form. | Pass: synthetic report validated on Windows PowerShell |
| 2026-08-16 | Microsoft Graph lab collection | A security-enabled Microsoft 365 group was counted in both the security and Microsoft 365 primary categories, so the report failed group-total reconciliation. | Treat `Unified` as the Microsoft 365 primary category first, and count only non-`Unified` security-enabled groups as security groups. | Pass: the regenerated report reconciled and passed the offline validator |
| 2026-08-16 | Microsoft Graph lab collection | The organization call succeeded, but the returned `verifiedDomain` objects do not define `IsVerified`; strict property access made the organization section unavailable. | Count the non-null objects already returned by the organization's `verifiedDomains` collection, and use only its documented `IsDefault` and `IsInitial` properties. | Pending |

## Lab execution record

Complete this section after following [`PHASE-1-RUNBOOK.md`](PHASE-1-RUNBOOK.md).

| Item | Result |
| --- | --- |
| Execution date in UTC | Pending |
| PowerShell version | Pending |
| Microsoft.Graph version | Pending |
| Stable Graph v1.0 profile used | Pending |
| Collector completed | Pending |
| Offline report validator passed | Pending |
| Graph session disconnected | Pending |

Do not record the tenant ID, tenant domain, signed-in account, user names, object IDs, or raw error text in this public file.

## Collection status

| Section | Status | Notes |
| --- | --- | --- |
| Organization and verified domains | Pending | Counts only |
| Users, guests, and synchronization | Pending | Counts only |
| Groups and dynamic membership | Pending | Counts only |
| Licensing | Pending | Aggregate units only |
| Active privileged assignments | Pending | Counts only |
| Eligible privileged assignments | Pending | Permission and PIM dependent |

## Portal cross-check

| Comparison | Result | Sanitized explanation of any mismatch |
| --- | --- | --- |
| Organization and custom domains | Pending | Pending |
| Users and guests | Pending | Pending |
| Account and synchronization state | Pending | Pending |
| Group types | Pending | Pending |
| License units | Pending | Pending |
| Active and eligible role assignments | Pending | Pending |

## Completion rule

Phase 1 can move from design-only to lab evidence only after:

1. The collector runs against the lab tenant.
2. The generated report passes the PowerShell validator.
3. Aggregate values are compared with the relevant administrator portals.
4. Mismatches and unavailable sections are explained.
5. The report is reviewed for identifiers before any sanitized excerpt is published.
