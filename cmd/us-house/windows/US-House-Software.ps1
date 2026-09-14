[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('install','update','remove','status','list')]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [ValidateSet('microsoft','apple')]
    [string]$Vendor,

    [string]$Package,
    [switch]$AllUsers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is required for Windows package operations.'
    }
}

function Invoke-Winget([string[]]$Args) {
    Assert-Winget
    & winget @Args
    if ($LASTEXITCODE -ne 0) { throw "winget failed with exit code $LASTEXITCODE" }
}

$ids = @{
    microsoft = @{
        'edge'       = 'Microsoft.Edge'
        'vscode'     = 'Microsoft.VisualStudioCode'
        'powershell' = 'Microsoft.PowerShell'
        'dotnet'     = 'Microsoft.DotNet.SDK.8'
        'git'        = 'Git.Git'
    }
    apple = @{
        'icloud'     = 'Apple.iCloud'
        'applemusic' = 'Apple.AppleMusic'
        'devices'    = 'Apple.AppleDevices'
    }
}

if ($Action -eq 'list') {
    $ids[$Vendor].GetEnumerator() | Sort-Object Name | Format-Table -AutoSize
    exit 0
}

if (-not $Package) {
    throw 'Specify -Package, or use -Action list to view supported package aliases.'
}

if (-not $ids[$Vendor].ContainsKey($Package)) {
    throw "Unsupported $Vendor package alias '$Package'. Use -Action list."
}

$id = $ids[$Vendor][$Package]
$common = @('--id', $id, '--exact', '--source', 'winget')
if ($AllUsers) { $common += '--scope'; $common += 'machine' }

switch ($Action) {
    'install' { Invoke-Winget (@('install') + $common + @('--accept-package-agreements','--accept-source-agreements')) }
    'update'  { Invoke-Winget (@('upgrade') + $common + @('--accept-package-agreements','--accept-source-agreements')) }
    'remove'  { Invoke-Winget (@('uninstall') + $common) }
    'status'  { Invoke-Winget (@('list') + $common) }
}
