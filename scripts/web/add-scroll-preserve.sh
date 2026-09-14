#!/bin/bash
# ============================================================================
# NitroWebExpress™ — Add Scroll Preservation to All DIGTIK Pages (JSPs)
# Copies scroll-preserve.js into each webapp's js/ directory and injects
# the <script> tag into every JSP that doesn't already have it.
# Safe to run multiple times — skips pages that already include the script.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_JS="$SCRIPT_DIR/js/scroll-preserve.js"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Add Scroll Preservation to DIGTIK Pages"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$SOURCE_JS" ]; then
    echo "[!] Source JS not found: $SOURCE_JS"
    exit 1
fi

TOTAL_PAGES=0
INJECTED=0
SKIPPED=0
COPIED_JS=0

# Find all webapp directories that contain JSP files
find "$PROJECT_ROOT" -path "*/webapp/*.jsp" -not -path "*/WEB-INF/*" | while read -r jsp; do
    echo "$jsp"
done | sort -u | while read -r JSP_FILE; do

    # Determine the webapp root (directory containing WEB-INF or the parent of the JSP's relative path)
    WEBAPP_DIR=$(echo "$JSP_FILE" | sed 's|\(.*webapp\)/.*|\1|')

    # Ensure js/ directory exists in the webapp
    JS_DIR="$WEBAPP_DIR/js"
    if [ ! -d "$JS_DIR" ]; then
        mkdir -p "$JS_DIR"
    fi

    # Copy scroll-preserve.js if not present or outdated
    if [ ! -f "$JS_DIR/scroll-preserve.js" ] || ! cmp -s "$SOURCE_JS" "$JS_DIR/scroll-preserve.js"; then
        cp "$SOURCE_JS" "$JS_DIR/scroll-preserve.js"
        COPIED_JS=$((COPIED_JS + 1))
    fi

    TOTAL_PAGES=$((TOTAL_PAGES + 1))

    # Check if already injected
    if grep -q "scroll-preserve.js" "$JSP_FILE"; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Determine relative path prefix (for JSPs in subdirectories like admin/)
    REL_PATH=$(echo "$JSP_FILE" | sed "s|${WEBAPP_DIR}/||")
    DEPTH=$(echo "$REL_PATH" | tr '/' '\n' | wc -l)
    PREFIX=""
    if [ "$DEPTH" -gt 1 ]; then
        for i in $(seq 2 $DEPTH); do PREFIX="../$PREFIX"; done
    fi

    # Inject the script tag before </head> if </head> exists
    if grep -q "</head>" "$JSP_FILE"; then
        sed -i "s|</head>|<script src=\"${PREFIX}js/scroll-preserve.js\"></script>\n</head>|" "$JSP_FILE"
        INJECTED=$((INJECTED + 1))
    elif grep -q "</body>" "$JSP_FILE"; then
        # Fallback: inject before </body>
        sed -i "s|</body>|<script src=\"${PREFIX}js/scroll-preserve.js\"></script>\n</body>|" "$JSP_FILE"
        INJECTED=$((INJECTED + 1))
    else
        echo "    [!] No </head> or </body> in: $JSP_FILE"
        SKIPPED=$((SKIPPED + 1))
    fi
done

# Also handle smartphone pages (outside webapp/ structure)
echo ""
echo "[*] Checking smartphone pages..."
find "$PROJECT_ROOT" -path "*/smartphone/*.jsp" | while read -r JSP_FILE; do
    PARENT_DIR=$(dirname "$JSP_FILE")
    JS_DIR="$PARENT_DIR/js"
    mkdir -p "$JS_DIR"
    if [ ! -f "$JS_DIR/scroll-preserve.js" ] || ! cmp -s "$SOURCE_JS" "$JS_DIR/scroll-preserve.js"; then
        cp "$SOURCE_JS" "$JS_DIR/scroll-preserve.js"
    fi
    if ! grep -q "scroll-preserve.js" "$JSP_FILE"; then
        if grep -q "</head>" "$JSP_FILE"; then
            sed -i 's|</head>|<script src="js/scroll-preserve.js"></script>\n</head>|' "$JSP_FILE"
            echo "    Injected: $JSP_FILE"
        fi
    fi
done

echo ""
echo "[✓] Done"
echo ""

# Re-count since subshell loses vars
TOTAL=$(find "$PROJECT_ROOT" -path "*/webapp/*.jsp" -not -path "*/WEB-INF/*" | wc -l)
ALREADY=$(grep -rl "scroll-preserve.js" "$PROJECT_ROOT" --include="*.jsp" 2>/dev/null | wc -l)
echo "     Total JSP pages found:    $TOTAL"
echo "     Pages with scroll-preserve: $ALREADY"
echo ""
echo "═══════════════════════════════════════════════════════════════"
