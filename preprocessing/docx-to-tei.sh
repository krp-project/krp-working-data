#!/bin/bash
#
# Convert DOCX files to TEI-XML using a local TEIGarage instance.
# Expects TEIGarage to be running at http://localhost:8080 (via Docker).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

INPUT_DIR="$REPO_DIR/tmp"
OUTPUT_DIR="$SCRIPT_DIR/teigarage-out/editions"
API_URL="http://localhost:8080/ege-webservice/Conversions/docx:application:vnd.openxmlformats-officedocument.wordprocessingml.document/TEI:text:xml"

mkdir -p "$OUTPUT_DIR"

# Check that TEIGarage is reachable
if ! curl -s --max-time 5 -o /dev/null "http://localhost:8080/ege-webservice/Conversions/"; then
    echo "Error: TEIGarage is not reachable at localhost:8080."
    echo "Start it with: docker run --rm -p 8080:8080 -e WEBSERVICE_URL=http://localhost:8080/ege-webservice/ --name teigarage ghcr.io/teic/teigarage"
    exit 1
fi

shopt -s nullglob
docx_files=("$INPUT_DIR"/*.docx)
shopt -u nullglob

if [[ ${#docx_files[@]} -eq 0 ]]; then
    echo "No .docx files found in $INPUT_DIR"
    exit 0
fi

echo "Converting ${#docx_files[@]} file(s)..."

failed=0
for f in "${docx_files[@]}"; do
    filename=$(basename "$f" .docx)
    outfile="$OUTPUT_DIR/${filename}.xml"
    echo -n "  $filename ... "

    http_code=$(curl -s -o "$outfile" -w "%{http_code}" \
        -F upload=@"$f" \
        "$API_URL")

    if [[ "$http_code" != "200" ]]; then
        echo "FAILED (HTTP $http_code)"
        rm -f "$outfile"
        ((failed++)) || true
        continue
    fi

    if ! xmllint --noout "$outfile" 2>/dev/null; then
        echo "FAILED (invalid XML)"
        ((failed++)) || true
        continue
    fi

    # Pretty-print in place
    xmllint --format "$outfile" -o "$outfile"
    echo "OK"
done

echo "Done. ${#docx_files[@]} processed, $failed failed."
