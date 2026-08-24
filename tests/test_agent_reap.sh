#!/bin/bash
# must-fail: an orphaned headless chrome and an orphaned node are reported.
# must-pass: a windowed Chrome (ppid 1, no --headless) and a parented node are not.
set -u; here=$(cd "$(dirname "$0")/.." && pwd)
snap=$(mktemp)
cat > "$snap" <<'PS'
437 1 /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
900 437 /Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Helpers/Google Chrome Helper (Renderer).app --type=renderer
910 1 /Applications/Google Chrome.app/Contents/MacOS/Google Chrome --headless --remote-debugging-port=9222
920 1 node /Users/x/.cache/ms-playwright/driver.js
930 4321 node /Users/x/dev/app/server.js
940 1967 /Users/x/.kimi-bridge/venv/lib/python3.13/site-packages/playwright/driver/node bridge
PS
out=$(AGENT_REAP_PS="$snap" "$here/bin/agent-reap"); rc=$?
echo "$out"
grep -q "pid=910" <<<"$out" && grep -q "pid=920" <<<"$out" && ! grep -q "pid=437\|pid=900\|pid=930" <<<"$out" && [ $rc = 1 ] && echo PASS && exit 0
echo FAIL; exit 1
