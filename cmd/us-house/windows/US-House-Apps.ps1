[CmdletBinding()]
param(
    [ValidateSet('install','update','remove','status','upgrade-all','repair','list')]
    [string]$Action = 'status',
    [ValidateSet('microsoft','apple','all')]
    [string]$Vendor = 'all',
    [string]$Package,
    [switch]$Machine
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'Windows Package Manager (winget) is required.'
}

$catalog = @{
    microsoft = @{
        edge='Microsoft.Edge'; vscode='Microsoft.VisualStudioCode'; powershell='Microsoft.PowerShell';
        dotnet='Microsoft.DotNet.SDK.8'; teams='Microsoft.Teams'; onedrive='Microsoft.OneDrive'
    }
    apple = @{
        icloud='Apple.iCloud'; applemusic='Apple.AppleMusic'; devices='Apple.AppleDevices'
    }
}

function Run-Winget([string[]]$Args) {
    & winget @Args
    if ($LASTEXITCODE -ne 0) { throw "winget failed with exit code $LASTEXITCODE" }
}

if ($Action -eq 'list') {
    $catalog.GetEnumerator() | ForEach-Object {
        Write-Host "[$($_.Key)]"
        $_.Value.GetEnumerator() | Sort-Object Name | Format-Table Name,Value -AutoSize
    }
    exit 0
}

$vendors = if ($Vendor -eq 'all') { @('microsoft','apple') } else { @($Vendor) }
$ids = @()
if ($Package) {
    foreach ($v in $vendors) {
        if ($catalog[$v].ContainsKey($Package)) { $ids += $catalog[$v][$Package] }
    }
    if ($ids.Count -eq 0) { throw "Package alias '$Package' is not in the selected vendor catalog." }
} else {
    foreach ($v in $vendors) { $ids += $catalog[$v].Values }
}

$scope = @()
if ($Machine) { $scope = @('--scope','machine') }

switch ($Action) {
    'install' { foreach ($id in $ids) { Run-Winget (@('install','--id',$id,'--exact') + $scope + @('--accept-package-agreements','--accept-source-agreements')) } }
    'update' { foreach ($id in $ids) { Run-Winget (@('upgrade','--id',$id,'--exact') + $scope + @('--accept-package-agreements','--accept-source-agreements')) } }
    'remove' { foreach ($id in $ids) { Run-Winget (@('uninstall','--id',$id,'--exact') + $scope) } }
    'status' { foreach ($id in $ids) { & winget list --id $id --exact } }
    'upgrade-all' { Run-Winget @('upgrade','--all','--accept-package-agreements','--accept-source-agreements') }
    'repair' {
        if (-not $Package) { throw 'Repair requires -Package.' }
        foreach ($id in $ids) { Run-Winget (@('repair','--id',$id,'--exact') + $scope) }
    }
}

Write-Host 'US House software operation complete.'
