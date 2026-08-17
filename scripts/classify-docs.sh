#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
OUT_DIR="$ROOT_DIR/docs-classified"
TMP_DIR="$(mktemp -d)"
OCR_JOBS="${OCR_JOBS:-4}"
trap 'rm -rf "$TMP_DIR"' EXIT

render_page_images() {
  local src="$1"
  local out_dir="$2"
  local dpi="${3:-170}"

  mkdir -p "$out_dir"
  pdftoppm -r "$dpi" -png "$src" "$out_dir/page" >/dev/null 2>&1
}

render_text_pdf() {
  local src="$1"
  local out="$2"
  local title="$3"
  local category="$4"
  local printed="$5"
  local diag_scope="$6"
  local notes="$7"
  local pages
  local figures_dir

  mkdir -p "$(dirname "$out")"
  pages="$(pdfinfo "$src" | awk -F': *' '/^Pages:/ {print $2}')"
  figures_dir="${out%.md}/figures"

  {
    printf '# %s\n\n' "$title"
    printf -- '- Source PDF: `%s`\n' "${src#$ROOT_DIR/}"
    printf -- '- Category: `%s`\n' "$category"
    printf -- '- Printed: `%s`\n' "$printed"
    printf -- '- Pages: `%s`\n' "$pages"
    printf -- '- Conversion: `pdftotext` with page markers\n'
    printf -- '- Figures: `%s`\n' "${figures_dir#$ROOT_DIR/}"
    printf -- '- Diagnostic Scope: %s\n' "$diag_scope"
    printf -- '- Notes: %s\n\n' "$notes"
    printf '## Agent Notes\n\n'
    printf 'Use this Markdown for search, quoting, and service reasoning. Use the rendered page images when the original figure, waveform, or layout matters more than the OCR text.\n\n'
    printf '## Extracted Text\n\n'
  } > "$out"

  pdftotext "$src" - \
    | awk '
      BEGIN {
        page = 1
        print "## Page 1"
        print ""
      }
      {
        gsub(/\r/, "")
        while (index($0, "\f")) {
          sub(/\f/, "")
          if (length($0) > 0) {
            print $0
          }
          print ""
          page++
          print "## Page " page
          print ""
          next_line = 1
        }
        if (!next_line) {
          print $0
        }
        next_line = 0
      }
    ' >> "$out"

  render_page_images "$src" "$figures_dir" 170
}

render_ocr_pdf() {
  local src="$1"
  local out="$2"
  local title="$3"
  local category="$4"
  local printed="$5"
  local diag_scope="$6"
  local notes="$7"
  local pages
  local figures_dir
  local ocr_dir="$TMP_DIR/ocr-text"
  local image
  local page_id
  local page_num
  local text_file

  mkdir -p "$(dirname "$out")"
  pages="$(pdfinfo "$src" | awk -F': *' '/^Pages:/ {print $2}')"
  figures_dir="${out%.md}/figures"
  mkdir -p "$ocr_dir"

  {
    printf '# %s\n\n' "$title"
    printf -- '- Source PDF: `%s`\n' "${src#$ROOT_DIR/}"
    printf -- '- Category: `%s`\n' "$category"
    printf -- '- Printed: `%s`\n' "$printed"
    printf -- '- Pages: `%s`\n' "$pages"
    printf -- '- Conversion: `pdftoppm` + `tesseract` OCR with per-page markers\n'
    printf -- '- Figures: `%s`\n' "${figures_dir#$ROOT_DIR/}"
    printf -- '- Diagnostic Scope: %s\n' "$diag_scope"
    printf -- '- Notes: %s\n\n' "$notes"
    printf '## Agent Notes\n\n'
    printf 'This document is image-based. OCR spelling noise is expected, so verify thresholds, part numbers, locator references, and waveform values against the rendered page images when the text looks suspicious.\n\n'
    printf '## Extracted Text\n\n'
  } > "$out"

  render_page_images "$src" "$figures_dir" 150

  for image in "$figures_dir"/page-*.png; do
    (
      page_id="$(basename "$image" .png | sed 's/^page-//')"
      tesseract "$image" stdout --psm 6 2>/dev/null > "$ocr_dir/$page_id.txt"
    ) &
    if (( $(jobs -r | wc -l) >= OCR_JOBS )); then
      wait -n
    fi
  done
  wait

  for text_file in "$ocr_dir"/[0-9][0-9][0-9].txt; do
    page_id="$(basename "$text_file" .txt)"
    page_num=$((10#$page_id))
    printf '## Page %s\n\n' "$page_num" >> "$out"
    cat "$text_file" >> "$out"
    printf '\n\n' >> "$out"
  done
}

write_index() {
  mkdir -p "$OUT_DIR"
  cat > "$OUT_DIR/index.md" <<'EOF'
# HP 1615A Document Classification Index

This folder is organized so an agent can reason about HP 1615A measurement behavior, front-end loading, probe wiring, self-tests, adjustments, and repair flow without rereading raw PDFs each time.

## Document Registry

### HP 1615A Operating And Service Manual

- File: `docs-classified/logic-analyzer/01615-90904.md`
- Source PDF: `docs/01615-90904.pdf`
- Category: `logic-analyzer-operating-and-service-manual`
- Best for: instrument setup, timing/state capture behavior, self-tests, performance tests, adjustments, troubleshooting, schematic navigation, and board-level repair
- Fault domains:
  - analyzer does not trigger, arms incorrectly, or captures incoherent timing/state data
  - front-panel or display anomalies
  - self-test failures
  - input threshold, setup/hold, or timing qualification misunderstandings
  - power supply, timing, display, or acquisition board adjustment/service work
- High-value sections:
  - `Section III`: operating behavior and measurement setup
  - `Section IV`: performance tests and verification fixtures
  - `Section V`: adjustments
  - `Section VIII`: troubleshooting, self-test interpretation, signature analysis, schematics
- Figures: `docs-classified/logic-analyzer/01615-90904/figures/`

### HP 10248C Eight-Bit Data Probe Operating Note

- File: `docs-classified/probes/10248-90805.md`
- Source PDF: `docs/10248-90805.pdf`
- Category: `probe-operating-note`
- Best for: probe electrical loading, threshold range, grounding, glitch capture integrity, probe cable usage, and compatibility with the 1615A
- Fault domains:
  - suspect DUT loading or overvoltage at the probe tip
  - false glitches caused by grounding or cable arrangement
  - threshold mismatch between DUT logic family and analyzer setup
  - uncertainty about which probe/accessory is valid for a measurement
- High-value sections:
  - `Description` and specifications
  - `Input Signal Grounding`
  - `Principles Of Operation`
- Figures: `docs-classified/probes/10248-90805/figures/`

## Agent Usage Rules

- Use the `1615A` manual first when the question is about analyzer behavior, verification, or internal faults.
- Use the `10248C` note first when the question is really about the measurement connection itself: probe loading, thresholding, grounding, or glitch integrity.
- When OCR text is ambiguous, cite the page number from the Markdown and inspect the matching page image in the sibling `figures/` directory.
- For DUT diagnosis, separate instrument faults from measurement-condition faults:
  - instrument fault candidates usually live in `Sections IV`, `V`, and `VIII` of the `1615A` manual
  - measurement-condition faults usually live in the `10248C` probe note plus the `1615A` operating examples in `Section III`
EOF
}

mkdir -p \
  "$OUT_DIR/logic-analyzer" \
  "$OUT_DIR/probes"

render_ocr_pdf \
  "$DOCS_DIR/01615-90904.pdf" \
  "$OUT_DIR/logic-analyzer/01615-90904.md" \
  "HP 1615A Operating And Service Manual" \
  "logic-analyzer-operating-and-service-manual" \
  "October 1979" \
  "Primary source for instrument behavior, verification, adjustments, troubleshooting, and schematic-level service." \
  "Image-based PDF. OCR is good enough for search, but figures and schematics should be read from the rendered page images."

render_text_pdf \
  "$DOCS_DIR/10248-90805.pdf" \
  "$OUT_DIR/probes/10248-90805.md" \
  "HP 10248C Eight-Bit Data Probe Operating Note" \
  "probe-operating-note" \
  "Unknown" \
  "Primary source for probe loading, thresholding, grounding, glitch sensitivity, and DUT connection quality." \
  "Text extraction is reliable enough for search. Page images preserve the original figure and page layout."

write_index

printf 'Wrote classified docs to %s\n' "$OUT_DIR"
