#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var PROCESS_PROJECT_ID
require_var REGION
require_var CLOUD_RUN_REPO
require_var IMAGE_NAME
require_var IMAGE_TAG
require_var JOB_NAME
require_var CLOUD_RUN_SERVICE_ACCOUNT
require_var JOB_ENV_FILE

if [[ ! -f "$ROOT_DIR/$JOB_ENV_FILE" ]]; then
  echo "[ERROR] Missing job env vars file: $ROOT_DIR/$JOB_ENV_FILE"
  exit 1
fi

IMAGE_URI="$REGION-docker.pkg.dev/$PROCESS_PROJECT_ID/$CLOUD_RUN_REPO/$IMAGE_NAME:$IMAGE_TAG"

log_step "Deploying Cloud Run Job"
gcloud run jobs deploy "$JOB_NAME" \
  --project "$PROCESS_PROJECT_ID" \
  --image "$IMAGE_URI" \
  --region "$REGION" \
  --service-account "$CLOUD_RUN_SERVICE_ACCOUNT" \
  --env-vars-file "$ROOT_DIR/$JOB_ENV_FILE" \
  --quiet

echo "[OK] Job deployed: $JOB_NAME"
