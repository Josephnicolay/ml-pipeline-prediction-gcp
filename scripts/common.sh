#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.deploy}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] Missing deploy env file: $ENV_FILE"
  echo "Copy .env.deploy.example to .env.deploy and fill values."
  exit 1
fi

set -a
# shellcheck disable=SC1090
set +e
# shellcheck disable=SC1090
source "$ENV_FILE"
source_status=$?
set -e

if [[ $source_status -ne 0 ]]; then
  echo "[ERROR] Failed to load $ENV_FILE"
  echo "Check syntax in variable assignments."
  echo "Tip: wrap values with spaces in double quotes, e.g. SCHEDULER_SCHEDULE=\"0 8 * * *\""
  exit $source_status
fi
set +a

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "[ERROR] Required variable is empty: $name"
    exit 1
  fi
}

log_step() {
  echo
  echo "==> $1"
}
