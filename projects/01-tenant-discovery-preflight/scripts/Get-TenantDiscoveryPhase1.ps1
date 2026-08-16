[CmdletBinding()]
param(
    [string]$OutputPath = (
        Join-Path $PSScriptRoot (
            "../output/tenant-baseline.phase1.{0}.json" -f (
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
    "Get-MgOrganization",
    "Get-MgUser",
    "Get-MgGroup",
    "Get-MgSubscribedSku",
    "Get-MgRoleManagementDirectoryRoleAssignment",
    "Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance"
)

$requiredScopes = @(
    "User.Read.All",
    "Group.Read.All",
    "Organization.Read.All",
    "RoleManagement.Read.Directory"
)

$missingCommands = @(
    $requiredCommands | Where-Object {
        -not (Get-Command -Name $_ -ErrorAction SilentlyContinue)
    }
)

if ($missingCommands.Count -gt 0) {
    $missingCommandMessage = (
        "Required Microsoft Graph PowerShell commands are missing: {0}. " +
        "Install the stable Microsoft.Graph module before running this script."
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

function Get-Sum {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$InputObject
    )

    $sum = ($InputObject | Measure-Object -Sum).Sum
    if ($null -eq $sum) {
        return [long]0
    }

    return [long]$sum
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
        '"skuPartNumber"\s*:'
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
        schemaVersion  = "0.2.0"
        generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        evidenceType   = "sanitized-lab"
        phase          = "phase-1"
        graphApiProfile = "v1.0"
    }
    organization = [ordered]@{
        status             = "unavailable"
        organizations      = $null
        verifiedDomains    = $null
        defaultDomains     = $null
        initialDomains     = $null
    }
    identity = [ordered]@{
        status                   = "unavailable"
        totalUsers               = $null
        enabledUsers             = $null
        disabledUsers            = $null
        unknownAccountStateUsers = $null
        memberUsers              = $null
        guestUsers               = $null
        unknownUserTypeUsers     = $null
        syncedUsers              = $null
        cloudOnlyUsers           = $null
    }
    groups = [ordered]@{
        status              = "unavailable"
        totalGroups         = $null
        securityGroups      = $null
        microsoft365Groups  = $null
        dynamicGroups       = $null
        otherGroups         = $null
    }
    licensing = [ordered]@{
        status          = "unavailable"
        subscribedSkus  = $null
        enabledUnits    = $null
        consumedUnits   = $null
        availableUnits  = $null
    }
    privilegedAccess = [ordered]@{
        status                       = "unavailable"
        activeAssignments            = $null
        eligibleAssignments          = $null
        uniquePrivilegedPrincipals   = $null
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
        $organizations = @(
            Get-MgOrganization -All -Property @("id", "verifiedDomains") -ErrorAction Stop
        )

        if ($organizations.Count -eq 0) {
            throw "No organization object was returned."
        }

        $verifiedDomains = @(
            $organizations |
                ForEach-Object { @($_.VerifiedDomains) } |
                Where-Object { $null -ne $_ -and $_.IsVerified -eq $true }
        )

        $report.organization = [ordered]@{
            status          = "complete"
            organizations   = $organizations.Count
            verifiedDomains = $verifiedDomains.Count
            defaultDomains  = @($verifiedDomains | Where-Object { $_.IsDefault -eq $true }).Count
            initialDomains  = @($verifiedDomains | Where-Object { $_.IsInitial -eq $true }).Count
        }
    }
    catch {
        Add-Limitation "Organization and verified-domain counts were not collected. Confirm User.Read.All access and retry."
    }

    try {
        $users = @(
            Get-MgUser -All -Property @(
                "id",
                "accountEnabled",
                "userType",
                "onPremisesSyncEnabled"
            ) -ErrorAction Stop
        )

        $report.identity = [ordered]@{
            status                   = "complete"
            totalUsers               = $users.Count
            enabledUsers             = Get-Count $users { $_.AccountEnabled -eq $true }
            disabledUsers            = Get-Count $users { $_.AccountEnabled -eq $false }
            unknownAccountStateUsers = Get-Count $users { $null -eq $_.AccountEnabled }
            memberUsers              = Get-Count $users { $_.UserType -eq "Member" }
            guestUsers               = Get-Count $users { $_.UserType -eq "Guest" }
            unknownUserTypeUsers     = Get-Count $users { $_.UserType -notin @("Member", "Guest") }
            syncedUsers              = Get-Count $users { $_.OnPremisesSyncEnabled -eq $true }
            cloudOnlyUsers           = Get-Count $users { $_.OnPremisesSyncEnabled -ne $true }
        }
    }
    catch {
        Add-Limitation "User, guest, account-state, and synchronization counts were not collected. Confirm User.Read.All access and retry."
    }

    try {
        $groups = @(
            Get-MgGroup -All -Property @(
                "id",
                "groupTypes",
                "securityEnabled"
            ) -ErrorAction Stop
        )

        $report.groups = [ordered]@{
            status             = "complete"
            totalGroups        = $groups.Count
            securityGroups     = Get-Count $groups {
                $_.SecurityEnabled -eq $true -and $_.GroupTypes -notcontains "Unified"
            }
            microsoft365Groups = Get-Count $groups { $_.GroupTypes -contains "Unified" }
            dynamicGroups      = Get-Count $groups { $_.GroupTypes -contains "DynamicMembership" }
            otherGroups        = Get-Count $groups {
                $_.SecurityEnabled -ne $true -and $_.GroupTypes -notcontains "Unified"
            }
        }
    }
    catch {
        Add-Limitation "Group-type counts were not collected. Confirm Group.Read.All access and retry."
    }

    try {
        $skus = @(
            Get-MgSubscribedSku -All -Property @(
                "id",
                "consumedUnits",
                "prepaidUnits"
            ) -ErrorAction Stop
        )

        $enabledUnits = Get-Sum @(
            $skus | ForEach-Object { $_.PrepaidUnits.Enabled }
        )
        $consumedUnits = Get-Sum @(
            $skus | ForEach-Object { $_.ConsumedUnits }
        )

        $report.licensing = [ordered]@{
            status         = "complete"
            subscribedSkus = $skus.Count
            enabledUnits   = $enabledUnits
            consumedUnits  = $consumedUnits
            availableUnits = $enabledUnits - $consumedUnits
        }
    }
    catch {
        Add-Limitation "Aggregate license counts were not collected. Confirm Organization.Read.All access and retry."
    }

    $activeAssignments = $null
    $eligibleAssignments = $null
    $activeCollected = $false
    $eligibleCollected = $false

    try {
        $activeAssignments = @(
            Get-MgRoleManagementDirectoryRoleAssignment -All -Property @(
                "principalId"
            ) -ErrorAction Stop
        )
        $activeCollected = $true
    }
    catch {
        Add-Limitation "Active privileged-role assignment counts were not collected. Confirm RoleManagement.Read.Directory access and retry."
    }

    try {
        $eligibleAssignments = @(
            Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All -Property @(
                "principalId"
            ) -ErrorAction Stop
        )
        $eligibleCollected = $true
    }
    catch {
        Add-Limitation "Eligible privileged-role assignment counts were not collected. The tenant may lack the required permission, role access, or PIM capability."
    }

    if ($activeCollected -and $eligibleCollected) {
        $allPrincipalIds = @(
            $activeAssignments | ForEach-Object { $_.PrincipalId }
        )
        $allPrincipalIds += @(
            $eligibleAssignments | ForEach-Object { $_.PrincipalId }
        )

        $uniquePrincipals = @(
            $allPrincipalIds |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Sort-Object -Unique
        )

        $report.privilegedAccess = [ordered]@{
            status                     = "complete"
            activeAssignments          = $activeAssignments.Count
            eligibleAssignments        = $eligibleAssignments.Count
            uniquePrivilegedPrincipals = $uniquePrincipals.Count
        }
    }
    elseif ($activeCollected -or $eligibleCollected) {
        $report.privilegedAccess = [ordered]@{
            status                     = "partial"
            activeAssignments          = if ($activeCollected) { $activeAssignments.Count } else { $null }
            eligibleAssignments        = if ($eligibleCollected) { $eligibleAssignments.Count } else { $null }
            uniquePrivilegedPrincipals = $null
        }
    }

    Add-Limitation "Conditional Access, device, and Microsoft 365 workload posture are outside Phase 1 and were not collected."
    $report.limitations = @($limitations)

    $sections = @(
        $report.organization,
        $report.identity,
        $report.groups,
        $report.licensing,
        $report.privilegedAccess
    )
    $collectedSections = @(
        $sections | Where-Object { $_.status -in @("complete", "partial") }
    ).Count

    if ($collectedSections -eq 0) {
        throw "No Phase 1 section was collected. Confirm the Graph connection and delegated permissions before retrying."
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

    Write-Host "Phase 1 aggregate report written to: $fullOutputPath"
    Write-Host "The report contains counts and collection status only. Review it before sharing any excerpt."
}
finally {
    if ($connectedByScript -and -not $KeepGraphConnection) {
        Disconnect-MgGraph | Out-Null
    }
}
