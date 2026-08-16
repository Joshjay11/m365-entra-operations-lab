# Phase 1 Runbook: Entra Aggregate Baseline

**Evidence state:** Lab execution and offline validation passed; administrator-portal cross-check pending.

## Purpose

Phase 1 creates a counts-only Microsoft Entra baseline without changing tenant configuration or publishing tenant identifiers. It collects:

- organization and verified-domain counts
- enabled, disabled, member, guest, synchronized, and cloud-only user counts
- security, Microsoft 365, dynamic, and other group counts
- aggregate subscribed, enabled, consumed, and available license units
- active and eligible privileged-role assignment counts

Conditional Access, devices, Intune, Exchange Online, Teams, SharePoint, and OneDrive are intentionally deferred to later phases.

## Safety boundary

The collector uses only `Get-*` Microsoft Graph PowerShell commands. It does not create, update, assign, revoke, disable, delete, migrate, or remediate anything.

The report contains counts and collection status only. It rejects output containing forbidden identity properties, GUID-like values, or email-like values. Real reports must remain under an ignored `output/` or `reports/` directory. Never move a real report into `samples/`.

## Delegated Microsoft Graph permissions

| Scope | Phase 1 use |
| --- | --- |
| `User.Read.All` | Organization summary and user properties |
| `Group.Read.All` | Group types and dynamic-membership state |
| `Organization.Read.All` | Subscribed SKU and aggregate license units |
| `RoleManagement.Read.Directory` | Active and eligible directory-role assignments |

These delegated scopes require administrator consent in most tenants. They allow directory discovery but do not grant write operations to this script.

## Prerequisites

1. Use PowerShell 7 if available. Windows PowerShell 5.1 is also supported by these Phase 1 scripts.
2. Confirm the execution policy:

   ```powershell
   Get-ExecutionPolicy -List
   ```

3. Install the stable Microsoft Graph PowerShell SDK in the PowerShell version you will use:

   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery
   ```

4. Confirm the installed module:

   ```powershell
   Get-InstalledModule Microsoft.Graph
   ```

The collector uses the stable Microsoft Graph v1.0 cmdlets. It does not require the beta module.

## Run the synthetic validation first

From the repository root:

```powershell
$Project = ".\projects\01-tenant-discovery-preflight"

& "$Project\scripts\Test-TenantDiscoveryPhase1Report.ps1" `
    -ReportPath "$Project\samples\tenant-baseline.synthetic.json"
```

Expected result:

```text
PASS: Phase 1 report structure, arithmetic, and sanitization checks succeeded.
```

## Collect the lab baseline

From the repository root:

```powershell
$Project = ".\projects\01-tenant-discovery-preflight"
$Output = "$Project\output\tenant-baseline.phase1.json"

& "$Project\scripts\Get-TenantDiscoveryPhase1.ps1" -OutputPath $Output
```

The script opens an interactive Microsoft Graph sign-in, requests the documented delegated scopes, writes the aggregate JSON report, and disconnects the process-scoped Graph session.

To use a Graph session you intentionally opened yourself:

```powershell
Connect-MgGraph -Scopes @(
    "User.Read.All",
    "Group.Read.All",
    "Organization.Read.All",
    "RoleManagement.Read.Directory"
) -ContextScope Process -NoWelcome

& "$Project\scripts\Get-TenantDiscoveryPhase1.ps1" `
    -OutputPath $Output `
    -UseExistingConnection

Disconnect-MgGraph
```

## Validate the lab report

```powershell
& "$Project\scripts\Test-TenantDiscoveryPhase1Report.ps1" -ReportPath $Output
```

Do not publish the real report. Record only the validation result, section status, count mismatches, and sanitized observations.

## Manual cross-check

Compare the aggregate report with these administrator views:

| Report section | Suggested control-plane check |
| --- | --- |
| Organization | Microsoft Entra admin center tenant properties and custom domain names |
| Identity | Entra ID users, including guest, account-state, and synchronization filters |
| Groups | Entra ID groups, including group type and membership type |
| Licensing | Microsoft 365 admin center billing and license inventory |
| Privileged access | Entra ID roles and administrators, plus PIM eligible assignments when licensed |

For every mismatch, record:

1. The report field and admin-center value.
2. The time each value was observed.
3. Whether eventual consistency, filtering, permissions, licensing, or object classification explains the difference.
4. The follow-up check required before treating the baseline as reliable.

## Expected limitations

- Eligible role assignments may be unavailable when the tenant lacks PIM capability or the signed-in account cannot read the schedule.
- Primary group categories are mutually exclusive: Microsoft 365 groups contain `Unified`; security groups are security-enabled groups without `Unified`; and all remaining groups are counted as other groups. A security-enabled Microsoft 365 group is counted only as a Microsoft 365 group.
- Dynamic groups can also be security or Microsoft 365 groups. `dynamicGroups` is an overlapping characteristic, not an additional group category.
- License availability can be negative when consumed units exceed enabled units.
- Counts may differ briefly from admin-center views because Graph and portal views can use different filters or update timing.

## Cleanup

1. Confirm the Graph session is disconnected with `Get-MgContext`.
2. Keep the real JSON report under the ignored `output/` directory.
3. Review `git status` and `git diff --staged` before any public commit.
4. Publish only synthetic or deliberately sanitized evidence.

## Authoritative references

- [Install the Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation)
- [Get-MgUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguser)
- [Get-MgGroup](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroup)
- [Get-MgSubscribedSku](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.directorymanagement/get-mgsubscribedsku)
- [Get-MgRoleManagementDirectoryRoleAssignment](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/get-mgrolemanagementdirectoryroleassignment)
- [Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/get-mgrolemanagementdirectoryroleeligibilityscheduleinstance)
