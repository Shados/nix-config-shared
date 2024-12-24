#!/usr/bin/env bash
set -eEo pipefail
shopt -s inherit_errexit nullglob

# Command to start the locker (should not fork)
locker="$1"

function cleanup {
	trap - TERM INT
	final_status=$?
	unset-dpms
	kill "$1" 2>/dev/null
	return $final_status
}

# Kill locker & reset dpms config if we get killed
trap 'cleanup "$LOCKER_PID"' TERM INT

# Set DPMS timeout
set-dpms

# Run the locker in the background
$locker &
LOCKER_PID="$!"

# Get logind session D-Bus path
session_path="$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager ListSessions -j | jq -r ".data[][] | select(.[0] == \"$XDG_SESSION_ID\") | .[4]")"
# Tell logind we're locked
busctl call org.freedesktop.login1 "$session_path" org.freedesktop.login1.Session SetLockedHint b true

# If we've been passed a XSS_SLEEP_LOCK_FD, we need to ensure we clean
# it up; once both us and the locker have closed it, systemd will know
# it is OK to proceed to sleep
if [[ -e /dev/fd/''${XSS_SLEEP_LOCK_FD:--1} ]]; then
	exec {XSS_SLEEP_LOCK_FD}<&-
fi

# Wait for the locker to exit
wait

# Tell logind we're unlocked
busctl call org.freedesktop.login1 "$session_path" org.freedesktop.login1.Session SetLockedHint b false &

# Now that we're unlocked again, trigger a logind Unlock event; we can
# hook this in dbus (or in systemd via systemd-lock-handler)
loginctl unlock-session &

# Unset DPMS timeout
unset-dpms
