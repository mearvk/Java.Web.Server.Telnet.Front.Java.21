[CmdletBinding()]
param(
    [ValidateSet('menu','list','install','update','remove','status','upgrade-all')]
    [string]$Action = 'menu',
    [ValidateSet('microsoft','apple','all')]
    [string]$Vendor = 'all',
    [string]$Package,
    [switch]$Machine
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'US-House-Apps.ps1'

if (-not (Test-Path -LiteralPath $script)) {
    throw "US-House-Apps.ps1 was not found at $script"
}

function Invoke-House([string]$op) {
    $args = @{ Action=$op; Vendor=$Vendor }
    if ($Package) { $args.Package=$Package }
    if ($Machine) { $args.Machine=$true }
    & $script @args
}

switch ($Action) {
    'menu' {
        Write-Host ''
        Write-Host 'US HOUSE — SOFTWARE CONVENIENCE' -ForegroundColor Cyan
        Write-Host '1. List catalog'
        Write-Host '2. Install'
        Write-Host '3. Update'
        Write-Host '4. Remove'
        Write-Host '5. Status'
        Write-Host '6. Upgrade all'
        Write-Host '7. Exit'
        $choice = Read-Host 'Select'
        $map = @{ '1'='list'; '2'='install'; '3'='update'; '4'='remove'; '5'='status'; '6'='upgrade-all' }
        if ($map.ContainsKey($choice)) { Invoke-House $map[$choice] }
    }
    default { Invoke-House $Action }
}
