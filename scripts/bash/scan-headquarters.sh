#!/bin/bash
# scan-headquarters.sh — Scan for new information on 555 South Mangum St, Durham, NC 27701
# Run at startup or periodically to update HEADQUARTERS.data with fresh public records

DATAFILE="$(dirname "$0")/../HEADQUARTERS.data"
LOGFILE="$(dirname "$0")/../logging/headquarters-scan.log"
SEARCH_TERMS=("555+South+Mangum+Durham+NC" "555+Mangum+Accesso+Partners" "555+Mangum+Durham+tenants")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

mkdir -p "$(dirname "$LOGFILE")"

echo "[$TIMESTAMP] Headquarters scan started" >> "$LOGFILE"

for TERM in "${SEARCH_TERMS[@]}"; do
  URL="https://www.google.com/search?q=${TERM}&tbs=qdr:m"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL" 2>/dev/null)
  echo "[$TIMESTAMP] Query: $TERM — HTTP $STATUS" >> "$LOGFILE"
done

# Check if building ownership has changed (look for sale announcements)
OWNERSHIP_CHECK=$(curl -s --max-time 15 "https://traded.co/deals/north-carolina/office/sale/555-south-mangum-street" 2>/dev/null | grep -i "acqui\|sold\|purchase" | head -5)
if [ -n "$OWNERSHIP_CHECK" ]; then
  echo "[$TIMESTAMP] Ownership signals detected:" >> "$LOGFILE"
  echo "$OWNERSHIP_CHECK" >> "$LOGFILE"
fi

echo "[$TIMESTAMP] Headquarters scan complete. Review $LOGFILE for updates." >> "$LOGFILE"
echo "Headquarters scan complete — see $LOGFILE"
