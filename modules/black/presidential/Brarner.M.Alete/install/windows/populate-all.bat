@echo off
REM Brarner.M.Alete™ — Populate ALL Tables (Windows)
REM Runs all population scripts in sequence.
REM Usage: install\windows\populate-all.bat

echo ═══════════════════════════════════════════════════════════════
echo  Brarner.M.Alete™ — Populate All Tables (Windows)
echo ═══════════════════════════════════════════════════════════════

set SCRIPT_DIR=%~dp0
set BMA_ROOT=%SCRIPT_DIR%..\..
set DB_PROPS=%BMA_ROOT%\servlets\servlet\src\main\webapp\WEB-INF\db.properties

if not exist "%DB_PROPS%" (
    echo [!] db.properties not found. Run install-mysql-windows.bat first.
    pause
    exit /b 1
)

for /f "tokens=1,* delims==" %%A in ('findstr "db.user" "%DB_PROPS%"') do set DB_USER=%%B
for /f "tokens=1,* delims==" %%A in ('findstr "db.password" "%DB_PROPS%"') do set DB_PASS=%%B

echo [*] Populating animalia...
call "%SCRIPT_DIR%populate-science-db.bat"

echo.
echo [*] Populating postal (sample)...
mysql -u%DB_USER% -p%DB_PASS% BrarnerScience -e "INSERT IGNORE INTO postal(zip_code,city,state,county) VALUES('27701','Durham','NC','Durham'),('27601','Raleigh','NC','Wake'),('28202','Charlotte','NC','Mecklenburg'),('90210','Beverly Hills','CA','Los Angeles'),('10001','New York','NY','New York'),('60601','Chicago','IL','Cook'),('77001','Houston','TX','Harris'),('85120','Apache Junction','AZ','Pinal');"
echo [OK] postal seeded.

echo.
echo [*] Populating art_works (sample)...
mysql -u%DB_USER% -p%DB_PASS% BrarnerScience -e "INSERT IGNORE INTO art_works(museum_name,title,artist,year_created,medium) VALUES('Metropolitan Museum of Art','Water Lilies','Claude Monet','1906','Oil on canvas'),('National Gallery of Art','Ginevra de Benci','Leonardo da Vinci','1474','Oil on panel'),('Art Institute of Chicago','American Gothic','Grant Wood','1930','Oil on beaverboard'),('Museum of Modern Art','The Starry Night','Vincent van Gogh','1889','Oil on canvas'),('NC Museum of Art','Wheatfields','Jacob van Ruisdael','1670','Oil on canvas');"
echo [OK] art_works seeded.

echo.
echo [*] Populating publications (sample)...
mysql -u%DB_USER% -p%DB_PASS% BrarnerScience -e "INSERT IGNORE INTO publications(source_name,title,authors,doi,year_published) VALUES('Nature','The structure of DNA','Watson JD, Crick FHC','10.1038/171737a0','1953'),('Science','Human Genome Project','International HGP Consortium','10.1126/science.1058040','2001'),('NCSU Journal','Eigenvalue methods','Rupplin M','10.ncsu/eigen.2026','2026');"
echo [OK] publications seeded.

echo.
echo [*] Populating ssa_offices (sample)...
mysql -u%DB_USER% -p%DB_PASS% BrarnerScience -e "CREATE TABLE IF NOT EXISTS ssa_offices(id BIGINT AUTO_INCREMENT PRIMARY KEY,office_name VARCHAR(255),address VARCHAR(500),city VARCHAR(100),state VARCHAR(50),zip_code VARCHAR(10),phone VARCHAR(30),office_type VARCHAR(50),INDEX idx_state(state)); INSERT IGNORE INTO ssa_offices(office_name,city,state,zip_code,phone,office_type) VALUES('Durham NC','Durham','NC','27707','1-877-405-3253','field'),('Raleigh NC','Raleigh','NC','27609','1-877-803-6514','field'),('Apache Junction AZ','Apache Junction','AZ','85120','1-800-772-1213','field');"
echo [OK] ssa_offices seeded.

echo.
echo ═══════════════════════════════════════════════════════════════
echo  [✓] All tables populated.
echo ═══════════════════════════════════════════════════════════════
pause
