#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# build_cv.sh — inietta il JSON reale nel template HTML
#
# Uso:
#   ./build_cv.sh                        → usa resume.json + template.html
#   ./build_cv.sh dati.json              → JSON custom, template default
#   ./build_cv.sh dati.json altro.html   → JSON e template custom
#
# Output: resume_out.html (aprilo nel browser, poi Ctrl+P per il PDF)
# ──────────────────────────────────────────────────────────────
set -euo pipefail

JSON_FILE="${1:-resume.json}"
TEMPLATE="${2:-template.html}"
OUTPUT="resume_out.html"

# ── Controlli ─────────────────────────────────
[[ -f "$JSON_FILE" ]]  || { echo "✗ JSON non trovato: $JSON_FILE" >&2; exit 1; }
[[ -f "$TEMPLATE" ]]   || { echo "✗ Template non trovato: $TEMPLATE" >&2; exit 1; }

# ── Valida e formatta il JSON ──────────────────
if command -v jq &>/dev/null; then
  jq empty "$JSON_FILE" 2>/dev/null || { echo "✗ JSON non valido: $JSON_FILE" >&2; exit 1; }
  JSON_CONTENT=$(jq '.' "$JSON_FILE")
else
  echo "⚠ jq non trovato — JSON incluso senza validazione."
  JSON_CONTENT=$(cat "$JSON_FILE")
fi

# ── Sostituisce __CV_DATA__ con il JSON reale ──
# Usa Python per l'escape sicuro: evita problemi con caratteri
# speciali (apici, backslash, newline) nel sed.
python3 - "$TEMPLATE" "$OUTPUT" "$JSON_CONTENT" <<'PYEOF'
import sys

template_path = sys.argv[1]
output_path   = sys.argv[2]
json_content  = sys.argv[3]

with open(template_path, 'r', encoding='utf-8') as f:
    html = f.read()

if '__CV_DATA__' not in html:
    print("✗ Placeholder '__CV_DATA__' non trovato nel template.", file=sys.stderr)
    sys.exit(1)

result = html.replace('__CV_DATA__', json_content, 1)

with open(output_path, 'w', encoding='utf-8') as f:
    f.write(result)
PYEOF

echo "✓ CV generato → $OUTPUT"
