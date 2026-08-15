#!/bin/sh
set -eu

SFTP_USER="${SFTP_USER:-sftpuser}"
SFTP_PASSWORD_FILE="${SFTP_PASSWORD_FILE:-}"
SFTP_GROUP="sftp_users"

fail() {
    echo "sftp-server: $*" >&2
    exit 1
}

case "$SFTP_USER" in
    *[!a-zA-Z0-9_-]*|'') fail "SFTP_USER may contain only letters, numbers, '_' and '-'" ;;
esac

if [ -n "$SFTP_PASSWORD_FILE" ]; then
    [ -r "$SFTP_PASSWORD_FILE" ] || fail "cannot read SFTP_PASSWORD_FILE: $SFTP_PASSWORD_FILE"
    SFTP_PASSWORD="$(sed -n '1p' "$SFTP_PASSWORD_FILE")"
else
    SFTP_PASSWORD="${SFTP_PASSWORD:-}"
fi

[ -n "$SFTP_PASSWORD" ] || fail "set SFTP_PASSWORD or SFTP_PASSWORD_FILE"
case "$SFTP_PASSWORD" in
    *"
"*) fail "SFTP_PASSWORD must not contain a newline" ;;
esac

addgroup -S -g 1000 "$SFTP_GROUP"
# /upload is the path as seen from inside ChrootDirectory.
adduser -S -D -H -u 1000 -G "$SFTP_GROUP" -h /upload -s /sbin/nologin "$SFTP_USER"

printf '%s:%s\n' "$SFTP_USER" "$SFTP_PASSWORD" | chpasswd
unset SFTP_PASSWORD

chroot_dir="/home/$SFTP_USER"
upload_dir="$chroot_dir/upload"
mkdir -p "$upload_dir" /run/sshd /etc/ssh/keys

# OpenSSH requires every component of ChrootDirectory to be owned by root and
# not writable by the SFTP user. Only /upload is writable by the user.
chown root:root /home "$chroot_dir"
chmod 0755 /home "$chroot_dir"
chown "$SFTP_USER:$SFTP_GROUP" "$upload_dir"
chmod 0775 "$upload_dir"

if [ ! -s /etc/ssh/keys/ssh_host_ed25519_key ]; then
    ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/keys/ssh_host_ed25519_key
fi

chmod 0600 /etc/ssh/keys/ssh_host_ed25519_key
/usr/sbin/sshd -t

exec "$@"
