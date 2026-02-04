# scripts/make_dmg.sh
#!/usr/bin/env bash
set -euo pipefail

# ========= Konfiguration =========
APP_NAME="${APP_NAME:-Redactly}"
VOL_NAME="${VOL_NAME:-${APP_NAME} Installer}"
STAGE_APP="${STAGE_APP:-.publisher/stage/${APP_NAME}.app}"
OUT_DIR="${OUT_DIR:-dist}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_NOTARY}"

# Flags
DO_NOTARIZE=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-notary) DO_NOTARIZE=false; shift ;;
    --volname) VOL_NAME="$2"; shift 2 ;;
    --app) STAGE_APP="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --profile) NOTARY_PROFILE="$2"; shift 2 ;;
    *) echo "Unbekannter Parameter: $1"; exit 2 ;;
  esac
done

# ========= Preflight =========
command -v create-dmg >/dev/null || { echo "✖ create-dmg fehlt (brew install create-dmg)"; exit 1; }
command -v xcrun >/dev/null      || { echo "✖ Xcode Command Line Tools fehlen"; exit 1; }
[[ -d "$STAGE_APP" ]]            || { echo "✖ Staging-App fehlt: $STAGE_APP"; exit 1; }
mkdir -p "$OUT_DIR"

# Version ermitteln (z.B. 0.2.1) aus pubspec.yaml
if [[ -f pubspec.yaml ]]; then
  BUILD_NAME="$(awk '/^version:/{print $2}' pubspec.yaml | cut -d+ -f1)"
else
  BUILD_NAME="dev"
fi
DMG_OUT="${OUT_DIR}/${APP_NAME}-macOS-${BUILD_NAME}.dmg"

# ========= DMG erstellen =========
MOUNTPOINT="/Volumes/${VOL_NAME}"
if mount | grep -q "$MOUNTPOINT"; then
  echo "• Aushängen: $MOUNTPOINT"
  hdiutil detach "$MOUNTPOINT" -quiet || true
fi

echo "• Erzeuge DMG: $DMG_OUT"
rm -f "$DMG_OUT"
create-dmg \
  --volname "${VOL_NAME}" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 150 200 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 450 200 \
  "$DMG_OUT" \
  "$(dirname "$STAGE_APP")"

# ========= Notarisieren (optional abschaltbar) =========
if $DO_NOTARIZE; then
  echo "• Notarisieren…"
  # Prüfen, ob Profile nutzbar sind
  if ! xcrun notarytool validate-credentials --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
    echo "✖ notarytool profile '${NOTARY_PROFILE}' ungültig. (xcrun notarytool store-credentials '${NOTARY_PROFILE}' …)"
    exit 1
  fi

  SUBMIT_JSON="$(xcrun notarytool submit "$DMG_OUT" --keychain-profile "$NOTARY_PROFILE" --output-format json 2>/dev/null || true)"
  SUB_ID="$(python3 - <<'PY' 2>/dev/null <<<"$SUBMIT_JSON"
import sys,json
try:
  j=json.load(sys.stdin)
  print(j.get("id",""))
except:
  print("")
PY
)"
  if [[ -z "$SUB_ID" ]]; then
    echo "✖ Konnte submissionId nicht auslesen. Rohantwort:"
    echo "$SUBMIT_JSON"
    exit 1
  fi
  echo "  submissionId: $SUB_ID"

  echo "• Warte auf 'Accepted'…"
  while :; do
    STATUS="$(xcrun notarytool info "$SUB_ID" --keychain-profile "$NOTARY_PROFILE" --output-format json \
      | python3 - <<'PY'
import sys,json
try:
  j=json.load(sys.stdin)
  print(j.get("status",""))
except:
  print("")
PY
    )"
    [[ -n "$STATUS" ]] && echo "  status: $STATUS"
    if [[ "$STATUS" == "Accepted" ]]; then
      break
    elif [[ "$STATUS" == "Invalid" ]]; then
      echo "✖ Notarisierung INVALID – Log:"
      xcrun notarytool log "$SUB_ID" --keychain-profile "$NOTARY_PROFILE" | sed -n '1,200p' || true
      exit 2
    fi
    sleep 30
  done

  echo "• Staple DMG…"
  xcrun stapler staple "$DMG_OUT" >"$OUT_DIR/stapler_dmg.log" 2>&1

  echo "• Validate DMG Staple…"
  xcrun stapler validate "$DMG_OUT"
else
  echo "• Notarisierung übersprungen (--no-notary)."
fi

# ========= Checksums =========
echo "• Schreibe SHA-256 Checksums…"
(
  cd "$OUT_DIR"
  rm -f checksums.txt
  shasum -a 256 "$(basename "$DMG_OUT")" > checksums.txt
)

echo "✅ Fertig: $DMG_OUT"
