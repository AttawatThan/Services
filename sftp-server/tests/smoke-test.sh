#!/bin/sh
set -eu

project_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test_password='smoke-test-password'
test_port="${SFTP_TEST_PORT:-22222}"
test_file="$project_dir/data/smoke-test.txt"
local_file="$(mktemp)"

cleanup() {
    SFTP_PASSWORD="$test_password" SFTP_PORT="$test_port" \
        docker compose --project-directory "$project_dir" down -v >/dev/null 2>&1 || true
    rm -f "$test_file" "$local_file"
}
trap cleanup EXIT INT TERM

command -v expect >/dev/null 2>&1 || {
    echo "The smoke test requires 'expect'" >&2
    exit 1
}

printf 'SFTP smoke test\n' > "$local_file"

SFTP_PASSWORD="$test_password" SFTP_PORT="$test_port" \
    docker compose --project-directory "$project_dir" up --build -d --wait

container_id="$(SFTP_PASSWORD="$test_password" SFTP_PORT="$test_port" \
    docker compose --project-directory "$project_dir" ps -q sftp)"
[ -n "$container_id" ]

expect <<EOF
set timeout 20
spawn sftp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P $test_port sftpuser@127.0.0.1
expect "password:"
send "$test_password\r"
expect "sftp>"
send "put $local_file smoke-test.txt\r"
expect "sftp>"
send "quit\r"
expect eof
EOF

[ "$(cat "$test_file")" = "SFTP smoke test" ]
docker exec "$container_id" /usr/sbin/sshd -t

echo "Smoke test passed"
