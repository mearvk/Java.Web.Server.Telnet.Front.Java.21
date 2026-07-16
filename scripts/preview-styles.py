#!/usr/bin/env python3
"""
NitroWebExpress™ — Local Style Preview Server

Serves module webapp directories as static files for CSS/layout/button preview.
JSP scriptlets won't execute (they show as raw text), but you can check:
  - Color themes and CSS styling
  - Button placement and CD1 connector dialog
  - Page layout and responsiveness
  - Navigation structure

Usage:
    python3 scripts/preview-styles.py [port]

Then open:
    http://localhost:9090/vietnam/        — Vietnam module (light brown)
    http://localhost:9090/emeter/         — Emeter module (light blue)
    http://localhost:9090/california-fbi/ — FBI module (red)
    http://localhost:9090/brarner.m.alete/— BMA module (blue)
    ... etc.

Press Ctrl+C to stop.
"""

import http.server
import os
import sys
import shutil

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9090
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Map context paths to webapp source directories
MODULES = {
    "vietnam": "modules/vietnam/servlets/servlet/src/main/webapp",
    "emeter": "modules/emeter/servlets/servlet/src/main/webapp",
    "california-fbi": "modules/fbi/servlets/servlet/src/main/webapp",
    "california-cia": "modules/cia/servlets/servlet/src/main/webapp",
    "california-nsa": "modules/nsa/servlets/servlet/src/main/webapp",
    "california-duke": "modules/duke/servlets/servlet/src/main/webapp",
    "library": "modules/library/servlets/servlet/src/main/webapp",
    "gray-registry": "modules/gray/servlets/servlet/src/main/webapp",
    "gray85-registry": "modules/gray.a85/servlets/servlet/src/main/webapp",
    "futures": "modules/red/Futures/servlets/servlet/src/main/webapp",
    "ae6e66": "modules/AE6E66/servlets/servlet/src/main/webapp",
    "blackbelt": "modules/black-belt/servlets/servlet/src/main/webapp",
    "languages": "modules/languages/servlets/servlet/src/main/webapp",
    "brarner.m.alete": "modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp",
}

# Build a temporary serve directory with symlinks/copies
SERVE_DIR = os.path.join(PROJECT_ROOT, ".preview-serve")
os.makedirs(SERVE_DIR, exist_ok=True)

# Create an index page
index_html = """<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>NWE Style Preview</title>
<style>body{font-family:system-ui;background:#111;color:#eee;padding:2rem;}
a{color:#60a5fa;text-decoration:none;display:block;padding:0.5rem 0;}
a:hover{color:#93c5fd;}h1{color:#fff;}table{border-collapse:collapse;width:100%;}
td,th{padding:0.5rem 1rem;text-align:left;border-bottom:1px solid #333;}
th{color:#999;}</style></head><body>
<h1>NitroWebExpress&trade; &mdash; Style Preview</h1>
<p style="color:#999;">JSP server-side code won't execute (shows as raw text). CSS, layout, buttons, and JS dialogs work normally.</p>
<table><thead><tr><th>Module</th><th>Theme</th><th>Port</th></tr></thead><tbody>
"""
for ctx, path in sorted(MODULES.items()):
    full = os.path.join(PROJECT_ROOT, path)
    if os.path.isdir(full):
        index_html += f'<tr><td><a href="/{ctx}/index.jsp">{ctx}</a></td><td></td><td></td></tr>\n'
index_html += "</tbody></table></body></html>"

with open(os.path.join(SERVE_DIR, "index.html"), "w") as f:
    f.write(index_html)

# Create directory junctions/symlinks for each module
for ctx, path in MODULES.items():
    full = os.path.join(PROJECT_ROOT, path)
    link = os.path.join(SERVE_DIR, ctx)
    if os.path.isdir(full):
        if os.path.exists(link):
            if os.path.islink(link) or os.path.isdir(link):
                try:
                    os.remove(link)
                except:
                    try:
                        os.rmdir(link)
                    except:
                        pass
        try:
            os.symlink(full, link, target_is_directory=True)
        except OSError:
            # Windows without developer mode: use junction
            os.system(f'mklink /J "{link}" "{full}" >nul 2>&1')

os.chdir(SERVE_DIR)

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.jsp': 'text/html',  # Serve JSP as HTML so browser renders the markup
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.svg': 'image/svg+xml',
    }
    def log_message(self, format, *args):
        # Only log actual page requests, not assets
        if '.css' not in args[0] and '.js' not in args[0] and '.png' not in args[0]:
            super().log_message(format, *args)

print(f"""
╔═══════════════════════════════════════════════════════════════════════════╗
║  NitroWebExpress™ — Style Preview Server                                  ║
║  http://localhost:{PORT}/                                                    ║
║                                                                           ║
║  Modules:                                                                 ║
║    http://localhost:{PORT}/vietnam/index.jsp       (light brown)              ║
║    http://localhost:{PORT}/emeter/index.jsp        (light blue)               ║
║    http://localhost:{PORT}/california-fbi/index.jsp (red)                     ║
║    http://localhost:{PORT}/brarner.m.alete/index.jsp (blue)                   ║
║                                                                           ║
║  NOTE: JSP scriptlets show as raw text. CSS/JS/layout works normally.     ║
║  Press Ctrl+C to stop.                                                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

try:
    with http.server.HTTPServer(("", PORT), QuietHandler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n[*] Preview server stopped.")
finally:
    # Cleanup symlinks
    for ctx in MODULES:
        link = os.path.join(SERVE_DIR, ctx)
        try:
            os.remove(link)
        except:
            os.system(f'rmdir "{link}" >nul 2>&1')
    try:
        os.remove(os.path.join(SERVE_DIR, "index.html"))
        os.rmdir(SERVE_DIR)
    except:
        pass
