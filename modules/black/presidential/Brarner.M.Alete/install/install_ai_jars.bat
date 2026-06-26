@echo off
echo --- Downloading AI/ML JARs ---
set JARS_DIR=%~dp0..\jars\ai
if not exist "%JARS_DIR%" mkdir "%JARS_DIR%"

set DJL_VER=0.36.0

echo Downloading DJL API...
curl.exe -L -s -o "%JARS_DIR%\djl-api-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/api/%DJL_VER%/api-%DJL_VER%.jar"

echo Downloading DJL PyTorch Engine...
curl.exe -L -s -o "%JARS_DIR%\pytorch-engine-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-engine/%DJL_VER%/pytorch-engine-%DJL_VER%.jar"

echo Downloading PyTorch Native Auto...
curl.exe -L -s -o "%JARS_DIR%\pytorch-native-auto-2.7.1.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-auto/2.7.1/pytorch-native-auto-2.7.1.jar"

echo Downloading PyTorch JNI...
curl.exe -L -s -o "%JARS_DIR%\pytorch-jni-2.7.1-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-jni/2.7.1-%DJL_VER%/pytorch-jni-2.7.1-%DJL_VER%.jar"

echo Downloading DJL Model Zoo...
curl.exe -L -s -o "%JARS_DIR%\model-zoo-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/model-zoo/%DJL_VER%/model-zoo-%DJL_VER%.jar"

echo Downloading DJL Basic Dataset...
curl.exe -L -s -o "%JARS_DIR%\basicdataset-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/basicdataset/%DJL_VER%/basicdataset-%DJL_VER%.jar"

echo Downloading DJL ONNX Runtime Engine Adapter...
curl.exe -L -s -o "%JARS_DIR%\onnxruntime-engine-%DJL_VER%.jar" "https://repo1.maven.org/maven2/ai/djl/onnxruntime/onnxruntime/%DJL_VER%/onnxruntime-%DJL_VER%.jar"

echo Downloading ONNX Runtime (Microsoft 1.19.2)...
curl.exe -L -s -o "%JARS_DIR%\onnxruntime-1.19.2.jar" "https://repo1.maven.org/maven2/com/microsoft/onnxruntime/onnxruntime/1.19.2/onnxruntime-1.19.2.jar"

echo Downloading PyTorch Native CPU (Windows x86_64 - ~75MB)...
curl.exe -L -s -o "%JARS_DIR%\pytorch-native-cpu-2.7.1-win-x86_64.jar" "https://repo1.maven.org/maven2/ai/djl/pytorch/pytorch-native-cpu/2.7.1/pytorch-native-cpu-2.7.1-win-x86_64.jar"

echo Downloading Gson (DJL dependency)...
curl.exe -L -s -o "%JARS_DIR%\gson-2.11.0.jar" "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"

echo Downloading SLF4J API (DJL dependency)...
curl.exe -L -s -o "%JARS_DIR%\slf4j-api-2.0.16.jar" "https://repo1.maven.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar"

echo Downloading SLF4J Simple (logging backend)...
curl.exe -L -s -o "%JARS_DIR%\slf4j-simple-2.0.16.jar" "https://repo1.maven.org/maven2/org/slf4j/slf4j-simple/2.0.16/slf4j-simple-2.0.16.jar"

echo.
echo AI JARs installed:
dir "%JARS_DIR%\*.jar"
