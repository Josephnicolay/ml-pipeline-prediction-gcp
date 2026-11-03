#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var PROCESS_PROJECT_ID
require_var REGION
require_var JOB_NAME
require_var CLOUD_RUN_SERVICE_ACCOUNT
require_var SCHEDULER_LOCATION
require_var SCHEDULER_NAME
require_var SCHEDULER_SCHEDULE
require_var SCHEDULER_TIME_ZONE

RUN_URI="https://run.googleapis.com/v2/projects/$PROCESS_PROJECT_ID/locations/$REGION/jobs/$JOB_NAME:run"

log_step "Creating or updating Cloud Scheduler job"
if gcloud scheduler jobs describe "$SCHEDULER_NAME" \
  --project "$PROCESS_PROJECT_ID" \
  --location "$SCHEDULER_LOCATION" >/dev/null 2>&1; then
  gcloud scheduler jobs update http "$SCHEDULER_NAME" \
    --project "$PROCESS_PROJECT_ID" \
    --location "$SCHEDULER_LOCATION" \
    --schedule "$SCHEDULER_SCHEDULE" \
    --time-zone "$SCHEDULER_TIME_ZONE" \
    --uri "$RUN_URI" \
    --http-method POST \
    --oauth-service-account-email "$CLOUD_RUN_SERVICE_ACCOUNT" \
    --oauth-token-scope "https://www.googleapis.com/auth/cloud-platform"
  echo "[OK] Scheduler updated: $SCHEDULER_NAME"
else
  gcloud scheduler jobs create http "$SCHEDULER_NAME" \
    --project "$PROCESS_PROJECT_ID" \
    --location "$SCHEDULER_LOCATION" \
    --schedule "$SCHEDULER_SCHEDULE" \
    --time-zone "$SCHEDULER_TIME_ZONE" \
    --uri "$RUN_URI" \
    --http-method POST \
    --oauth-service-account-email "$CLOUD_RUN_SERVICE_ACCOUNT" \
    --oauth-token-scope "https://www.googleapis.com/auth/cloud-platform"
  echo "[OK] Scheduler created: $SCHEDULER_NAME"
fi
