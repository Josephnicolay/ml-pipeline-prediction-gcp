#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

require_var PROCESS_PROJECT_ID
require_var REGION
require_var CLOUD_RUN_REPO
require_var IMAGE_NAME
require_var IMAGE_TAG

IMAGE_URI="$REGION-docker.pkg.dev/$PROCESS_PROJECT_ID/$CLOUD_RUN_REPO/$IMAGE_NAME:$IMAGE_TAG"

log_step "Building Cloud Run image"
gcloud builds submit --tag "$IMAGE_URI" "$ROOT_DIR/src/job/"

echo "[OK] Image built: $IMAGE_URI"
