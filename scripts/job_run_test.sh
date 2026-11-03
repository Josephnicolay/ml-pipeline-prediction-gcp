#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var PROCESS_PROJECT_ID
require_var REGION
require_var JOB_NAME

log_step "Executing Cloud Run Job test run"
gcloud run jobs execute "$JOB_NAME" \
  --project "$PROCESS_PROJECT_ID" \
  --region "$REGION"

echo "[OK] Job execution requested"
