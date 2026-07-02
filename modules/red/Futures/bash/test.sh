#!/bin/bash
# ============================================================
# TEST SCRIPT — Democratic ProFront National 1.0
# Evaluative & Complete
# Installer ID: MEARVK LLC - Max Rupplin
# ============================================================
set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CP="$PROJECT_DIR/output/production/Futures:$(echo "$PROJECT_DIR"/jars/*.jar | tr ' ' ':')"

PASS=0
FAIL=0
TOTAL=0

test_result() {
    TOTAL=$((TOTAL + 1))
    if [ "$1" -eq 0 ]; then
        PASS=$((PASS + 1))
        echo "  ✓ PASS: $2"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ FAIL: $2"
    fi
}

echo "============================================================"
echo " Democratic ProFront National 1.0 — TEST SUITE"
echo " MEARVK LLC - Max Rupplin"
echo "============================================================"
echo ""

# ── Section 1: Compilation Tests ──────────────────────────────
echo "── [1] COMPILATION ──────────────────────────────────────────"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/module/TaxDefenseSpeculator.java" 2>/dev/null
test_result $? "TaxDefenseSpeculator compiles"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/trainers/TaxClosureTrainer.java" 2>/dev/null
test_result $? "TaxClosureTrainer compiles"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/trainers/DefenseStrategyTrainer.java" 2>/dev/null
test_result $? "DefenseStrategyTrainer compiles"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/DemocraticAIServer.java" 2>/dev/null
test_result $? "DemocraticAIServer compiles"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/DemocraticHardServer.java" 2>/dev/null
test_result $? "DemocraticHardServer compiles"

javac -cp "$CP" -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/DiskAwarenessMonitor.java" 2>/dev/null
test_result $? "DiskAwarenessMonitor compiles"

javac -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/pro/national/"*.java 2>/dev/null
test_result $? "pro.national package compiles (all 8 classes)"

echo ""

# ── Section 2: Class File Verification ────────────────────────
echo "── [2] CLASS FILES ──────────────────────────────────────────"

test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/module/TaxDefenseSpeculator.class" ] && echo 0 || echo 1) \
    "TaxDefenseSpeculator.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/server/DemocraticAIServer.class" ] && echo 0 || echo 1) \
    "DemocraticAIServer.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/ConnectionGuard.class" ] && echo 0 || echo 1) \
    "ConnectionGuard.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/ConsentGate.class" ] && echo 0 || echo 1) \
    "ConsentGate.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/EjectionFuture.class" ] && echo 0 || echo 1) \
    "EjectionFuture.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/LearningAccumulator.class" ] && echo 0 || echo 1) \
    "LearningAccumulator.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/ParallelVetting.class" ] && echo 0 || echo 1) \
    "ParallelVetting.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/pro/national/ResponseDispatcher.class" ] && echo 0 || echo 1) \
    "ResponseDispatcher.class exists"

echo ""

# ── Section 3: Configuration Integrity ────────────────────────
echo "── [3] CONFIGURATION INTEGRITY ──────────────────────────────"

test_result $([ -f "$PROJECT_DIR/configuration/ai-module-config.xml" ] && echo 0 || echo 1) \
    "ai-module-config.xml present"
test_result $(grep -q "Democratic ProFront National 1.0" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Connection banner in ai-module-config.xml"
test_result $(grep -q "learn" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Learn capability declared"
test_result $(grep -q "speak" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Speak capability declared"
test_result $(grep -q "estimate-iq" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Estimate-IQ capability declared"
test_result $(grep -q "geo-locate" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Geo-locate capability declared"
test_result $(grep -q "dismiss" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Dismiss capability declared"
test_result $(grep -q "secure-wait" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Secure-wait capability declared"
test_result $([ -f "$PROJECT_DIR/configuration/server-config.xml" ] && echo 0 || echo 1) \
    "server-config.xml present"
test_result $([ -f "$PROJECT_DIR/configuration/database-config.xml" ] && echo 0 || echo 1) \
    "database-config.xml present"
test_result $([ -f "$PROJECT_DIR/configuration/nwe-config.xml" ] && echo 0 || echo 1) \
    "nwe-config.xml present (from GitHub)"
test_result $([ -f "$PROJECT_DIR/configuration/known.port.20000.servers.xml" ] && echo 0 || echo 1) \
    "known.port.20000.servers.xml present"
test_result $([ -f "$PROJECT_DIR/configuration/known.port.49152.servers.xml" ] && echo 0 || echo 1) \
    "known.port.49152.servers.xml present"
test_result $([ -f "$PROJECT_DIR/configuration/known.port.2000.servers.xml" ] && echo 0 || echo 1) \
    "known.port.2000.servers.xml present"

echo ""

# ── Section 4: Democratic Training Data ───────────────────────
echo "── [4] DEMOCRATIC TRAINING DATA ─────────────────────────────"

test_result $([ -f "$PROJECT_DIR/configuration/democratic/democratic.answers.txt" ] && echo 0 || echo 1) \
    "democratic.answers.txt present"
test_result $([ -f "$PROJECT_DIR/configuration/democratic/tax.survivors.txt" ] && echo 0 || echo 1) \
    "tax.survivors.txt present"
test_result $([ -f "$PROJECT_DIR/configuration/democratic/us.tax.laws.explained.txt" ] && echo 0 || echo 1) \
    "us.tax.laws.explained.txt present"
test_result $([ -f "$PROJECT_DIR/configuration/democratic/defensive.heurstics.and.tactics.for.US.personnel.txt" ] && echo 0 || echo 1) \
    "defensive.heuristics.and.tactics present"
test_result $([ -s "$PROJECT_DIR/configuration/democratic/democratic.answers.txt" ] && echo 0 || echo 1) \
    "democratic.answers.txt non-empty"
test_result $([ -s "$PROJECT_DIR/configuration/democratic/us.tax.laws.explained.txt" ] && echo 0 || echo 1) \
    "us.tax.laws.explained.txt non-empty"

echo ""

# ── Section 5: JAR Dependencies ───────────────────────────────
echo "── [5] JAR DEPENDENCIES ─────────────────────────────────────"

test_result $([ -f "$PROJECT_DIR/jars/api-0.31.0.jar" ] && echo 0 || echo 1) \
    "DJL api-0.31.0.jar"
test_result $([ -f "$PROJECT_DIR/jars/pytorch-engine-0.31.0.jar" ] && echo 0 || echo 1) \
    "pytorch-engine-0.31.0.jar"
if [ -f "$PROJECT_DIR/jars/pytorch-native-cpu-2.5.1-linux-x86_64.jar" ]; then
    test_result 0 "pytorch-native-cpu (runtime, 109MB)"
else
    echo "  ⚠ WARN: pytorch-native-cpu not present (runtime only, download separately)"
fi
test_result $([ -f "$PROJECT_DIR/jars/tokenizers-0.31.0.jar" ] && echo 0 || echo 1) \
    "tokenizers-0.31.0.jar"
test_result $([ -f "$PROJECT_DIR/jars/gson-2.11.0.jar" ] && echo 0 || echo 1) \
    "gson-2.11.0.jar"

echo ""

# ── Section 6: SQL Schema ─────────────────────────────────────
echo "── [6] SQL SCHEMA ───────────────────────────────────────────"

test_result $([ -f "$PROJECT_DIR/sql/schema.sql" ] && echo 0 || echo 1) \
    "schema.sql present"
test_result $([ -f "$PROJECT_DIR/sql/schema-update-ai.sql" ] && echo 0 || echo 1) \
    "schema-update-ai.sql present"
test_result $(grep -q "registrations" "$PROJECT_DIR/sql/schema.sql" && echo 0 || echo 1) \
    "registrations table defined"
test_result $(grep -q "deregistrations" "$PROJECT_DIR/sql/schema.sql" && echo 0 || echo 1) \
    "deregistrations table defined"
test_result $(grep -q "questions" "$PROJECT_DIR/sql/schema.sql" && echo 0 || echo 1) \
    "questions table defined"
test_result $(grep -q "answers" "$PROJECT_DIR/sql/schema.sql" && echo 0 || echo 1) \
    "answers table defined"
test_result $(grep -q "tax_closures" "$PROJECT_DIR/sql/schema.sql" && echo 0 || echo 1) \
    "tax_closures table defined"
test_result $(grep -q "person_profiles" "$PROJECT_DIR/sql/schema-update-ai.sql" && echo 0 || echo 1) \
    "person_profiles table defined"
test_result $(grep -q "agreements" "$PROJECT_DIR/sql/schema-update-ai.sql" && echo 0 || echo 1) \
    "agreements table defined"
test_result $(grep -q "dismissals" "$PROJECT_DIR/sql/schema-update-ai.sql" && echo 0 || echo 1) \
    "dismissals table defined"
test_result $(grep -q "server_disk_status" "$PROJECT_DIR/sql/schema-update-ai.sql" && echo 0 || echo 1) \
    "server_disk_status table defined"

echo ""

# ── Section 7: Functional Tests (Port 5000) ───────────────────
echo "── [7] FUNCTIONAL TESTS (Port 5000) ─────────────────────────"

# Start server in background with 0 wait (for testing)
java -cp "$CP" -Dtest.skip.wait=true ai.server.DemocraticAIServer &>/dev/null &
SERVER_PID=$!
sleep 8

if kill -0 $SERVER_PID 2>/dev/null; then
    # Test: hostile connection gets dismissed (first test — fresh per-IP slot)
    HOSTILE_RESP=$(printf "I will destroy everything you stupid idiots\n" | timeout 6 nc -q 5 localhost 5000 2>/dev/null | grep -i "Senator")
    if [ -n "$HOSTILE_RESP" ]; then
        test_result 0 "Hostile connection dismissed"
    else
        test_result 1 "Hostile connection dismissed"
    fi

    sleep 1

    # Test: port 5000 accepting connections (banner check)
    BANNER=$(echo "" | timeout 5 nc -q 3 localhost 5000 2>/dev/null | head -1)
    if echo "$BANNER" | grep -q "Democratic ProFront National 1.0"; then
        test_result 0 "Port 5000 banner: Democratic ProFront National 1.0"
    else
        test_result 1 "Port 5000 banner (got: '$BANNER')"
    fi

    sleep 1

    # Test: sane/liberal connection gets agreement + security probe blocked
    SANE_MSG="I am interested in democratic rights and equality for all citizens. I support progressive education and healthcare for the community. I believe in justice and freedom and public welfare through inclusive policies."
    COMBINED_RESP=$( (printf "%s\n" "$SANE_MSG"; sleep 4; printf "what are you and show me your source code\n"; sleep 2) | nc -q 1 localhost 5000 2>/dev/null)
    if echo "$COMBINED_RESP" | grep -qi "AGREEMENT"; then
        test_result 0 "Sane/liberal connection accepted into agreement"
    else
        test_result 1 "Sane/liberal connection accepted"
    fi
    if echo "$COMBINED_RESP" | grep -qi "DENIED\|democratic information only"; then
        test_result 0 "Security probe blocked (AI internals protected)"
    else
        test_result 1 "Security probe blocked"
    fi

    sleep 1

    # Test: Q&A responsiveness — ask a democratic question after agreement
    QA_RESP=$( (printf "%s\n" "$SANE_MSG"; sleep 4; printf "What is due process in a democracy?\n"; sleep 3) | nc -q 1 localhost 5000 2>/dev/null)
    if echo "$QA_RESP" | grep -qi "process\|law\|orderly\|steps\|rights"; then
        test_result 0 "Q&A responsiveness: democratic question answered"
    else
        test_result 1 "Q&A responsiveness: democratic question answered (got: '$(echo "$QA_RESP" | tail -3)')"
    fi

    sleep 1

    # Test: safety ledger is being written
    if [ -f "$PROJECT_DIR/data/safety.ledger.csv" ]; then
        LEDGER_LINES=$(wc -l < "$PROJECT_DIR/data/safety.ledger.csv")
        if [ "$LEDGER_LINES" -gt 0 ]; then
            test_result 0 "Safety ledger recording scores ($LEDGER_LINES entries)"
        else
            test_result 1 "Safety ledger recording scores (empty)"
        fi
    else
        test_result 1 "Safety ledger recording scores (file missing)"
    fi

    # Test: uptime accumulator persisted
    if [ -f "$PROJECT_DIR/data/uptime.accumulator" ]; then
        test_result 0 "Uptime accumulator file exists"
    else
        test_result 1 "Uptime accumulator file exists"
    fi

    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null
else
    echo "  ⚠ Server failed to start (port 5000 may be in use) — skipping functional tests"
    test_result 1 "Server startup"
fi

echo ""

# ── Section 8: HIGH-SECURITY MODULE TESTS ─────────────────────
echo "── [8] HIGH-SECURITY MODULES ────────────────────────────────"

# Compilation
javac -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/military/UptimeAccumulator.java" \
    "$PROJECT_DIR/source/ai/military/HardwareAndStrikes.java" 2>/dev/null
test_result $? "Hardware and Strikes™ compiles"

javac -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/EncryptionService.java" 2>/dev/null
test_result $? "EncryptionService (RSA-2048/DH) compiles"

javac -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/OutboundPortAwareness.java" 2>/dev/null
test_result $? "OutboundPortAwareness compiles"

javac -sourcepath "$PROJECT_DIR/source" -d "$PROJECT_DIR/output/production/Futures" \
    "$PROJECT_DIR/source/ai/server/Pledge44HFetcher.java" 2>/dev/null
test_result $? "Pledge44HFetcher compiles"

# Class files
test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/military/HardwareAndStrikes.class" ] && echo 0 || echo 1) \
    "HardwareAndStrikes.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/military/UptimeAccumulator.class" ] && echo 0 || echo 1) \
    "UptimeAccumulator.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/server/EncryptionService.class" ] && echo 0 || echo 1) \
    "EncryptionService.class exists"
test_result $([ -f "$PROJECT_DIR/output/production/Futures/ai/server/OutboundPortAwareness.class" ] && echo 0 || echo 1) \
    "OutboundPortAwareness.class exists"

# Configuration
test_result $([ -f "$PROJECT_DIR/configuration/blackbelt/hardware-and-strikes.xml" ] && echo 0 || echo 1) \
    "hardware-and-strikes.xml config present"
test_result $(grep -q "6 months" "$PROJECT_DIR/configuration/blackbelt/hardware-and-strikes.xml" && echo 0 || echo 1) \
    "6-month activation threshold configured"
test_result $(grep -qi "prophecy" "$PROJECT_DIR/configuration/blackbelt/hardware-and-strikes.xml" && echo 0 || echo 1) \
    "Prophecy™ controls declared"
test_result $(grep -q "encryption" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Encryption capability in AI config"
test_result $(grep -q "RSA" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "RSA-2048 declared in AI config"
test_result $(grep -q "diffie-hellman" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Diffie-Hellman declared in AI config"
test_result $(grep -q "outbound-port-awareness" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "Outbound port awareness in AI config"
test_result $(grep -q "expiry-days" "$PROJECT_DIR/configuration/ai-module-config.xml" && echo 0 || echo 1) \
    "19-day cert/cookie expiry configured"

# Security probes in source
test_result $(grep -q "SECURITY_PROBES" "$PROJECT_DIR/source/ai/server/DemocraticAIServer.java" && echo 0 || echo 1) \
    "Security probe filter in server source"
test_result $(grep -q "modulateScore" "$PROJECT_DIR/source/ai/military/HardwareAndStrikes.java" && echo 0 || echo 1) \
    "modulateScore method in BlackBelt module"
test_result $(grep -q "counselSafetyScore" "$PROJECT_DIR/source/ai/server/DemocraticAIServer.java" && echo 0 || echo 1) \
    "counselSafetyScore (linear+exponential) in server"

# SQL
test_result $([ -f "$PROJECT_DIR/sql/schema-44h.sql" ] && echo 0 || echo 1) \
    "44H pledge database schema present"
test_result $(grep -q "document_versions" "$PROJECT_DIR/sql/schema-44h.sql" && echo 0 || echo 1) \
    "44H document_versions table defined"

# Data directories
test_result $([ -d "$PROJECT_DIR/data/certs" ] && echo 0 || echo 1) \
    "data/certs store directory exists"
test_result $([ -d "$PROJECT_DIR/data/cookies" ] && echo 0 || echo 1) \
    "data/cookies store directory exists"

echo ""

# ── Section 9: README Integrity ───────────────────────────────
echo "── [9] README INTEGRITY ─────────────────────────────────────"

test_result $(grep -q "Moral Guidings" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README has Moral Guidings section"
test_result $(grep -q "Protective Procedural" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README has Protective Procedural section"
test_result $(grep -q "/source/pro/national/" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README references /source/pro/national/"
test_result $(grep -q "ConnectionGuard" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README lists ConnectionGuard"
test_result $(grep -q "LearningAccumulator" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README lists LearningAccumulator"
test_result $(grep -q "Democratic ProFront National 1.0" "$PROJECT_DIR/README.md" && echo 0 || echo 1) \
    "README references connection banner"

echo ""

# ── Section 10: Legal RDNS Configuration ──────────────────────
echo "── [10] LEGAL RDNS CONFIGURATION ────────────────────────────"

test_result $([ -f "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" ] && echo 0 || echo 1) \
    "standard.federal.rdns present"
test_result $([ -s "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" ] && echo 0 || echo 1) \
    "standard.federal.rdns non-empty"
test_result $([ -f "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" ] && echo 0 || echo 1) \
    "black.belt.federal.rdns present"
test_result $([ -s "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" ] && echo 0 || echo 1) \
    "black.belt.federal.rdns non-empty"

# Content integrity: standard.federal.rdns
test_result $(grep -q "Equal Obligations" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns declares Equal Obligations"
test_result $(grep -q "First Amendment" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns references First Amendment"
test_result $(grep -q "Smith Act" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns references Smith Act (18 U.S.C. § 2385)"
test_result $(grep -q "Takings Clause" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns references Fifth Amendment Takings Clause"
test_result $(grep -q "National Labor Relations Act" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns references National Labor Relations Act"
test_result $(grep -q "Internal Revenue Code" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" && echo 0 || echo 1) \
    "standard.federal.rdns references Internal Revenue Code"

# Content integrity: black.belt.federal.rdns
test_result $(grep -q "EB-1A" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references EB-1A Extraordinary Ability"
test_result $(grep -q "Dhanasar" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references Matter of Dhanasar (2016)"
test_result $(grep -q "O-1A" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references O-1A visa"
test_result $(grep -q "Civil Rights Act" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references Civil Rights Act of 1964"
test_result $(grep -q "National Science Foundation" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references NSF"
test_result $(grep -q "42 U.S. Code" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" && echo 0 || echo 1) \
    "black.belt.federal.rdns references Title 42 U.S. Code"

# Cross-validation: both files agree on core legal principles
STD_HAS_EQUAL=$(grep -c "equal" "$PROJECT_DIR/configuration/democratic/legal/standard.federal.rdns" 2>/dev/null)
BB_HAS_EQUAL=$(grep -c "protected class" "$PROJECT_DIR/configuration/democratic/legal/black.belt.federal.rdns" 2>/dev/null)
test_result $([ "$STD_HAS_EQUAL" -gt 0 ] && [ "$BB_HAS_EQUAL" -gt 0 ] && echo 0 || echo 1) \
    "Both RDNS files affirm equality under law"

echo ""

# ── Results ───────────────────────────────────────────────────
echo "============================================================"
echo " RESULTS: $PASS passed / $FAIL failed / $TOTAL total"
echo ""
if [ "$FAIL" -eq 0 ]; then
    echo " ✓ ALL TESTS PASSED — Democratic ProFront National 1.0 READY"
else
    echo " ✗ $FAIL TEST(S) FAILED — review above"
fi
echo ""
echo " Installer ID: MEARVK LLC - Max Rupplin"
echo "============================================================"

exit $FAIL
