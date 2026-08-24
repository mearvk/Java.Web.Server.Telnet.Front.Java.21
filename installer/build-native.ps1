[CmdletBinding()]
param([switch]$SkipMaven)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not $SkipMaven) { mvn -B clean package }
$version = (mvn -q -DforceStdout help:evaluate '-Dexpression=project.version').Trim()
$jar = "target\us-house-installer-$version.jar"
if (-not (Test-Path $jar)) { throw "Build did not produce $jar" }
New-Item -ItemType Directory -Force -Path dist | Out-Null
jpackage --type app-image --name US-House-Installer --input target --main-jar (Split-Path $jar -Leaf) --main-class us.house.installer.USHouseInstaller --dest dist
jpackage --type exe --name US-House-Installer --input target --main-jar (Split-Path $jar -Leaf) --main-class us.house.installer.USHouseInstaller --dest dist
Write-Host "Native Windows installer written to $PSScriptRoot\dist"
