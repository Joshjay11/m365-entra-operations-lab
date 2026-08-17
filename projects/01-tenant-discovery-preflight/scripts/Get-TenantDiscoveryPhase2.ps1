[CmdletBinding()]
param(
    [string]$OutputPath = (
        Join-Path $PSScriptRoot (
            "../output/access-policy-posture.phase2.{0}.json" -f (
                (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
            )
        )
    ),

    [switch]$UseExistingConnection,

    [switch]$KeepGraphConnection,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredCommands = @(
    "Connect-MgGraph",
    "Disconnect-MgGraph",
    "Get-MgContext",
    "Get-MgIdentityConditionalAccessPolicy",
    "Get-MgReportAuthenticationMethodUserRegistrationDetail",
    "Get-MgRiskyUser",
    "Get-MgRiskDetection"
)

$requiredScopes = @(
    "Policy.Read.All",
    "AuditLog.Read.All",
    "IdentityRiskyUser.Read.All",
    "IdentityRiskEvent.Read.All"
)

$missingCommands = @(
    $requiredCommands | Where-Object {
        -not (Get-Command -Name $_ -ErrorAction SilentlyContinue)
    }
)

if ($missingCommands.Count -gt 0) {
    $missingCommandMessage = (
        "Required Microsoft Graph PowerShell commands are missing: {0}. " +
        "Install or update the stable Microsoft.Graph module before running this script."
    ) -f ($missingCommands -join ", ")
    throw $missingCommandMessage
}

function Add-Limitation {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $script:limitations.Contains($Message)) {
        $script:limitations.Add($Message)
    }
}

function Get-Count {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$InputObject,

        [Parameter(Mandatory)]
        [scriptblock]$FilterScript
    )

    return @($InputObject | Where-Object $FilterScript).Count
}

function Get-ConditionalAccessUsers {
    param(
        [Parameter(Mandatory)]
        [object]$Policy
    )

    if ($null -eq $Policy.Conditions) {
        return $null
    }

    return $Policy.Conditions.Users
}

function Get-BuiltInControls {
    param(
        [Parameter(Mandatory)]
        [object]$Policy
    )

    if ($null -eq $Policy.GrantControls) {
        return @()
    }

    return @(
        $Policy.GrantControls.BuiltInControls |
            ForEach-Object { [string]$_ }
    )
}

function Test-GrantControl {
    param(
        [Parameter(Mandatory)]
        [object]$Policy,

        [Parameter(Mandatory)]
        [string]$Control
    )

    return (Get-BuiltInControls -Policy $Policy) -contains $Control
}

function Assert-SanitizedReport {
    param(
        [Parameter(Mandatory)]
        [string]$Json
    )

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
        if ($Json -match $pattern) {
            throw "Sanitization check failed because a forbidden property was detected."
        }
    }

    $guidPattern = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b'
    $emailPattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'

    if ($Json -match $guidPattern) {
        throw "Sanitization check failed because a GUID-like identifier was detected."
    }

    if ($Json -match $emailPattern) {
        throw "Sanitization check failed because an email-like value was detected."
    }
}

$limitations = [System.Collections.Generic.List[string]]::new()
$connectedByScript = $false

$report = [ordered]@{
    metadata = [ordered]@{
        schemaVersion   = "0.1.0"
        generatedAtUtc  = (Get-Date).ToUniversalTime().ToString("o")
        evidenceType    = "sanitized-lab"
        phase           = "phase-2"
        graphApiProfile = "v1.0"
    }
    conditionalAccess = [ordered]@{
        status                           = "unavailable"
        totalPolicies                    = $null
        enabledPolicies                  = $null
        reportOnlyPolicies               = $null
        disabledPolicies                 = $null
        allUsersPolicies                 = $null
        policiesWithUserExclusions       = $null
        policiesWithGroupExclusions      = $null
        policiesWithRoleExclusions       = $null
        mfaGrantPolicies                 = $null
        authenticationStrengthPolicies   = $null
        blockGrantPolicies               = $null
        compliantDeviceGrantPolicies     = $null
        hybridJoinedDeviceGrantPolicies  = $null
    }
    authenticationRegistration = [ordered]@{
        status                        = "unavailable"
        usersReported                 = $null
        adminUsers                    = $null
        mfaRegisteredUsers            = $null
        mfaCapableUsers               = $null
        ssprRegisteredUsers           = $null
        ssprEnabledUsers              = $null
        ssprCapableUsers              = $null
        passwordlessCapableUsers      = $null
        systemPreferredEnabledUsers   = $null
    }
    identityRisk = [ordered]@{
        status                   = "unavailable"
        riskyUsersAvailable      = $false
        riskyUsers               = $null
        riskDetectionsAvailable  = $false
        riskDetections           = $null
    }
    limitations = @()
}

try {
    if ($UseExistingConnection) {
        if ($null -eq (Get-MgContext)) {
            throw "No Microsoft Graph context exists. Connect first or omit -UseExistingConnection."
        }
    }
    else {
        $connectParameters = @{
            Scopes       = $requiredScopes
            ContextScope = "Process"
            NoWelcome    = $true
        }
        Connect-MgGraph @connectParameters
        $connectedByScript = $true
    }

    try {
        $policies = @(
            Get-MgIdentityConditionalAccessPolicy -All -Property @(
                "id",
                "state",
                "conditions",
                "grantControls"
            ) -ErrorAction Stop
        )

        $report.conditionalAccess = [ordered]@{
            status                          = "complete"
            totalPolicies                   = $policies.Count
            enabledPolicies                 = Get-Count $policies { [string]$_.State -eq "enabled" }
            reportOnlyPolicies              = Get-Count $policies {
                [string]$_.State -eq "enabledForReportingButNotEnforced"
            }
            disabledPolicies                = Get-Count $policies { [string]$_.State -eq "disabled" }
            allUsersPolicies                = Get-Count $policies {
                $users = Get-ConditionalAccessUsers -Policy $_
                $null -ne $users -and @($users.IncludeUsers) -contains "All"
            }
            policiesWithUserExclusions      = Get-Count $policies {
                $users = Get-ConditionalAccessUsers -Policy $_
                $null -ne $users -and @($users.ExcludeUsers).Count -gt 0
            }
            policiesWithGroupExclusions     = Get-Count $policies {
                $users = Get-ConditionalAccessUsers -Policy $_
                $null -ne $users -and @($users.ExcludeGroups).Count -gt 0
            }
            policiesWithRoleExclusions      = Get-Count $policies {
                $users = Get-ConditionalAccessUsers -Policy $_
                $null -ne $users -and @($users.ExcludeRoles).Count -gt 0
            }
            mfaGrantPolicies                = Get-Count $policies {
                Test-GrantControl -Policy $_ -Control "mfa"
            }
            authenticationStrengthPolicies  = Get-Count $policies {
                $null -ne $_.GrantControls -and
                    $null -ne $_.GrantControls.AuthenticationStrength
            }
            blockGrantPolicies              = Get-Count $policies {
                Test-GrantControl -Policy $_ -Control "block"
            }
            compliantDeviceGrantPolicies    = Get-Count $policies {
                Test-GrantControl -Policy $_ -Control "compliantDevice"
            }
            hybridJoinedDeviceGrantPolicies = Get-Count $policies {
                Test-GrantControl -Policy $_ -Control "domainJoinedDevice"
            }
        }
    }
    catch {
        Add-Limitation "Conditional Access policy counts were not collected. Confirm Policy.Read.All access, a supported directory role, and tenant capability before retrying."
    }

    try {
        $registrationDetails = @(
            Get-MgReportAuthenticationMethodUserRegistrationDetail -All -Property @(
                "id",
                "isAdmin",
                "isMfaCapable",
                "isMfaRegistered",
                "isPasswordlessCapable",
                "isSsprCapable",
                "isSsprEnabled",
                "isSsprRegistered",
                "isSystemPreferredAuthenticationMethodEnabled"
            ) -ErrorAction Stop
        )

        $report.authenticationRegistration = [ordered]@{
            status                       = "complete"
            usersReported                = $registrationDetails.Count
            adminUsers                   = Get-Count $registrationDetails { $_.IsAdmin -eq $true }
            mfaRegisteredUsers           = Get-Count $registrationDetails { $_.IsMfaRegistered -eq $true }
            mfaCapableUsers              = Get-Count $registrationDetails { $_.IsMfaCapable -eq $true }
            ssprRegisteredUsers          = Get-Count $registrationDetails { $_.IsSsprRegistered -eq $true }
            ssprEnabledUsers             = Get-Count $registrationDetails { $_.IsSsprEnabled -eq $true }
            ssprCapableUsers             = Get-Count $registrationDetails { $_.IsSsprCapable -eq $true }
            passwordlessCapableUsers     = Get-Count $registrationDetails { $_.IsPasswordlessCapable -eq $true }
            systemPreferredEnabledUsers  = Get-Count $registrationDetails {
                $_.IsSystemPreferredAuthenticationMethodEnabled -eq $true
            }
        }

        Add-Limitation "The authentication registration report does not return disabled users, so usersReported is not a tenant-wide user total."
    }
    catch {
        Add-Limitation "Authentication registration counts were not collected. Confirm AuditLog.Read.All access, a supported directory role, and report availability before retrying."
    }

    $riskyUsersCollected = $false
    $riskDetectionsCollected = $false
    $riskyUsers = @()
    $riskDetections = @()

    try {
        $riskyUsers = @(
            Get-MgRiskyUser -All -Property @("id") -ErrorAction Stop
        )
        $riskyUsersCollected = $true
    }
    catch {
        Add-Limitation "Risky-user availability was not collected. Confirm IdentityRiskyUser.Read.All access, a supported directory role, and Microsoft Entra ID Protection licensing."
    }

    try {
        $riskDetections = @(
            Get-MgRiskDetection -All -Property @("id") -ErrorAction Stop
        )
        $riskDetectionsCollected = $true
    }
    catch {
        Add-Limitation "Risk-detection availability was not collected. Confirm IdentityRiskEvent.Read.All access, a supported directory role, and Microsoft Entra ID Protection licensing."
    }

    $riskStatus = if ($riskyUsersCollected -and $riskDetectionsCollected) {
        "complete"
    }
    elseif ($riskyUsersCollected -or $riskDetectionsCollected) {
        "partial"
    }
    else {
        "unavailable"
    }

    $report.identityRisk = [ordered]@{
        status                  = $riskStatus
        riskyUsersAvailable     = $riskyUsersCollected
        riskyUsers              = if ($riskyUsersCollected) { $riskyUsers.Count } else { $null }
        riskDetectionsAvailable = $riskDetectionsCollected
        riskDetections          = if ($riskDetectionsCollected) { $riskDetections.Count } else { $null }
    }

    Add-Limitation "Emergency-access account design and Conditional Access exclusion correctness require manual review; this collector does not identify or certify emergency accounts."
    Add-Limitation "Phase 2 reports aggregate posture only and does not prove that any individual policy is correctly designed or effective."
    $report.limitations = @($limitations)

    $sections = @(
        $report.conditionalAccess,
        $report.authenticationRegistration,
        $report.identityRisk
    )
    $collectedSections = @(
        $sections | Where-Object { $_.status -in @("complete", "partial") }
    ).Count

    if ($collectedSections -eq 0) {
        throw "No Phase 2 section was collected. Confirm the Graph connection, delegated permissions, directory role, and tenant licensing before retrying."
    }

    $json = $report | ConvertTo-Json -Depth 10
    Assert-SanitizedReport -Json $json

    $outputPathCandidate = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    }
    else {
        Join-Path -Path (Get-Location).Path -ChildPath $OutputPath
    }
    $fullOutputPath = [System.IO.Path]::GetFullPath($outputPathCandidate)
    $sampleDirectory = [System.IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot "../samples")
    )

    $sampleDirectoryPrefix = $sampleDirectory.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if ($fullOutputPath.StartsWith($sampleDirectoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Real tenant output cannot be written under the committed samples directory."
    }

    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
        throw "The output file already exists. Choose a new path or use -Force explicitly."
    }

    $outputDirectory = Split-Path -Parent $fullOutputPath
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    Set-Content -LiteralPath $fullOutputPath -Value $json -Encoding utf8 -NoNewline

    Write-Host "Phase 2 aggregate report written to: $fullOutputPath"
    Write-Host "The report contains counts, availability, and limitations only. Review it before sharing any excerpt."
}
finally {
    if ($connectedByScript -and -not $KeepGraphConnection) {
        Disconnect-MgGraph | Out-Null
    }
}
