#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var EMAIL
require_var GCS_BUCKET

log_step "Compiling pipeline and uploading JSON to GCS"
EMAIL="$EMAIL" \
GCS_BUCKET="$GCS_BUCKET" \
python "$ROOT_DIR/src/pipeline/pipeline.py"

echo "[OK] Pipeline spec uploaded"
