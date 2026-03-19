#!/usr/bin/env bash
# Convert DOCX files to TEI-XML using a local TEIGarage instance.
# Starts the TEIGarage Docker container automatically and stops it when done.

set -euo pipefail

# --- Config
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
readonly REPO_DIR="$(dirname -- "$SCRIPT_DIR")"
readonly INPUT_DIR="$REPO_DIR/input"
readonly OUTPUT_DIR="$SCRIPT_DIR/teigarage-out"
readonly API_URL="http://localhost:8080/ege-webservice/Conversions/docx:application:vnd.openxmlformats-officedocument.wordprocessingml.document/TEI:text:xml"
readonly CONTAINER_NAME="teigarage"
readonly SERVICE_URL="http://localhost:8080/ege-webservice/Conversions/"

# --- Preflight
for cmd in docker curl xmllint; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd"; exit 1; }
done

mkdir -p -- "$OUTPUT_DIR"

started_by_script=false
cleanup() {
  if [[ "$started_by_script" == true ]]; then
    echo "Stopping TEIGarage container..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# --- Ensure TEIGarage is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "TEIGarage container already running."
else
  echo "Starting TEIGarage container..."
  docker run --rm -d -p 8080:8080 \
    -e WEBSERVICE_URL=http://localhost:8080/ege-webservice/ \
    --name "$CONTAINER_NAME" ghcr.io/teic/teigarage >/dev/null
  started_by_script=true
fi

# --- Wait for readiness
echo -n "Waiting for TEIGarage to start "
ready=false
for i in {1..30}; do
  if curl -s --max-time 2 -o /dev/null "$SERVICE_URL"; then
    ready=true
    echo " ready."
    break
  fi
  echo -n "."
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo " timed out."
  exit 1
fi

# --- Gather inputs
shopt -s nullglob
docx_files=("$INPUT_DIR"/*.docx)
shopt -u nullglob

if [[ ${#docx_files[@]} -eq 0 ]]; then
  echo "No .docx files found in $INPUT_DIR"
  exit 0
fi

# --- Convert
echo "Converting ${#docx_files[@]} file(s)..."

failed=0
for f in "${docx_files[@]}"; do
  filename=$(basename -- "$f" .docx)
  outfile="$OUTPUT_DIR/${filename}.xml"
  printf "  %s ... " "$filename"

  http_code=$(curl -sS --connect-timeout 5 --max-time 120 \
    -o "$outfile" -w "%{http_code}" \
    -F "upload=@$f" \
    "$API_URL" || printf "000")

  if [[ "$http_code" != "200" ]]; then
    echo "FAILED (HTTP $http_code)"
    rm -f -- "$outfile"
    ((failed+=1))
    continue
  fi

  # Validate and pretty-print via a temp file to avoid clobbering on error
  tmpfile="$outfile.tmp"
  if ! XMLLINT_INDENT="    " xmllint --format "$outfile" -o "$tmpfile" 2>/dev/null; then
    echo "FAILED (invalid XML)"
    rm -f -- "$tmpfile" "$outfile"
    ((failed+=1))
    continue
  fi
  mv -f -- "$tmpfile" "$outfile"
  echo "OK"
done

echo "Done. ${#docx_files[@]} processed, $failed failed."
