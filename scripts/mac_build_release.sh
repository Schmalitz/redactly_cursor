#!/usr/bin/env bash
set -euo pipefail

# --- Locale: CocoaPods/Ruby brauchen UTF-8 ---
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

########## 🔁 App-/Projekt-Variablen ##########
APP_NAME="Redactly"
BUNDLE_ID="com.plaintools.redactly"
DEVID_NAME="Developer ID Application: TILO HANS-GEERD SCHMIDTSDORFF (LXM9DM8VCP)"
ENTITLEMENTS="macos/Runner/Release.entitlements"
NOTARY_PROFILE="AC_NOTARY"
###############################################

# Farben/Utils
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
info(){ echo -e "${GREEN}▶︎ $*${NC}"; }
warn(){ echo -e "${YELLOW}⚠ $*${NC}"; }
abort(){ echo -e "${RED}✖ $*${NC}"; exit 1; }

# Pfade
BUILD_APP="build/macos/Build/Products/Release/${APP_NAME}.app"
STAGE_ROOT=".publisher/stage"
STAGE_APP="${STAGE_ROOT}/${APP_NAME}.app"
LOG_DIR=".publisher/logs"
JOB_JSON=".publisher/job.json"
OUT_DIR="dist"
ZIP_NOTARY="${STAGE_ROOT}/${APP_NAME}-notary.zip"
ZIP_OUT="${OUT_DIR}/${APP_NAME}-macOS-__VERSION__-stapled.zip" # __VERSION__ wird später ersetzt
DMG_OUT="${OUT_DIR}/${APP_NAME}-macOS-__VERSION__.dmg"
VOL_NAME="${APP_NAME} Installer"

mkdir -p "$LOG_DIR"

# Flags (können durch interaktiven Modus überschrieben werden)
DO_FROM_SCRATCH=false
DO_RESUME=false
DO_WITH_DMG=false
DO_CLEAN_ONLY=false
DO_SKIP_BUILD=false
if [[ $# -eq 0 ]]; then
  echo "================= ${APP_NAME} Publisher ================="
  echo "1) From scratch (Clean → Build → Sign → Notarize → Staple → ZIP[/DMG])"
  echo "2) Resume (kein Rebuild, kein Resubmit – nur Polling → Staple → ZIP[/DMG])"
  echo "3) Clean only"
  echo "q) Quit"
  read -rp "Auswahl: " CH
  case "$CH" in
    1) DO_FROM_SCRATCH=true ;;
    2) DO_RESUME=true ;;
    3) DO_CLEAN_ONLY=true ;;
    q|Q) exit 0 ;;
    *) abort "Ungültige Auswahl" ;;
  esac
  if [[ "$CH" = "1" || "$CH" = "2" ]]; then
    read -rp "DMG zusätzlich bauen und notarisieren? (y/N): " DMG
    [[ "${DMG:-}" =~ ^[Yy]$ ]] && DO_WITH_DMG=true
  fi
else
  for a in "$@"; do
    case "$a" in
      --from-scratch) DO_FROM_SCRATCH=true ;;
      --resume)       DO_RESUME=true ;;
      --with-dmg)     DO_WITH_DMG=true ;;
      --clean)        DO_CLEAN_ONLY=true ;;
      --skip-build)   DO_SKIP_BUILD=true ;;
      *) echo "Unbekannter Parameter: $a"; exit 2 ;;
    esac
  done
fi

# Preflight
command -v xcrun >/dev/null   || abort "xcode command line tools fehlen"
command -v codesign >/dev/null|| abort "codesign nicht gefunden"
command -v flutter  >/dev/null|| abort "flutter nicht gefunden"
$DO_WITH_DMG && command -v create-dmg >/dev/null || { $DO_WITH_DMG && abort "create-dmg fehlt (brew install create-dmg)"; }

# Notary-Creds sanity
if ! xcrun notarytool validate-credentials --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
  if ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
    abort "notarytool profile '${NOTARY_PROFILE}' ungültig. Mit: xcrun notarytool store-credentials '${NOTARY_PROFILE}' … neu anlegen."
  fi
fi

# Version aus pubspec.yaml
[[ -f pubspec.yaml ]] || abort "pubspec.yaml fehlt"
grep -q '^version:' pubspec.yaml || abort "pubspec.yaml hat keine 'version:' Zeile"
VER=$(awk '/^version:/{print $2}' pubspec.yaml)
BUILD_NAME=${VER%%+*}
BUILD_NUM=${VER##*+}
[[ "$BUILD_NAME" == "$BUILD_NUM" ]] && BUILD_NUM=0
ZIP_OUT="${ZIP_OUT/__VERSION__/${BUILD_NAME}}"
DMG_OUT="${DMG_OUT/__VERSION__/${BUILD_NAME}}"

# Helpers
detach_volume_if_mounted() {
  local vol="/Volumes/${VOL_NAME}"
  if mount | grep -q "$vol"; then
    warn "DMG-Volume aushängen: ${vol}"
    hdiutil detach "$vol" -quiet || true
  fi
}
save_job_state() {
  local state="$1"; local extra="${2:-}"
  /usr/bin/python3 - "$JOB_JSON" "$state" "$extra" <<'PY'
import json,sys,os,datetime
p,state,extra=sys.argv[1],sys.argv[2],sys.argv[3] if len(sys.argv)>3 else ""
j={}
if os.path.exists(p):
  try: j=json.load(open(p))
  except: j={}
j["state"]=state
j["updatedAt"]=datetime.datetime.utcnow().isoformat()+"Z"
if extra:
  for kv in extra.split(";"):
    kv=kv.strip()
    if not kv: continue
    k,v=kv.split("=",1)
    j[k]=v
os.makedirs(os.path.dirname(p), exist_ok=True)
open(p,"w").write(json.dumps(j,indent=2))
print(json.dumps(j,indent=2))
PY
}
read_state_field() {
  local key="$1"
  [[ -f "$JOB_JSON" ]] || { echo ""; return 0; }
  /usr/bin/python3 - "$JOB_JSON" "$key" <<'PY'
import json,sys
try:
  j=json.load(open(sys.argv[1]))
  print(j.get(sys.argv[2],""))
except: print("")
PY
}

# ========= Notary: robustes History-Parsing (JSON → PLIST → Text) =========
latest_history_row_for_name_since() {
  local NAME="$1"; local START="$2"

  _python_pick='
import sys,json,datetime,unicodedata,re
name=sys.argv[1].strip().lower()
start=sys.argv[2].strip()
def norm(s): return unicodedata.normalize("NFKC",(s or "")).strip()
def ts(s):
  try: return datetime.datetime.fromisoformat((s or "").replace("Z","+00:00"))
  except: return datetime.datetime.min
def pick(items, start_iso):
  items=[h for h in items if norm(h.get("name")).lower()==name]
  if not items: return None
  # Startfilter
  if start_iso:
    t0=ts(start_iso); items_since=[h for h in items if ts(h.get("createdDate"))>=t0]
  else:
    items_since=items[:]
  # Bevorzugung: Accepted > Invalid > andere (jeweils jüngster)
  for wanted in ("accepted","invalid"):
    cand=[h for h in items_since if (h.get("status") or "").lower()==wanted]
    if cand:
      cand.sort(key=lambda h:h.get("createdDate",""), reverse=True)
      return cand[0]
  # Fallback ohne Startfilter
  for wanted in ("accepted","invalid"):
    cand=[h for h in items if (h.get("status") or "").lower()==wanted]
    if cand:
      cand.sort(key=lambda h:h.get("createdDate",""), reverse=True)
      return cand[0]
  items.sort(key=lambda h:h.get("createdDate",""), reverse=True)
  return items[0]
raw=sys.stdin.read().strip()
if not raw:
  sys.exit(2)
data=json.loads(raw)
hist=data.get("history") or []
row=pick(hist, start)
if row:
  print((row.get("id","") or ""), (row.get("status","") or ""), (row.get("createdDate","") or ""))
else:
  sys.exit(1)
'
  # 1) JSON
  local RAW_JSON
  RAW_JSON="$(xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" --output-format json 2>/dev/null || true)"
  if [[ -n "${RAW_JSON}" && "${RAW_JSON}" == *"{"* ]]; then
    /usr/bin/python3 - "$NAME" "$START" <<<"${_python_pick}" | /usr/bin/python3 - "$NAME" "$START" 2>/dev/null <<<"${RAW_JSON}" && return 0 || true
  fi
  # 2) PLIST
  if command -v plutil >/dev/null 2>&1; then
    local RAW_PLIST RAW_PLIST_JSON
    RAW_PLIST="$(xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" --output-format plist 2>/dev/null || true)"
    if [[ -n "${RAW_PLIST}" ]]; then
      RAW_PLIST_JSON="$(plutil -convert json -o - - 2>/dev/null <<<"${RAW_PLIST}" || true)"
      if [[ -n "${RAW_PLIST_JSON}" && "${RAW_PLIST_JSON}" == *"{"* ]]; then
        /usr/bin/python3 - "$NAME" "$START" <<<"${_python_pick}" | /usr/bin/python3 - "$NAME" "$START" 2>/dev/null <<<"${RAW_PLIST_JSON}" && return 0 || true
      fi
    fi
  fi
  # 3) Text
  local RAW_TXT
  RAW_TXT="$(xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" 2>/dev/null || true)"
  if [[ -n "${RAW_TXT}" ]]; then
    /usr/bin/python3 - "$NAME" "$START" <<'PY' 2>/dev/null <<<"${RAW_TXT}"
import sys,datetime,re,unicodedata
name=sys.argv[1].strip().lower()
start=sys.argv[2].strip()
def norm(s): return unicodedata.normalize("NFKC",(s or "")).strip()
def ts(s):
  try: return datetime.datetime.fromisoformat((s or "").replace("Z","+00:00"))
  except: return datetime.datetime.min
text=sys.stdin.read()
blocks=re.split(r'-{5,}', text)
items=[]
for b in blocks:
  cd=re.search(r'createdDate:\s*([0-9T:\.\-Z\+]+)', b)
  i=re.search(r'\bid:\s*([0-9a-fA-F\-]{8,})', b)
  nm=re.search(r'\bname:\s*(.+)', b)
  st=re.search(r'\bstatus:\s*(\w+)', b)
  if nm and i and st and cd:
    items.append({"createdDate":norm(cd.group(1)),"id":norm(i.group(1)),
                  "name":norm(nm.group(1)).lower(),"status":norm(st.group(1))})
if not items: sys.exit(2)
def pick(items, start_iso):
  same=[x for x in items if x["name"]==name]
  if not same: return None
  def filt(arr, iso):
    if not iso: return arr[:]
    t0=ts(iso); return [x for x in arr if ts(x["createdDate"])>=t0]
  since=filt(same, start)
  for wanted in ("accepted","invalid"):
    cand=[x for x in since if x["status"].lower()==wanted]
    if cand:
      cand.sort(key=lambda x:x["createdDate"], reverse=True); return cand[0]
  for wanted in ("accepted","invalid"):
    cand=[x for x in same if x["status"].lower()==wanted]
    if cand:
      cand.sort(key=lambda x:x["createdDate"], reverse=True); return cand[0]
  same.sort(key=lambda x:x["createdDate"], reverse=True)
  return same[0]
row=pick(items, start)
if row:
  print(row["id"], row["status"], row["createdDate"])
else:
  sys.exit(1)
PY
    if [[ $? -eq 0 ]]; then return 0; fi
  fi
  return 1
}

# ========= Notary: ID-basierte Abfrage (bevorzugt) =========
notary_wait_by_id() {
  local SUB_ID="$1"
  local tries=0 sleep_s=30
  while :; do
    tries=$((tries+1))
    local RAW
    RAW="$(xcrun notarytool info "$SUB_ID" --keychain-profile "${NOTARY_PROFILE}" --output-format json 2>/dev/null || true)"
    if [[ -n "$RAW" && "$RAW" == *"{"* ]]; then
      local STATUS
      STATUS="$(/usr/bin/python3 - <<'PY' 2>/dev/null <<<"$RAW"
import sys,json
j=json.load(sys.stdin)
print((j.get("status") or ""))
PY
)"
      [[ -n "$STATUS" ]] && echo "  info($SUB_ID): $STATUS"
      if [[ "$STATUS" == "Accepted" ]]; then
        return 0
      elif [[ "$STATUS" == "Invalid" ]]; then
        xcrun notarytool log "$SUB_ID" --keychain-profile "${NOTARY_PROFILE}" | sed -n '1,200p' || true
        abort "Notarisierung invalid."
      fi
    fi
    echo "  … in progress (${tries}), sleep ${sleep_s}s"
    sleep "$sleep_s"
    (( sleep_s < 300 )) && sleep_s=$((sleep_s*2))
  done
}

lint_framework_roots_or_die() {
  local bad=0
  find "$STAGE_APP/Contents/Frameworks" \( -name ".DS_Store" -o -name "._*" \) -delete 2>/dev/null || true
  while IFS= read -r -d '' fw; do
    while IFS= read -r -d '' f; do
      echo "✖ Unzulässige Datei im Framework-Root: $f"
      bad=$((bad+1))
    done < <(find "$fw" -maxdepth 1 -type f -print0)
  done < <(find "$STAGE_APP/Contents/Frameworks" -type d -name "*.framework" -print0)
  (( bad == 0 )) || abort "Framework-Root enthält unsealed Dateien. Bitte fixen und erneut starten."
}
resign_all() {
  info "xattrs entfernen & vorbereiten"
  xattr -rc "$STAGE_APP" || true
  info "Resign Executables/Dylibs/Bundles/Plugins"
  find "$STAGE_APP" -type f \( -perm -111 -o -name "*.dylib" -o -name "*.so" -o -name "*.bundle" -o -name "*.plugin" \) -print0 \
    | xargs -0 -I{} codesign --force --options runtime --timestamp -s "$DEVID_NAME" "{}"
  info "Resign Framework-Bundles"
  find "$STAGE_APP/Contents/Frameworks" -type d -name "*.framework" -print0 \
    | xargs -0 -I{} codesign --force --options runtime --timestamp -s "$DEVID_NAME" "{}"
  info "Resign App (mit Entitlements)"
  codesign --force --options runtime --timestamp --entitlements "${ENTITLEMENTS}" -s "${DEVID_NAME}" "${STAGE_APP}"
}
verify_strict_or_die() {
  info "Verify (codesign --verify --deep --strict)"
  if ! codesign --verify --deep --strict --verbose=4 "${STAGE_APP}" >"$LOG_DIR/verify.log" 2>&1; then
    sed -n '1,200p' "$LOG_DIR/verify.log" || true
    abort "codesign verify fehlgeschlagen"
  fi
  spctl --assess --type execute -vv "${STAGE_APP}" || warn "spctl vor Notarisierung ggf. 'rejected' – ok"
}

# ========= Submit (ID speichern) =========
notary_submit_and_wait() {
  local FILE="$1"; local LABEL="$2"
  info "Submit: ${LABEL}"
  local RAW
  if ! RAW="$(xcrun notarytool submit "$FILE" --keychain-profile "${NOTARY_PROFILE}" --output-format json 2>/dev/null)"; then
    warn "Submit gab keinen JSON-Block zurück – Log folgt:"
    xcrun notarytool submit "$FILE" --keychain-profile "${NOTARY_PROFILE}" >"$LOG_DIR/submit_${LABEL}.log" 2>&1 || true
    sed -n '1,200p' "$LOG_DIR/submit_${LABEL}.log" || true
    abort "Submit fehlgeschlagen: ${LABEL}"
  fi
  local SUB_ID
  SUB_ID="$(/usr/bin/python3 - <<'PY' 2>/dev/null <<<"$RAW"
import sys,json
j=json.load(sys.stdin)
print((j.get("id") or ""))
PY
)"
  [[ -z "$SUB_ID" ]] && abort "Konnte submissionId nicht auslesen."
  save_job_state "NOTARY_SUBMITTED" "submissionId=${SUB_ID};artifactName=$(basename "$FILE")"
  info "Warte auf Ergebnis (info by id)"
  notary_wait_by_id "$SUB_ID"
  save_job_state "NOTARY_ACCEPTED"
}

# ========= CLEAN PHASE =========
if $DO_CLEAN_ONLY; then
  info "Cleanup Artefakte"
  rm -rf build "${OUT_DIR}" "$STAGE_ROOT" ".publisher"
  detach_volume_if_mounted
  exit 0
fi
if $DO_FROM_SCRATCH; then
  info "Full Clean: build/, dist/, DerivedData, DMG-Volumes"
  rm -rf build "${OUT_DIR}" "$STAGE_ROOT" ".publisher"
  mkdir -p "$LOG_DIR"
  rm -rf ~/Library/Developer/Xcode/DerivedData
  detach_volume_if_mounted
fi

# ========= BUILD =========
if $DO_RESUME; then DO_SKIP_BUILD=true; fi
if $DO_SKIP_BUILD; then
  warn "Build übersprungen (--skip-build/Resume)"
else
  info "Flutter build (name=${BUILD_NAME}, number=${BUILD_NUM})"
  flutter clean
  flutter pub get
  flutter build macos --release --build-name "${BUILD_NAME}" --build-number "${BUILD_NUM}"
fi
[[ -d "$BUILD_APP" || -d "$STAGE_APP" ]] || abort "App nicht gefunden: $BUILD_APP"

# ========= STAGING / STATE =========
STATE="$(read_state_field state)"
if $DO_FROM_SCRATCH || [[ -z "$STATE" ]]; then
  info "Staging vorbereiten (immutable Snapshot)"
  rm -rf "$STAGE_ROOT"; mkdir -p "$STAGE_ROOT"
  ditto "$BUILD_APP" "$STAGE_APP"
  save_job_state "SNAPSHOT_READY" "buildName=${BUILD_NAME};buildNumber=${BUILD_NUM}"
  STATE="SNAPSHOT_READY"
else
  info "Resume aktiv – aktuelle Phase: ${STATE}"
  [[ -d "$STAGE_APP" ]] || abort "Resume ohne Staging nicht möglich."
fi

# ========= STATE MACHINE (bash-3.2-kompatibel) =========
while :; do
  case "$STATE" in
    SNAPSHOT_READY|SIGNED|VERIFIED)
      info "Framework-Roots prüfen (vor dem Signieren)"
      lint_framework_roots_or_die
      resign_all
      save_job_state "SIGNED"
      info "Framework-Roots prüfen (nach dem Signieren)"
      lint_framework_roots_or_die
      verify_strict_or_die
      save_job_state "VERIFIED"
      STATE="VERIFIED"
      ;;

    VERIFIED)
      info "ZIP für Notarisierung erstellen (aus STAGING)"
      rm -f "$ZIP_NOTARY"
      ditto -c -k --keepParent "${STAGE_APP}" "${ZIP_NOTARY}"
      save_job_state "ZIP_FOR_NOTARY_DONE" "notaryZip=$(basename "$ZIP_NOTARY")"
      STATE="ZIP_FOR_NOTARY_DONE"
      ;;

    ZIP_FOR_NOTARY_DONE)
      if $DO_RESUME; then
        # Fast-Path: irgendein Accepted für diese Datei? (ohne Startfilter)
        if latest_history_row_for_name_since "$(basename "$ZIP_NOTARY")" ""; then
          ROW="$(latest_history_row_for_name_since "$(basename "$ZIP_NOTARY")" "" || true)"
          if [[ -n "$ROW" ]]; then
            set -- $ROW; STATUS="$2"
            if [[ "$STATUS" == "Accepted" ]]; then
              save_job_state "NOTARY_ACCEPTED"
              STATE="NOTARY_ACCEPTED"
              continue
            fi
          fi
        fi
        # Sonst: wenn wir eine submissionId kennen, nutze info by id
        SUB_ID="$(read_state_field submissionId)"
        if [[ -n "$SUB_ID" ]]; then
          notary_wait_by_id "$SUB_ID"
          save_job_state "NOTARY_ACCEPTED"
          STATE="NOTARY_ACCEPTED"
        else
          # Kein SUB_ID bekannt → vorsichtshalber NICHT erneut submitten (Resume-Policy)
          info "Keine submissionId vorhanden – History-Polling"
          if latest_history_row_for_name_since "$(basename "$ZIP_NOTARY")" ""; then
            ROW="$(latest_history_row_for_name_since "$(basename "$ZIP_NOTARY")" "" || true)"
            if [[ -n "$ROW" ]]; then
              set -- $ROW; STATUS="$2"
              [[ "$STATUS" == "Accepted" ]] && { save_job_state "NOTARY_ACCEPTED"; STATE="NOTARY_ACCEPTED"; continue; }
              [[ "$STATUS" == "Invalid"  ]] && abort "Notarisierung invalid (History)."
            fi
          fi
          warn "Kein Accepted sichtbar – nichts zu tun im Resume ohne ID."
          exit 0
        fi
      else
        notary_submit_and_wait "${ZIP_NOTARY}" "${APP_NAME}-notary.zip"
        STATE="NOTARY_ACCEPTED"
      fi
      ;;

    NOTARY_SUBMITTED)
      SUB_ID="$(read_state_field submissionId)"
      if [[ -n "$SUB_ID" ]]; then
        notary_wait_by_id "$SUB_ID"
        save_job_state "NOTARY_ACCEPTED"
        STATE="NOTARY_ACCEPTED"
      else
        # Fallback auf History (z. B. wenn alte Jobs.json)
        ROW="$(latest_history_row_for_name_since "$(basename "$ZIP_NOTARY")" "" || true)"
        if [[ -n "$ROW" ]]; then
          set -- $ROW; STATUS="$2"
          [[ "$STATUS" == "Accepted" ]] && { save_job_state "NOTARY_ACCEPTED"; STATE="NOTARY_ACCEPTED"; } || true
          [[ "$STATUS" == "Invalid"  ]] && abort "Notarisierung invalid (History)."
        fi
        [[ "$STATE" != "NOTARY_ACCEPTED" ]] && { warn "Kein Accepted sichtbar – Resume beendet."; exit 0; }
      fi
      ;;

    NOTARY_ACCEPTED)
      info "Stapeln der App (nach Accepted)"
      xcrun stapler staple "${STAGE_APP}"
      xcrun stapler validate "${STAGE_APP}" >"$LOG_DIR/stapler_validate_app.log" 2>&1 || abort "stapler validate fehlgeschlagen"
      save_job_state "STAPLED"
      STATE="STAPLED"
      ;;

    STAPLED)
      mkdir -p "${OUT_DIR}"
      info "Distributions-ZIP schreiben (gestapelte App)"
      rm -f "${ZIP_OUT}"
      ditto -c -k --keepParent "${STAGE_APP}" "${ZIP_OUT}"
      save_job_state "RELEASE_READY" "releaseZip=$(basename "$ZIP_OUT")"
      STATE="RELEASE_READY"
      ;;

    RELEASE_READY)
      if $DO_WITH_DMG; then
        info "DMG erstellen"
        detach_volume_if_mounted
        create-dmg \
          --volname "${VOL_NAME}" \
          --window-pos 200 120 \
          --window-size 600 400 \
          --icon-size 100 \
          --icon "${APP_NAME}.app" 150 200 \
          --hide-extension "${APP_NAME}.app" \
          --app-drop-link 450 200 \
          "${DMG_OUT}" \
          "${STAGE_ROOT}"

        if $DO_RESUME; then
          DMG_ID="$(read_state_field dmgSubmissionId)"
          if [[ -n "$DMG_ID" ]]; then
            notary_wait_by_id "$DMG_ID"
          else
            # Kein neuer Submit im Resume: nur Fast-Path via History
            ROW="$(latest_history_row_for_name_since "$(basename "$DMG_OUT")" "" || true)"
            if [[ -n "$ROW" ]]; then set -- $ROW; [[ "$2" == "Invalid" ]] && abort "DMG invalid."; fi
          fi
        else
          notary_submit_and_wait "${DMG_OUT}" "${APP_NAME}.dmg"
          # notary_submit_and_wait speichert keinen separaten DMG_ID-Key; könnte man ergänzen:
          # save_job_state "DMG_NOTARY_SUBMITTED" "dmgSubmissionId=$SUB_ID"
        fi

        info "DMG stapeln"
        xcrun stapler staple "${DMG_OUT}" >"$LOG_DIR/stapler_dmg.log" 2>&1 || abort "stapler (DMG) fehlgeschlagen"
        save_job_state "DMG_STAPLED" "releaseDmg=$(basename "$DMG_OUT")"
      fi
      break
      ;;

    *)
      break
      ;;
  esac
done

echo -e "${GREEN}✅ Fertig.${NC}"
echo "  STAGE : ${STAGE_APP}"
[[ -f "$ZIP_OUT" ]] && echo "  ZIP   : ${ZIP_OUT}"
[[ -f "$DMG_OUT" ]] && echo "  DMG   : ${DMG_OUT}"
echo "  Job   : ${JOB_JSON}"
