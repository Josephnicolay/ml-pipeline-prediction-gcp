#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var SOURCE_PROJECT_ID
require_var SOURCE_DATASET_ID
require_var SOURCE_TABLE_ID

log_step "Loading initial data into BigQuery"
PROJECT_ID="$SOURCE_PROJECT_ID" \
DATASET_ID="$SOURCE_DATASET_ID" \
TABLE_ID="$SOURCE_TABLE_ID" \
uv run python "$ROOT_DIR/src/pre-setup.py"

echo "[OK] Initial data loaded"
