#!/bin/bash
# ArmorerSteve™ module — start both backend and frontend
cd "$(dirname "$0")"
echo "[ArmorerSteve] Starting backend on port 49235..."
java -cp "../../source:../../lib/*:../../jars/*" source.ArmorerSteveServer &
echo "[ArmorerSteve] Backend PID: $!"
echo "[ArmorerSteve] Frontend served via Tomcat (deploy servlet WAR)"
