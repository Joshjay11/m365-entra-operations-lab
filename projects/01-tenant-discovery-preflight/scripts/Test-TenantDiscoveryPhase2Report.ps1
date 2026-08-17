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

function Assert-ExactProperties {
    param(
        [Parameter(Mandatory)]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string[]]$Expected,

        [Parameter(Mandatory)]
        [string]$Section
    )

    $actual = @($InputObject.PSObject.Properties.Name | Sort-Object)
    $expectedSorted = @($Expected | Sort-Object)

    Assert-Condition `
        -Condition (($actual -join "|") -eq ($expectedSorted -join "|")) `
        -Message "$Section contains missing or unexpected properties."
}

function Test-NonNegativeInteger {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    [long]$parsed = 0
    if (-not [long]::TryParse([string]$Value, [ref]$parsed)) {
        return $false
    }

    return $parsed -ge 0
}

function Assert-CountFields {
    param(
        [Parameter(Mandatory)]
        [object]$SectionObject,

        [Parameter(Mandatory)]
        [string[]]$Fields,

        [Parameter(Mandatory)]
        [string]$SectionName,

        [Parameter(Mandatory)]
        [bool]$RequireCounts
    )

    foreach ($field in $Fields) {
        $value = $SectionObject.$field
        if ($RequireCounts) {
            Assert-Condition `
                -Condition (Test-NonNegativeInteger -Value $value) `
                -Message "$SectionName.$field must be a non-negative integer when collected."
        }
        else {
            Assert-Condition `
                -Condition ($null -eq $value) `
                -Message "$SectionName.$field must be null when the section is unavailable."
        }
    }
}

$reportPathCandidate = if ([System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath
}
else {
    Join-Path -Path (Get-Location).Path -ChildPath $ReportPath
}
$fullReportPath = [System.IO.Path]::GetFullPath($reportPathCandidate)

if (-not (Test-Path -LiteralPath $fullReportPath -PathType Leaf)) {
    throw "Report file not found."
}

$json = Get-Content -LiteralPath $fullReportPath -Raw -Encoding UTF8
$report = $json | ConvertFrom-Json

Assert-ExactProperties -InputObject $report -Expected @(
    "metadata",
    "conditionalAccess",
    "authenticationRegistration",
    "identityRisk",
    "limitations"
) -Section "report"

Assert-ExactProperties -InputObject $report.metadata -Expected @(
    "schemaVersion",
    "generatedAtUtc",
    "evidenceType",
    "phase",
    "graphApiProfile"
) -Section "metadata"

Assert-Condition -Condition ($report.metadata.schemaVersion -eq "0.1.0") -Message "Unexpected schemaVersion."
Assert-Condition -Condition ($report.metadata.phase -eq "phase-2") -Message "Unexpected phase."
Assert-Condition -Condition ($report.metadata.graphApiProfile -eq "v1.0") -Message "Unexpected Graph API profile."
Assert-Condition `
    -Condition ($report.metadata.evidenceType -in @("synthetic", "sanitized-lab")) `
    -Message "Unexpected evidenceType."

[datetimeoffset]$generatedAt = [datetimeoffset]::MinValue
Assert-Condition `
    -Condition ([datetimeoffset]::TryParse([string]$report.metadata.generatedAtUtc, [ref]$generatedAt)) `
    -Message "generatedAtUtc is not a valid timestamp."

$conditionalAccessFields = @(
    "totalPolicies",
    "enabledPolicies",
    "reportOnlyPolicies",
    "disabledPolicies",
    "allUsersPolicies",
    "policiesWithUserExclusions",
    "policiesWithGroupExclusions",
    "policiesWithRoleExclusions",
    "mfaGrantPolicies",
    "authenticationStrengthPolicies",
    "blockGrantPolicies",
    "compliantDeviceGrantPolicies",
    "hybridJoinedDeviceGrantPolicies"
)

Assert-ExactProperties `
    -InputObject $report.conditionalAccess `
    -Expected (@("status") + $conditionalAccessFields) `
    -Section "conditionalAccess"

Assert-Condition `
    -Condition ($report.conditionalAccess.status -in @("complete", "unavailable")) `
    -Message "conditionalAccess.status is invalid."

$conditionalAccessComplete = $report.conditionalAccess.status -eq "complete"
Assert-CountFields `
    -SectionObject $report.conditionalAccess `
    -Fields $conditionalAccessFields `
    -SectionName "conditionalAccess" `
    -RequireCounts $conditionalAccessComplete

if ($conditionalAccessComplete) {
    $stateTotal = [long]$report.conditionalAccess.enabledPolicies +
        [long]$report.conditionalAccess.reportOnlyPolicies +
        [long]$report.conditionalAccess.disabledPolicies

    Assert-Condition `
        -Condition ($stateTotal -eq [long]$report.conditionalAccess.totalPolicies) `
        -Message "Conditional Access policy-state counts do not reconcile with totalPolicies."

    foreach ($field in $conditionalAccessFields | Where-Object { $_ -ne "totalPolicies" }) {
        Assert-Condition `
            -Condition ([long]$report.conditionalAccess.$field -le [long]$report.conditionalAccess.totalPolicies) `
            -Message "conditionalAccess.$field cannot exceed totalPolicies."
    }
}

$authenticationFields = @(
    "usersReported",
    "adminUsers",
    "mfaRegisteredUsers",
    "mfaCapableUsers",
    "ssprRegisteredUsers",
    "ssprEnabledUsers",
    "ssprCapableUsers",
    "passwordlessCapableUsers",
    "systemPreferredEnabledUsers"
)

Assert-ExactProperties `
    -InputObject $report.authenticationRegistration `
    -Expected (@("status") + $authenticationFields) `
    -Section "authenticationRegistration"

Assert-Condition `
    -Condition ($report.authenticationRegistration.status -in @("complete", "unavailable")) `
    -Message "authenticationRegistration.status is invalid."

$authenticationComplete = $report.authenticationRegistration.status -eq "complete"
Assert-CountFields `
    -SectionObject $report.authenticationRegistration `
    -Fields $authenticationFields `
    -SectionName "authenticationRegistration" `
    -RequireCounts $authenticationComplete

if ($authenticationComplete) {
    foreach ($field in $authenticationFields | Where-Object { $_ -ne "usersReported" }) {
        Assert-Condition `
            -Condition ([long]$report.authenticationRegistration.$field -le [long]$report.authenticationRegistration.usersReported) `
            -Message "authenticationRegistration.$field cannot exceed usersReported."
    }
}

Assert-ExactProperties -InputObject $report.identityRisk -Expected @(
    "status",
    "riskyUsersAvailable",
    "riskyUsers",
    "riskDetectionsAvailable",
    "riskDetections"
) -Section "identityRisk"

Assert-Condition `
    -Condition ($report.identityRisk.status -in @("complete", "partial", "unavailable")) `
    -Message "identityRisk.status is invalid."
Assert-Condition `
    -Condition ($report.identityRisk.riskyUsersAvailable -is [bool]) `
    -Message "identityRisk.riskyUsersAvailable must be Boolean."
Assert-Condition `
    -Condition ($report.identityRisk.riskDetectionsAvailable -is [bool]) `
    -Message "identityRisk.riskDetectionsAvailable must be Boolean."

if ($report.identityRisk.riskyUsersAvailable) {
    Assert-Condition `
        -Condition (Test-NonNegativeInteger -Value $report.identityRisk.riskyUsers) `
        -Message "identityRisk.riskyUsers must be a non-negative integer when available."
}
else {
    Assert-Condition `
        -Condition ($null -eq $report.identityRisk.riskyUsers) `
        -Message "identityRisk.riskyUsers must be null when unavailable."
}

if ($report.identityRisk.riskDetectionsAvailable) {
    Assert-Condition `
        -Condition (Test-NonNegativeInteger -Value $report.identityRisk.riskDetections) `
        -Message "identityRisk.riskDetections must be a non-negative integer when available."
}
else {
    Assert-Condition `
        -Condition ($null -eq $report.identityRisk.riskDetections) `
        -Message "identityRisk.riskDetections must be null when unavailable."
}

$availableRiskSources = @(
    $report.identityRisk.riskyUsersAvailable,
    $report.identityRisk.riskDetectionsAvailable
) | Where-Object { $_ -eq $true }

$expectedRiskStatus = if (@($availableRiskSources).Count -eq 2) {
    "complete"
}
elseif (@($availableRiskSources).Count -eq 1) {
    "partial"
}
else {
    "unavailable"
}

Assert-Condition `
    -Condition ($report.identityRisk.status -eq $expectedRiskStatus) `
    -Message "identityRisk.status does not match endpoint availability."

Assert-Condition `
    -Condition ($report.limitations -is [System.Array]) `
    -Message "limitations must be an array."

foreach ($limitation in @($report.limitations)) {
    Assert-Condition `
        -Condition (-not [string]::IsNullOrWhiteSpace([string]$limitation)) `
        -Message "limitations cannot contain blank entries."
}

$forbiddenPropertyPatterns = @(
    '"id"\s*:',
    '"tenantId"\s*:',
    '"displayName"\s*:',
    '"userPrincipalName"\s*:',
    '"domainName"\s*:',
    '"policyName"\s*:',
    '"ipAddress"\s*:',
    '"userId"\s*:'
)

foreach ($pattern in $forbiddenPropertyPatterns) {
    Assert-Condition `
        -Condition ($json -notmatch $pattern) `
        -Message "Sanitization check failed because a forbidden property was detected."
}

$guidPattern = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b'
$emailPattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'

Assert-Condition `
    -Condition ($json -notmatch $guidPattern) `
    -Message "Sanitization check failed because a GUID-like identifier was detected."
Assert-Condition `
    -Condition ($json -notmatch $emailPattern) `
    -Message "Sanitization check failed because an email-like value was detected."

Write-Host "PASS: Phase 2 report structure, arithmetic, availability, and sanitization checks succeeded."
