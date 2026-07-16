#!/usr/bin/env bash
set -euo pipefail

BUCKET="tentris-renovate"
ENDPOINT="https://fsn1.your-objectstorage.com"
NAMESPACE="${1:?NAMESPACE is not set}"
KEEP_KEY="${2:?KEEP_KEY is not set}"
CACHE_PREFIX="cache/${NAMESPACE}/"

export AWS_ACCESS_KEY_ID="${MINIO_USER:?MINIO_USER is not set}"
export AWS_SECRET_ACCESS_KEY="${MINIO_PASSWORD:?MINIO_PASSWORD is not set}"
export AWS_REGION="eu-central-1"

echo "Scanning s3://${BUCKET}/${CACHE_PREFIX} (keeping: ${KEEP_KEY})"
prefixes="$(aws --endpoint-url "$ENDPOINT" s3api list-objects-v2 \
  --bucket "$BUCKET" --prefix "$CACHE_PREFIX" --delimiter "/" \
  --query 'CommonPrefixes[].Prefix' --output text | tr '\t' '\n')"

if [[ -z "$prefixes" || "$prefixes" == "None" ]]; then
  echo "No cache prefixes found."
  exit 0
fi

while read -r full_prefix; do
  [[ -z "$full_prefix" ]] && continue

  name="${full_prefix#"$CACHE_PREFIX"}"
  name="${name%/}"

  if [[ "$name" == "$KEEP_KEY" ]]; then
    echo "  keep:    ${full_prefix}"
    continue
  fi

  echo "  delete:  ${full_prefix}"
  aws --endpoint-url "$ENDPOINT" s3 rm "s3://${BUCKET}/${full_prefix}" --recursive
done <<< "$prefixes"
