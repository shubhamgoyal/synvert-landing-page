#!/usr/bin/env bash
# Deploy static files to S3 and invalidate CloudFront.
# After the stack exists, set bucket and distribution (from stack Outputs), e.g.:
#   export S3_BUCKET=synvertchem.com
#   export CLOUDFRONT_DISTRIBUTION_ID=E1234567890ABC
#   ./scripts/deploy.sh
# Or one-shot: S3_BUCKET=... CLOUDFRONT_DISTRIBUTION_ID=... ./scripts/deploy.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROFILE="${AWS_PROFILE:-synvert-landing-page}"
REGION="${AWS_REGION:-us-east-1}"

BUCKET="${S3_BUCKET:-}"
DIST="${CLOUDFRONT_DISTRIBUTION_ID:-}"

if [[ -z "$BUCKET" || -z "$DIST" ]]; then
  echo "Set S3_BUCKET and CLOUDFRONT_DISTRIBUTION_ID (from CloudFormation stack Outputs after deploy)." >&2
  echo "Example: export S3_BUCKET=synvertchem.com CLOUDFRONT_DISTRIBUTION_ID=E123..." >&2
  exit 1
fi

echo "Syncing to s3://${BUCKET}/ ..."
aws s3 sync "$ROOT" "s3://${BUCKET}/" \
  --delete \
  --profile "$PROFILE" \
  --exclude ".git/*" \
  --exclude "infra/*" \
  --exclude "scripts/*" \
  --exclude ".gitignore" \
  --exclude ".DS_Store"

echo "Invalidating CloudFront ${DIST} ..."
aws cloudfront create-invalidation \
  --distribution-id "$DIST" \
  --paths "/*" \
  --profile "$PROFILE" \
  --region "$REGION" \
  --output text

echo "Done."
