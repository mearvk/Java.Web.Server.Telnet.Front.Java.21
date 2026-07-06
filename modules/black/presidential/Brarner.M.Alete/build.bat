@echo off
REM Build script for Brarner.M.Alete — Windows
REM Produces: Brarner.M.Alete.jar

setlocal

set JAR_NAME=Brarner.M.Alete.jar
set SRC_DIR=source-code
set OUT_DIR=build\classes
set LIB_DIR=lib

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

REM Find all Java source files
dir /s /b "%SRC_DIR%\*.java" > build\sources.txt

REM Compile
javac -d "%OUT_DIR%" -cp "%LIB_DIR%\*" @build\sources.txt
if errorlevel 1 (
    echo Compilation failed.
    exit /b 1
)

REM Package
jar cf "%JAR_NAME%" -C "%OUT_DIR%" .

echo Built %JAR_NAME%
