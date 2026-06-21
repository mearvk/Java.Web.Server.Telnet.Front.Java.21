@echo off
REM Reassembles pytorch-native-cpu-2.5.1-linux-x86_64.jar from split parts if not already present
set "DIR=%~dp0"
set "JAR=%DIR%pytorch-native-cpu-2.5.1-linux-x86_64.jar"

if exist "%JAR%" exit /b 0

copy /b "%DIR%native_pytorch_cpu_linux_x86_64_aa"+"%DIR%native_pytorch_cpu_linux_x86_64_ab" "%JAR%"
echo Reassembled pytorch-native-cpu-2.5.1-linux-x86_64.jar
