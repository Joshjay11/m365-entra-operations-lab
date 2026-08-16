[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Condition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-PropertySet {
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string[]]$ExpectedProperties,

        [Parameter(Mandatory)]
        [string]$SectionName
    )

    $actual = @($InputObject.PSObject.Properties.Name | Sort-Object)
    $expected = @($ExpectedProperties | Sort-Object)

    $propertySetsMatch = ($actual -join "|") -eq ($expected -join "|")
    Assert-Condition -Condition $propertySetsMatch -Message "$SectionName contains missing or unexpected properties."
}

function Assert-NullableNonNegativeInteger {
    param(
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [string]$FieldName
    )

    if ($null -eq $Value) {
        return
    }

    $isInteger = $Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64]
    Assert-Condition -Condition $isInteger -Message "$FieldName must be an integer or null."
    Assert-Condition -Condition ($Value -ge 0) -Message "$FieldName cannot be negative."
}

$reportPathCandidate = if ([System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath
}
else {
    Join-Path -Path (Get-Location).Path -ChildPath $ReportPath
}
$fullReportPath = [System.IO.Path]::GetFullPath($reportPathCandidate)
Assert-Condition -Condition (Test-Path -LiteralPath $fullReportPath -PathType Leaf) -Message "Report file not found."

$rawJson = Get-Content -LiteralPath $fullReportPath -Raw -Encoding utf8
$report = $rawJson | ConvertFrom-Json

Assert-PropertySet -InputObject $report -SectionName "root" -ExpectedProperties @(
    "metadata",
    "organization",
    "identity",
    "groups",
    "licensing",
    "privilegedAccess",
    "limitations"
)

Assert-PropertySet -InputObject $report.metadata -SectionName "metadata" -ExpectedProperties @(
    "schemaVersion",
    "generatedAtUtc",
    "evidenceType",
    "phase",
    "graphApiProfile"
)

Assert-Condition -Condition ($report.metadata.schemaVersion -eq "0.2.0") -Message "Unexpected schema version."
Assert-Condition -Condition ($report.metadata.phase -eq "phase-1") -Message "Unexpected project phase."
Assert-Condition -Condition ($report.metadata.graphApiProfile -eq "v1.0") -Message "Only the stable Microsoft Graph v1.0 profile is accepted."
Assert-Condition -Condition ($report.metadata.evidenceType -in @("synthetic", "sanitized-lab")) -Message "Unexpected evidence type."

$generatedAt = [datetimeoffset]::MinValue
$dateIsValid = [datetimeoffset]::TryParse($report.metadata.generatedAtUtc, [ref]$generatedAt)
Assert-Condition -Condition $dateIsValid -Message "generatedAtUtc is not a valid date-time."

$sectionDefinitions = [ordered]@{
    organization = @("organizations", "verifiedDomains", "defaultDomains", "initialDomains")
    identity = @(
        "totalUsers",
        "enabledUsers",
        "disabledUsers",
        "unknownAccountStateUsers",
        "memberUsers",
        "guestUsers",
        "unknownUserTypeUsers",
        "syncedUsers",
        "cloudOnlyUsers"
    )
    groups = @("totalGroups", "securityGroups", "microsoft365Groups", "dynamicGroups", "otherGroups")
    licensing = @("subscribedSkus", "enabledUnits", "consumedUnits", "availableUnits")
    privilegedAccess = @("activeAssignments", "eligibleAssignments", "uniquePrivilegedPrincipals")
}

foreach ($sectionName in $sectionDefinitions.Keys) {
    $section = $report.$sectionName
    $countFields = $sectionDefinitions[$sectionName]

    Assert-PropertySet -InputObject $section -SectionName $sectionName -ExpectedProperties (@("status") + $countFields)

    $allowedStatuses = if ($sectionName -eq "privilegedAccess") {
        @("complete", "partial", "unavailable")
    }
    else {
        @("complete", "unavailable")
    }
    Assert-Condition -Condition ($section.status -in $allowedStatuses) -Message "$sectionName has an invalid collection status."

    foreach ($field in $countFields) {
        if ($sectionName -eq "licensing" -and $field -eq "availableUnits") {
            $value = $section.$field
            $availableUnitsIsValid = $null -eq $value -or $value -is [byte] -or $value -is [int16] -or $value -is [int32] -or $value -is [int64]
            Assert-Condition -Condition $availableUnitsIsValid -Message "licensing.availableUnits must be an integer or null."
        }
        else {
            Assert-NullableNonNegativeInteger -Value $section.$field -FieldName "$sectionName.$field"
        }
    }

    if ($section.status -eq "complete") {
        foreach ($field in $countFields) {
            Assert-Condition -Condition ($null -ne $section.$field) -Message "$sectionName.$field cannot be null when status is complete."
        }
    }

    if ($section.status -eq "unavailable") {
        foreach ($field in $countFields) {
            Assert-Condition -Condition ($null -eq $section.$field) -Message "$sectionName.$field must be null when status is unavailable."
        }
    }
}

if ($report.privilegedAccess.status -eq "partial") {
    $hasPartialRoleCount = $null -ne $report.privilegedAccess.activeAssignments -or $null -ne $report.privilegedAccess.eligibleAssignments
    Assert-Condition -Condition $hasPartialRoleCount -Message "A partial privileged-access result must include at least one assignment count."
    Assert-Condition -Condition ($null -eq $report.privilegedAccess.uniquePrivilegedPrincipals) -Message "Unique privileged principals must be null when privileged-access collection is partial."
}

if ($report.identity.status -eq "complete") {
    $accountStateTotal = $report.identity.enabledUsers + $report.identity.disabledUsers + $report.identity.unknownAccountStateUsers
    Assert-Condition -Condition ($report.identity.totalUsers -eq $accountStateTotal) -Message "Identity account-state counts do not reconcile with totalUsers."

    $userTypeTotal = $report.identity.memberUsers + $report.identity.guestUsers + $report.identity.unknownUserTypeUsers
    Assert-Condition -Condition ($report.identity.totalUsers -eq $userTypeTotal) -Message "Identity user-type counts do not reconcile with totalUsers."

    $syncStateTotal = $report.identity.syncedUsers + $report.identity.cloudOnlyUsers
    Assert-Condition -Condition ($report.identity.totalUsers -eq $syncStateTotal) -Message "Identity synchronization counts do not reconcile with totalUsers."
}

if ($report.groups.status -eq "complete") {
    $primaryGroupTypeTotal = $report.groups.securityGroups + $report.groups.microsoft365Groups + $report.groups.otherGroups
    Assert-Condition -Condition ($report.groups.totalGroups -eq $primaryGroupTypeTotal) -Message "Primary group-type counts do not reconcile with totalGroups."
}

if ($report.licensing.status -eq "complete") {
    $calculatedAvailableUnits = $report.licensing.enabledUnits - $report.licensing.consumedUnits
    Assert-Condition -Condition ($report.licensing.availableUnits -eq $calculatedAvailableUnits) -Message "License-unit arithmetic does not reconcile."
}

if ($report.privilegedAccess.status -eq "complete") {
    $assignmentTotal = $report.privilegedAccess.activeAssignments + $report.privilegedAccess.eligibleAssignments
    Assert-Condition -Condition ($report.privilegedAccess.uniquePrivilegedPrincipals -le $assignmentTotal) -Message "Unique privileged principals exceed the assignment total."
}

$forbiddenPropertyPatterns = @(
    '"id"\s*:',
    '"tenantId"\s*:',
    '"displayName"\s*:',
    '"userPrincipalName"\s*:',
    '"domainName"\s*:',
    '"skuPartNumber"\s*:'
)

foreach ($pattern in $forbiddenPropertyPatterns) {
    Assert-Condition -Condition ($rawJson -notmatch $pattern) -Message "A forbidden property was detected."
}

$guidPattern = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b'
$emailPattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'

Assert-Condition -Condition ($rawJson -notmatch $guidPattern) -Message "A GUID-like identifier was detected."
Assert-Condition -Condition ($rawJson -notmatch $emailPattern) -Message "An email-like value was detected."

Write-Host "PASS: Phase 1 report structure, arithmetic, and sanitization checks succeeded."
