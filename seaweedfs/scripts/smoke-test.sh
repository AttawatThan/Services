#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

container_id="$(docker compose ps -q seaweedfs)"

if [[ -z "$container_id" ]]; then
  echo "SeaweedFS is not running. Start it with: docker compose up -d" >&2
  exit 1
fi

health_state=""
for _ in {1..30}; do
  health_state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' "$container_id")"
  if [[ "$health_state" == "healthy" ]]; then
    break
  fi
  if [[ "$health_state" == "unhealthy" ]]; then
    echo "SeaweedFS health check failed. Inspect it with: docker compose logs seaweedfs" >&2
    exit 1
  fi
  sleep 2
done

if [[ "$health_state" != "healthy" ]]; then
  echo "SeaweedFS did not become healthy within 60 seconds." >&2
  exit 1
fi

container_env="$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container_id")"
access_key="$(printf '%s\n' "$container_env" | sed -n 's/^AWS_ACCESS_KEY_ID=//p')"
secret_key="$(printf '%s\n' "$container_env" | sed -n 's/^AWS_SECRET_ACCESS_KEY=//p')"
bucket="$(printf '%s\n' "$container_env" | sed -n 's/^S3_BUCKET=//p')"

if [[ -z "$access_key" || -z "$secret_key" || -z "$bucket" ]]; then
  echo "The running container is missing AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or S3_BUCKET." >&2
  exit 1
fi

network_name="$(docker inspect --format '{{range $name, $_ := .NetworkSettings.Networks}}{{println $name}}{{end}}' "$container_id" | sed -n '1p')"
if [[ -z "$network_name" ]]; then
  echo "Could not determine the SeaweedFS Docker network." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -f -- "$tmp_dir/hello.txt" "$tmp_dir/downloaded.txt"
  rmdir -- "$tmp_dir"
}
trap cleanup EXIT

object_name="smoke-test-$(date +%s)-$$.txt"
printf 'hello seaweedfs\n' > "$tmp_dir/hello.txt"

aws_cli() {
  docker run --rm \
    --network "$network_name" \
    -e AWS_ACCESS_KEY_ID="$access_key" \
    -e AWS_SECRET_ACCESS_KEY="$secret_key" \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -v "$tmp_dir:/work" \
    amazon/aws-cli:2.36.14 \
    --endpoint-url http://seaweedfs:8333 \
    "$@"
}

echo "Checking pre-created bucket: s3://$bucket"
aws_cli s3api head-bucket --bucket "$bucket"

echo "Uploading $object_name"
aws_cli s3 cp /work/hello.txt "s3://$bucket/$object_name" --no-progress

echo "Listing uploaded object"
aws_cli s3 ls "s3://$bucket/$object_name"

echo "Downloading and comparing content"
aws_cli s3 cp "s3://$bucket/$object_name" /work/downloaded.txt --no-progress
cmp "$tmp_dir/hello.txt" "$tmp_dir/downloaded.txt"

echo "Removing smoke-test object"
aws_cli s3 rm "s3://$bucket/$object_name"

echo "PASS: bucket creation, authenticated upload, list, download, and content verification all succeeded."
