#!/bin/bash
# Watchdog will monitor Lua heartbeat file to detect server hangs. Refer to
# the module sv_healthcheck.lua

COLOR_RED=$'\033[1;31m'
COLOR_GREEN=$'\033[1;32m'
COLOR_YELLOW=$'\033[1;33m'
NO_COLOR=$'\033[0m'

print_health() {
	printf '[%sWatchdog%s] %s\n' "$COLOR_GREEN" "$NO_COLOR" "$*"
}

print_warning() {
	printf '[%sWatchdog%s] %s\n' "$COLOR_YELLOW" "$NO_COLOR" "$*"
}

print_error() {
	printf '[%sWatchdog%s] %s\n' "$COLOR_RED" "$NO_COLOR" "$*"
}

CHECK_INTERVAL=5
HEARTBEAT_TIMEOUT=10  # If heartbeat not updated for this many seconds, restart
HEARTBEAT_FILE="/home/container/garrysmod/data/gmcore/healthcheck_heartbeat.txt"
DEBUG_STATUS_FILE="/home/container/garrysmod/data/gmcore/debug_active.txt"

DEPLOY_ENV="${DEPLOY_ENV:-local}"
WATCHDOG_ENABLED="${WATCHDOG_ENABLED:-1}"

# Watchdog can only be disabled in local env. This env var does NOT exist in Pterodactyl egg configs either.
if [ "${DEPLOY_ENV}" = "local" ] && [ "${WATCHDOG_ENABLED}" = "0" ]; then
	print_health "Watchdog disabled via WATCHDOG_ENABLED=0 (local env only) - exiting."
	exit 0
fi

print_health "Watchdog started (checking every ${CHECK_INTERVAL}s)"
print_health "Monitoring heartbeat file: $HEARTBEAT_FILE"
print_health "Will restart if heartbeat not updated for ${HEARTBEAT_TIMEOUT}s"

# Wait until heartbeat file written AFTER $1 (unix epoch) to start watchdog
# Prevents server from being restarted during initial boot with an old heartbeat file.
wait_for_fresh_heartbeat() {
	local start_time_epoch=$1
	print_health "Waiting for server to boot (first heartbeat after unix timestamp ${start_time_epoch})..."

	while true; do
		sleep "$CHECK_INTERVAL"

		if [ -f "$DEBUG_STATUS_FILE" ]; then
			print_health "Debug mode active during boot - watchdog paused until heartbeat received"

			continue
		fi

		if [ -f "$HEARTBEAT_FILE" ]; then
			local file_modified_time_epoch
			# Use file file_modified_time_epoch as "last heartbeat" timestamp.
			file_modified_time_epoch=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)

			if [ "$file_modified_time_epoch" -ge "$start_time_epoch" ]; then
				print_health "Server heartbeat received - watchdog active"

				return 0
			fi
		fi

		# No fresh heartbeat yet; keep waiting
		print_health "Still waiting for first heartbeat..."
	done
}

WATCHDOG_START_TIME=$(date +%s)
wait_for_fresh_heartbeat "$WATCHDOG_START_TIME"

get_srcds_pid() {
	# Match incase we move back to 32-bit
	local pid=""
	pid=$(pgrep -x "srcds_linux" 2>/dev/null | head -1)
	if [ -n "$pid" ]; then
		echo "$pid"

		return
	fi

	pid=$(pgrep -x "srcds" 2>/dev/null | head -1)
	if [ -n "$pid" ]; then
		echo "$pid"

		return
	fi

	pid=$(pgrep -f "srcds_run_x64" 2>/dev/null | head -1)
	if [ -n "$pid" ]; then
		echo "$pid"

		return
	fi

	echo ""
}

get_heartbeat_age() {
	if [ ! -f "$HEARTBEAT_FILE" ]; then
		echo "999999"

		return
	fi

	local current_time=$(date +%s)
	local file_mtime=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
	local age=$((current_time - file_mtime))
	echo "$age"
}

kill_and_restart() {
	local pid=$1
	print_error "Server hang detected - heartbeat stopped!"
	print_error "Killing srcds (PID: $pid) - Container will autorestart..."

	kill -9 "$pid" 2>/dev/null || true
	pkill -9 "srcds" 2>/dev/null || true

	sleep 2

	wait_for_fresh_heartbeat "$(date +%s)"
}

DEBUG_MODE_NOTIFIED=""

print_health "Watchdog active"

while true; do
	sleep "$CHECK_INTERVAL"

	if [ -f "$DEBUG_STATUS_FILE" ]; then
		if [ "$DEBUG_MODE_NOTIFIED" != "true" ]; then
			print_health "Debug mode active - watchdog paused"
			DEBUG_MODE_NOTIFIED="true"
		fi

		continue
	else
		if [ "$DEBUG_MODE_NOTIFIED" = "true" ]; then
			print_health "Debug mode deactivated - watchdog resumed"
			DEBUG_MODE_NOTIFIED=""
		fi
	fi

	SRCDS_PID=$(get_srcds_pid)

	if [ -z "$SRCDS_PID" ]; then
		print_warning "No srcds process found, skipping check... (pgrep output: $(pgrep -a srcds 2>&1 || echo 'none'))"

		continue
	fi

	HEARTBEAT_AGE=$(get_heartbeat_age)

	if [ "$HEARTBEAT_AGE" -gt "$HEARTBEAT_TIMEOUT" ]; then
		print_error "Heartbeat timeout! Last update: ${HEARTBEAT_AGE}s ago"
		kill_and_restart "$SRCDS_PID"
	elif [ "$HEARTBEAT_AGE" -gt 15 ]; then
		print_warning "Heartbeat aging: ${HEARTBEAT_AGE}s since last update"
	fi
done
