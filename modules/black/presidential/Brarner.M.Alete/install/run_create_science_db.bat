@echo off
cd /d "%~dp0"
mysql --defaults-extra-file="..\configuration\.my.cnf" < create_science_db.sql
if %errorlevel%==0 (
    echo Science database created successfully.
    mysql --defaults-extra-file="..\configuration\.my.cnf" -e "USE Science; SHOW TABLES;"
) else (
    echo Failed. Check MySQL credentials in configuration\.my.cnf
)
