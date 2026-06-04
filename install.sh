#!/usr/bin/env bash
# RAPP Brainstem — Brain Surgeon (beta) one-liner installer.
#   curl -fsSL https://raw.githubusercontent.com/kody-w/rapp-brainstem-beta/beta/install.sh | bash
# Clones the beta, injects a single <script> line (the scalpel) into your brainstem UI
# (with a backup), and launches the surgeon sidecar. The stable installer repo is untouched.
set -euo pipefail

REPO_URL="${BRAIN_SURGEON_REPO:-https://github.com/kody-w/rapp-brainstem-beta.git}"
DEST="${BRAIN_SURGEON_HOME:-$HOME/.brain-surgeon}"
PORT="${SURGEON_PORT:-7072}"
BRAINSTEM_INDEX="${BRAINSTEM_INDEX:-$HOME/.brainstem/src/rapp_brainstem/index.html}"

echo "🔪 Installing RAPP Brainstem Brain Surgeon (beta)…"

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" fetch --quiet origin beta && git -C "$DEST" reset --hard --quiet origin/beta
else
  git clone --quiet --branch beta "$REPO_URL" "$DEST"
fi

# Inject the scalpel overlay (one line) into the brainstem UI — idempotent, with backup.
if [ -f "$BRAINSTEM_INDEX" ]; then
  PORT="$PORT" python3 - "$BRAINSTEM_INDEX" <<'PYEOF'
import os, sys
p = sys.argv[1]; port = os.environ.get("PORT", "7072")
s = open(p, encoding="utf-8").read()
if "overlay.js" in s:
    print("   scalpel overlay already present — skipped")
else:
    open(p + ".pre-surgeon.bak", "w", encoding="utf-8").write(s)
    line = f'  <script src="http://localhost:{port}/overlay.js" defer></script>\n'
    i = s.rfind("</body>")
    s = (s[:i] + line + s[i:]) if i != -1 else (s + "\n" + line)
    open(p, "w", encoding="utf-8").write(s)
    print(f"   injected scalpel overlay into {p} (backup: {p}.pre-surgeon.bak)")
PYEOF
else
  echo "   ⚠️  brainstem index.html not found at $BRAINSTEM_INDEX"
  echo "      Set BRAINSTEM_INDEX, or add this line before </body> yourself:"
  echo "      <script src=\"http://localhost:${PORT}/overlay.js\" defer></script>"
fi

echo "   Launching the surgeon sidecar (Ctrl-C to stop)…"
exec "$DEST/start.sh"
