#!/bin/bash
set -e
sleep 1

COLOR_BLUE=$'\033[1;34m'
NO_COLOR=$'\033[0m'

print_tag() {
	local msg="$*"
	printf '[%sGDocker%s] %s\n' "$COLOR_BLUE" "$NO_COLOR" "$msg"
}

TZ=${TZ:-UTC}
export TZ

# Set environment vars for internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

# Ensure Steam client libraries exist in GMod mount
mkdir -p /home/container/.steam/sdk32 /home/container/.steam/sdk64
if [ -f /opt/steamcmd/linux32/steamclient.so ]; then
	cp -f /opt/steamcmd/linux32/steamclient.so /home/container/.steam/sdk32/steamclient.so
fi
if [ -f /opt/steamcmd/linux64/steamclient.so ]; then
	cp -f /opt/steamcmd/linux64/steamclient.so /home/container/.steam/sdk64/steamclient.so
fi

if [ -d /opt/gmod-server ]; then
	if [ ! -f /home/container/srcds_run_x64 ]; then
		# First-time seed... this always runs, regardless of GMCORE_DISABLE_IMAGE_SEEDING.
		# Without it there is no server.
		if [ ! -w /home/container ]; then
			print_tag "Error: /home/container is not writable."
			print_tag "If running locally with bind mounts, run the container once as root to seed files, then restart as user 'container'."

			exit 1
		fi

		print_tag "Seeding server files from image (first boot of container build)..."
		if cp -a /opt/gmod-server/. /home/container/; then
			print_tag "Seed complete."
		else
			print_tag "Warning: seed failed due to permissions. If running locally with bind mounts, run the container as root once to seed."
		fi
	elif [ "${GMCORE_DISABLE_IMAGE_SEEDING:-0}" = "1" ]; then
		print_tag "Skipping image rsync (GMCORE_DISABLE_IMAGE_SEEDING=1)."
	elif [ "${DEPLOY_ENV:-}" = "local" ]; then
		print_tag "Skipping image rsync for local environment."
	else
		# Subsequent starts... rsync with --delete so removed files don't linger
		print_tag "Syncing content from image..."

		# Dirs where --delete is safe: image owns all content
		for dir in addons cfg lua models; do
			src="/opt/gmod-server/garrysmod/${dir}/"
			dst="/home/container/garrysmod/${dir}/"

			if [ -d "$src" ]; then
				print_tag "  - Syncing ${dir}..."
				rsync -a --delete "$src" "$dst"
			fi
		done

		# Sync image files in without deleting anything the server has written
		for dir in data; do
			src="/opt/gmod-server/garrysmod/${dir}/"
			dst="/home/container/garrysmod/${dir}/"

			if [ -d "$src" ]; then
				print_tag "  - Syncing ${dir}"
				rsync -a "$src" "$dst"
			fi
		done

		print_tag "Sync complete."
	fi
fi

# Convert all of Pterodactyl "{{VARIABLE}}" env vars into shell variable format of "${VARIABLE}"
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the Ptero output mimic, and execute it with env
# from the container itself.
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"

if [ "$(id -u)" = "0" ]; then
	chown -R container:container /home/container || true
	# shellcheck disable=SC2086
	exec su -s /bin/bash container -c "env ${PARSED}"
fi

# shellcheck disable=SC2086
exec env ${PARSED}
