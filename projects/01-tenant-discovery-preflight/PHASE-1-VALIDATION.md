# Phase 1 Validation Record

**Current evidence state:** Lab-executed and administrator-portal cross-checked

**Lab execution status:** Collector and offline validator passed on Windows PowerShell; all portal comparisons passed

This record separates checks completed against the repository artifacts from completed comparisons against Jason's Microsoft 365 lab tenant.

## Artifact checks

| Check | Result | Evidence |
| --- | --- | --- |
| Schema JSON parses | Pass | `tenant-baseline.schema.json` loaded successfully |
| Synthetic report JSON parses | Pass | `tenant-baseline.synthetic.json` loaded successfully |
| Synthetic report conforms to schema 0.2.0 | Pass | Required fields, types, constants, conditionals, and additional-property rules checked |
| Synthetic arithmetic reconciles | Pass | Identity, group, license, and privileged-access relationships checked |
| Relative Markdown links resolve | Pass | Repository-local documentation links checked |
| PowerShell delimiter and quote balance | Pass | Static source scan completed |
| PowerShell runtime execution | Pass | Collector and validator executed with Windows PowerShell 5.1.26100.9168 |
| Microsoft Graph execution | Pass | Stable Microsoft.Graph 2.39.0 collector completed with all five report sections complete |

Automated lab execution and all six administrator-portal comparisons are verified. No tenant-specific counts or identifiers are published.

## Runtime issue log

| Date | Environment | Observation | Correction | Retest |
| --- | --- | --- | --- | --- |
| 2026-08-16 | Windows PowerShell | The validator resolved a relative report path against the process start directory instead of PowerShell's current location. A later `ConvertFrom-Json -Depth` call would also have required PowerShell 7. | Resolve relative input and output paths against `Get-Location`, and use the Windows PowerShell-compatible `ConvertFrom-Json` form. | Pass: synthetic report validated on Windows PowerShell |
| 2026-08-16 | Microsoft Graph lab collection | A security-enabled Microsoft 365 group was counted in both the security and Microsoft 365 primary categories, so the report failed group-total reconciliation. | Treat `Unified` as the Microsoft 365 primary category first, and count only non-`Unified` security-enabled groups as security groups. | Pass: the regenerated report reconciled and passed the offline validator |
| 2026-08-16 | Microsoft Graph lab collection | The organization call succeeded, but the returned `verifiedDomain` objects do not define `IsVerified`; strict property access made the organization section unavailable. | Count the non-null objects already returned by the organization's `verifiedDomains` collection, and use only its documented `IsDefault` and `IsInitial` properties. | Pass: organization collection completed and the regenerated report passed the offline validator |

## Lab execution record

| Item | Result |
| --- | --- |
| Execution date in UTC | 2026-08-16 |
| PowerShell version | Windows PowerShell 5.1.26100.9168 |
| Microsoft.Graph version | 2.39.0 |
| Stable Graph v1.0 profile used | Pass |
| Collector completed | Pass |
| Offline report validator passed | Pass |
| Graph session disconnected | Pass |

Do not record the tenant ID, tenant domain, signed-in account, user names, object IDs, or raw error text in this public file.

## Collection status

| Section | Status | Notes |
| --- | --- | --- |
| Organization and verified domains | Complete | Counts only; values not published |
| Users, guests, and synchronization | Complete | Counts only; values not published |
| Groups and dynamic membership | Complete | Counts only; values not published |
| Licensing | Complete | Aggregate units only; values not published |
| Active privileged assignments | Complete | Counts only; values not published |
| Eligible privileged assignments | Complete | Counts only; values not published |

## Portal cross-check

| Comparison | Result | Sanitized evidence |
| --- | --- | --- |
| Organization and custom domains | Pass | Aggregate organization and domain counts matched the administrator portal |
| Users and guests | Pass | Aggregate user, member, and guest counts matched the administrator portal |
| Account and synchronization state | Pass | Enabled, disabled, synchronized, and cloud-only counts matched the administrator portal |
| Group types | Pass | Aggregate total, security, Microsoft 365, and dynamic group counts matched the administrator portal |
| License units | Pass | Aggregate SKU, enabled, consumed, and available unit counts matched the administrator portal |
| Active and eligible role assignments | Pass | Aggregate active, eligible, and distinct-principal counts matched the PIM portal |

## Completion rule

Phase 1 is fully cross-checked:

1. Aggregate values were compared with the relevant administrator portals.
2. All six comparisons passed without an unexplained mismatch.
3. The real report remains private, and the public validation record contains no tenant-specific counts or identifiers.
