#!/bin/bash
#1
split -n 18 graalvm-jdk-25.0.3_linux-x64_bin.tar.gz graal-sdk-25_

cat graal-sdk-25_* > graal-sdk-25.zip
