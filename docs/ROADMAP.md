# Portfolio roadmap

The roadmap is ordered by hiring value, learning value, and the ability to demonstrate safe engineering judgment in a public repository.

## 1. Tenant discovery and migration preflight

**Why first:** Current Microsoft 365 and Modern Workplace roles repeatedly ask for tenant discovery, Exchange Online, Teams, SharePoint, OneDrive, Entra ID, Intune, PowerShell, migration planning, validation, and clear documentation.

**What it demonstrates:** Broad tenant awareness, read-only Graph and service administration, risk identification, migration thinking, and report design.

**SC-300 connection:** Tenant configuration, users, groups, domains, roles, authentication, risk, workload identities, privileged access, and monitoring.

## 2. Identity lifecycle automation

**Scenario:** Provision, update, disable, and validate a controlled set of synthetic lab users and groups from a structured input file.

**Engineering requirements:** Plan mode, input validation, least privilege, idempotency, error handling, audit output, and documented rollback.

**What it demonstrates:** Microsoft Graph PowerShell, identity lifecycle work, bulk operations, licensing logic, and safe automation.

## 3. Conditional Access and privileged access review

**Scenario:** Review an existing lab design for gaps involving MFA, legacy authentication, sign-in risk, user risk, exclusions, emergency-access accounts, and privileged-role activation.

**Engineering requirements:** Read-only inventory first, documented policy intent, dependency checks, staged enforcement, and rollback criteria.

**What it demonstrates:** Conditional Access reasoning, PIM, Zero Trust, least privilege, risk controls, and change safety.

## 4. Intune device-posture assessment

**Scenario:** Compare registered, Entra joined, and hybrid joined devices and summarize enrollment, ownership, compliance, and management state.

**Engineering requirements:** Aggregate reporting, stale-device criteria, exception handling, and no device actions during discovery.

**What it demonstrates:** Device identity, Intune operations, endpoint governance, and the relationship between identity and device controls.

## 5. Microsoft 365 migration runbook

**Scenario:** Produce a vendor-neutral migration plan for a small multi-site organization moving collaboration and identity workloads into Microsoft 365 or between tenants.

**Engineering requirements:** Discovery, dependency mapping, coexistence, pilot selection, communications, cutover, validation, rollback, and post-migration stabilization.

**What it demonstrates:** Exchange Online, SharePoint, OneDrive, Teams, identity, DNS, stakeholder coordination, operational documentation, and migration judgment.

## Release rule

Only one project is active at a time. A project is marked complete only after its scripts or artifacts have been run in a lab, its output has been sanitized, and its validation notes accurately describe what passed and what remains untested.

