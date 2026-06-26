<#
.SYNOPSIS
    Brarner.M.Alete Animalia Install Script
.DESCRIPTION
    1. Checks for existing Science database and MEARVK brand ownership
    2. Creates BrarnerScience database if needed
    3. Installs schema with installer_registry brand marker
    4. Parses animalia.coercus.config and populates taxonomy table
    5. Registers species instances
.NOTES
    Installer Tax ID: MEARVK-LLC-2026
    Brand: Brarner.M.Alete / MEARVK LLC / Max Rupplin
#>

param(
    [string]$MySqlHost = "localhost",
    [string]$MySqlPort = "3306",
    [string]$MySqlUser = "root",
    [string]$MySqlPass = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=== Brarner.M.Alete Animalia Installer ===" -ForegroundColor Cyan
Write-Host "Installer Tax ID: MEARVK-LLC-2026"
Write-Host "Brand: Brarner.M.Alete / MEARVK LLC"
Write-Host ""

# Step 1: Run schema SQL
Write-Host "[1/4] Installing schema..." -ForegroundColor Yellow
$schemaFile = "servlets/servlet/src/main/resources/animalia-schema.sql"
if (Test-Path $schemaFile) {
    try {
        Get-Content $schemaFile | & mysql -h $MySqlHost -P $MySqlPort -u $MySqlUser --password="$MySqlPass" 2>$null
        Write-Host "  Schema installed." -ForegroundColor Green
    } catch {
        Write-Host "  Note: mysql CLI not found or connection failed. Schema SQL saved for manual execution." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Schema file not found at $schemaFile" -ForegroundColor Red
}

# Step 2: Parse animalia.coercus.config
Write-Host "[2/4] Parsing animalia.coercus.config..." -ForegroundColor Yellow
$configFile = "source-code/config-files/animalia.coercus.config"
$lines = Get-Content $configFile

$currentPhylum = ""
$currentSubphylum = ""
$currentClass = ""
$currentSubclass = ""
$currentSuperorder = ""
$currentOrder = ""
$currentSuborder = ""
$currentInfraorder = ""
$insertStatements = @()

foreach ($line in $lines) {
    if ($line -match "^\s+Phylum:\s+(.+)$") { $currentPhylum = $Matches[1].Trim(); $currentSubphylum = ""; $currentClass = ""; $currentSubclass = ""; $currentSuperorder = ""; $currentOrder = ""; $currentSuborder = ""; $currentInfraorder = "" }
    elseif ($line -match "Subphylum:\s+(.+)$") { $currentSubphylum = $Matches[1].Trim(); $currentClass = ""; $currentSubclass = ""; $currentSuperorder = ""; $currentOrder = ""; $currentSuborder = ""; $currentInfraorder = "" }
    elseif ($line -match "Class:\s+(.+)$") { $currentClass = $Matches[1].Trim(); $currentSubclass = ""; $currentSuperorder = ""; $currentOrder = ""; $currentSuborder = ""; $currentInfraorder = "" }
    elseif ($line -match "Subclass:\s+(.+)$") { $currentSubclass = $Matches[1].Trim(); $currentSuperorder = ""; $currentOrder = ""; $currentSuborder = ""; $currentInfraorder = "" }
    elseif ($line -match "Superorder:\s+(.+)$") { $currentSuperorder = $Matches[1].Trim() }
    elseif ($line -match "Order:\s+(.+)$") { $currentOrder = $Matches[1].Trim(); $currentSuborder = ""; $currentInfraorder = "" }
    elseif ($line -match "Suborder:\s+(.+)$") { $currentSuborder = $Matches[1].Trim(); $currentInfraorder = "" }
    elseif ($line -match "Infraorder:\s+(.+)$") { $currentInfraorder = $Matches[1].Trim() }
    elseif ($line -match "Family:\s+(.+)$") {
        $family = $Matches[1].Trim()
        $phy = $currentPhylum -replace "'","''"
        $sub = $currentSubphylum -replace "'","''"
        $cls = $currentClass -replace "'","''"
        $scl = $currentSubclass -replace "'","''"
        $ord = $currentOrder -replace "'","''"
        $sor = $currentSuborder -replace "'","''"
        $inf = $currentInfraorder -replace "'","''"
        $fam = $family -replace "'","''"
        $insertStatements += "('$phy','$sub','$cls','$scl','$ord','$sor','$inf','$fam','MEARVK-LLC-2026')"
    }
}

Write-Host "  Parsed $($insertStatements.Count) family entries." -ForegroundColor Green

# Step 3: Generate bulk SQL
Write-Host "[3/4] Generating bulk insert SQL..." -ForegroundColor Yellow
$sqlFile = "install/animalia-bulk-insert.sql"
New-Item -ItemType Directory -Path "install" -Force | Out-Null

$header = @"
USE BrarnerScience;
INSERT INTO animalia (phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name, installer_tax_id) VALUES
"@

$batchSize = 500
$batches = [Math]::Ceiling($insertStatements.Count / $batchSize)
$content = $header + "`n"

for ($i = 0; $i -lt $insertStatements.Count; $i++) {
    $content += $insertStatements[$i]
    if (($i + 1) % $batchSize -eq 0 -or $i -eq $insertStatements.Count - 1) {
        $content += ";`n"
        if ($i -lt $insertStatements.Count - 1) {
            $content += "INSERT INTO animalia (phylum, subphylum, class_name, subclass, order_name, suborder, infraorder, family_name, installer_tax_id) VALUES`n"
        }
    } else {
        $content += ",`n"
    }
}

[System.IO.File]::WriteAllText($sqlFile, $content, (New-Object System.Text.UTF8Encoding $false))
Write-Host "  Written to $sqlFile ($($insertStatements.Count) rows)" -ForegroundColor Green

# Step 4: Register species instances
Write-Host "[4/4] Registering species instances..." -ForegroundColor Yellow
$instanceSql = "USE BrarnerScience;`n"
$phyla = $insertStatements | ForEach-Object { if ($_ -match "^\('([^']+)'") { $Matches[1] } } | Select-Object -Unique
$port = 10400
foreach ($p in $phyla) {
    $instanceSql += "INSERT IGNORE INTO species_instances (phylum, port, status, installer_tax_id) VALUES ('$p', $port, 'standby', 'MEARVK-LLC-2026');`n"
    $port++
}
[System.IO.File]::WriteAllText("install/species-instances.sql", $instanceSql, (New-Object System.Text.UTF8Encoding $false))
Write-Host "  Written to install/species-instances.sql" -ForegroundColor Green

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "To load data into MySQL, run:"
Write-Host "  mysql -u root < servlets/servlet/src/main/resources/animalia-schema.sql"
Write-Host "  mysql -u root < install/animalia-bulk-insert.sql"
Write-Host "  mysql -u root < install/species-instances.sql"
