#!/usr/bin/env bash
# One-time: create AWS infrastructure (requires admin / broad IAM).
# Fill HOSTED_ZONE_ID from Route 53 → Hosted zones → synvertchem.com → Hosted zone ID.
# Usage:
#   export AWS_PROFILE=your-admin-profile
#   export HOSTED_ZONE_ID=Z0123456789ABCDEFGHIJ
#   ./scripts/create-stack.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
STACK="${STACK_NAME:-synvert-landing-page-site}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"

if [[ -z "$HOSTED_ZONE_ID" ]]; then
  echo "Set HOSTED_ZONE_ID to your Route 53 hosted zone ID for synvertchem.com" >&2
  exit 1
fi

echo "Deploying stack ${STACK} in ${REGION} (ACM + CloudFront can take 20–40+ minutes) ..."
aws cloudformation deploy \
  --template-file "${ROOT}/infra/cloudformation-static-site.yaml" \
  --stack-name "$STACK" \
  --parameter-overrides "HostedZoneId=${HOSTED_ZONE_ID}" \
  --region "$REGION"

echo "Stack complete. Get outputs:"
aws cloudformation describe-stacks \
  --stack-name "$STACK" \
  --region "$REGION" \
  --query "Stacks[0].Outputs" \
  --output table

echo "Then set S3_BUCKET and CLOUDFRONT_DISTRIBUTION_ID and run ./scripts/deploy.sh"
