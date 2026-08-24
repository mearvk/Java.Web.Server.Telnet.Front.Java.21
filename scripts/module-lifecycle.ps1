[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('install','update','verify','remove','status')][string]$Action,
  [string]$Module = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Modules = Join-Path $Root 'modules'

function Invoke-Script([string]$Path) {
  if (Test-Path $Path) { & bash $Path; if ($LASTEXITCODE -ne 0) { throw "Hook failed: $Path" } }
}

$dirs = if ($Module -eq 'all') {
  Get-ChildItem -Path $Modules -Directory -Recurse -Depth 1
} else {
  $p = Join-Path $Modules $Module
  if (-not (Test-Path $p)) { throw "Unknown module: $Module" }
  @(Get-Item $p)
}

foreach ($m in $dirs) {
  $install = Join-Path $m.FullName 'install.sh'
  $update = Join-Path $m.FullName 'update.sh'
  $verify = Join-Path $m.FullName 'verify.sh'
  $uninstall = Join-Path $m.FullName 'uninstall.sh'
  $stopBackend = Join-Path $m.FullName 'shutdown-backend.sh'
  $stopFrontend = Join-Path $m.FullName 'shutdown-frontend.sh'

  Write-Host "==> $Action $($m.Name)"
  switch ($Action) {
    'install' {
      if (Test-Path $install) { Invoke-Script $install }
      elseif (Test-Path (Join-Path $m.FullName 'source/Makefile')) { make -C (Join-Path $m.FullName 'source') }
      elseif (Test-Path (Join-Path $m.FullName 'Makefile')) { make -C $m.FullName }
      elseif (Test-Path (Join-Path $m.FullName 'pom.xml')) { mvn -f (Join-Path $m.FullName 'pom.xml') package }
      else { Write-Host 'No install/build hook; source preserved.' }
    }
    'update' {
      if (Test-Path $update) { Invoke-Script $update } else { & $PSCommandPath -Action install -Module $m.Name }
    }
    'verify' { if (Test-Path $verify) { Invoke-Script $verify } else { Write-Host 'Lifecycle hooks:'; Write-Host "  install=$([bool](Test-Path $install)) update=$([bool](Test-Path $update)) remove=$([bool](Test-Path $uninstall)) verify=$([bool](Test-Path $verify))" } }
    'status' { & $PSCommandPath -Action verify -Module $m.Name }
    'remove' {
      if (Test-Path $stopBackend) { Invoke-Script $stopBackend }
      if (Test-Path $stopFrontend) { Invoke-Script $stopFrontend }
      if (Test-Path $uninstall) { Invoke-Script $uninstall }
      foreach ($name in @('out','build','target')) { $p = Join-Path $m.FullName $name; if (Test-Path $p) { Remove-Item -Recurse -Force $p } }
      Get-ChildItem $m.FullName -Recurse -File -Include *.class,*.jar -ErrorAction SilentlyContinue | Remove-Item -Force
      Write-Host 'Source preserved; generated artifacts removed where recognized.'
    }
  }
}
