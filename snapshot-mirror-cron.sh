#!/bin/bash

set -x

SNAPSHOT_MOUNTPOINT=/snapshot

# Adapt window of "1 day" with respect to cron
NOW_TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOWER_TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ -d "1 day ago")"

exec {lock_fd}>/home/user/snapshot.lock || exit 1
flock -n "$lock_fd" || { echo "ERROR: flock() failed." >&2; exit 1; }

if mountpoint -q "$SNAPSHOT_MOUNTPOINT"; then
    /home/user/snapshot-mirror/snapshot-mirror.py "$SNAPSHOT_MOUNTPOINT" \
        --debug --no-clean-part-file \
        --archive debian --archive qubes-r4.1-vm \
        --suite unstable --suite bullseye --suite buster \
        --arch amd64 --arch all --arch source \
        --timestamp "${LOWER_TIMESTAMP}": \
        > "/var/log/snapshot/${NOW_TIMESTAMP}.log" 2>&1
    xz "/var/log/snapshot/${NOW_TIMESTAMP}.log"
fi

flock -u "$lock_fd"
