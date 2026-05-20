#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# build_cv.sh — inietta il JSON reale nel template HTML
#
# Uso:
#   ./build_cv.sh resume.json
#   ./build_cv.sh resume.json -t altro.html
#   ./build_cv.sh resume.json -o output.html
#   ./build_cv.sh resume.json -t altro.html -o output.html
#
# Output: resume-out.html (aprilo nel browser, poi Ctrl+P per il PDF)
# ──────────────────────────────────────────────────────────────
set -euo pipefail

usage() {
  cat >&2 <<EOF
Uso: $0 <file.json> [-t template.html] [-o output.html] [-h]

Argomenti:
  <file.json>          File JSON con i dati del CV (obbligatorio)

Opzioni:
  -t <template.html>   Template HTML da usare       (default: template.html)
  -o <output.html>     File HTML di output           (default: resume-out.html)
  -h, --help           Mostra questo messaggio di aiuto

Esempio:
  $0 resume.json
  $0 resume.json -t altro.html -o cv-mario.html
EOF
  exit "${1:-0}"
}

# ── Help anticipato (--help non è gestito da getopts) ─────────
for arg in "$@"; do
  [[ "$arg" == "--help" ]] && usage 0
done

# ── JSON obbligatorio come primo argomento ─────────────────────
[[ $# -lt 1 || "$1" == -* ]] && usage 1
JSON_FILE="$1"
shift

# ── Parametri opzionali ────────────────────────────────────────
TEMPLATE="template.html"
OUTPUT="resume-out.html"

while getopts ":t:o:h" opt; do
  case $opt in
    t) TEMPLATE="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    h) usage 0 ;;
    :) echo "✗ Il parametro -$OPTARG richiede un valore." >&2; usage 1 ;;
    \?) echo "✗ Parametro sconosciuto: -$OPTARG" >&2; usage 1 ;;
  esac
done

# ── Controlli ─────────────────────────────────────────────────
[[ -f "$JSON_FILE" ]] || { echo "✗ JSON non trovato: $JSON_FILE" >&2; exit 1; }
[[ -f "$TEMPLATE" ]]  || { echo "✗ Template non trovato: $TEMPLATE" >&2; exit 1; }

# ── Valida e formatta il JSON ──────────────────────────────────
if command -v jq &>/dev/null; then
  jq empty "$JSON_FILE" 2>/dev/null || { echo "✗ JSON non valido: $JSON_FILE" >&2; exit 1; }
  JSON_CONTENT=$(jq '.' "$JSON_FILE")
else
  echo "⚠ jq non trovato — JSON incluso senza validazione."
  JSON_CONTENT=$(cat "$JSON_FILE")
fi

# ── Sostituisce __CV_DATA__ con il JSON reale ──────────────────
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
