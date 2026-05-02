#!/bin/sh
set -eu

DOCS_DIR="docs"
QMD_FILE="these_brieuc.qmd"
PDF_FILE="these_brieuc.pdf"
PDF_IN_DOCS="${DOCS_DIR}/${PDF_FILE}"

mkdir -p "${DOCS_DIR}"
cp "${QMD_FILE}" "${DOCS_DIR}/"

# If the PDF was rendered directly into docs/, keep it there.
# Otherwise copy the latest PDF found at the project root.
if [ ! -f "${PDF_IN_DOCS}" ] && [ -f "${PDF_FILE}" ]; then
  cp "${PDF_FILE}" "${DOCS_DIR}/"
fi

