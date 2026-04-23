#!/bin/bash

split -n 4 ibm-sdk-8.zip ibm-sdk-8_

cat ibm-sdk-_* > ibm-sdk-8.zip
