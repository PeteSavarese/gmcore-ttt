#!/usr/bin/env bash

set -eo pipefail

COLOR_BLUE=$'\033[1;34m'
NO_COLOR=$'\033[0m'

print_tag() {
	local msg="$*"
	printf '[%sGDocker%s] %s\n' "$COLOR_BLUE" "$NO_COLOR" "$msg"
}

GMOD_ROOT="/home/container"
GMOD_DIR="${GMOD_ROOT}/garrysmod"
CFG_DIR="${GMOD_DIR}/cfg"
SERVER_CFG="${CFG_DIR}/server.cfg"
SERVER_CFG_TEMPLATE="${CFG_DIR}/server.cfg.template"
IMAGE_CFG_TEMPLATE="/opt/gmod-server/garrysmod/cfg/server.cfg.template"

generate_server_cfg() {
	print_tag "Starting server.cfg generation process"

	# Update from latest image since pterodactyl mounts differently
	if [ -f "${IMAGE_CFG_TEMPLATE}" ]; then
		print_tag "Copying server.cfg.template from image to runtime location"
		mkdir -p "${CFG_DIR}"
		cp -f "${IMAGE_CFG_TEMPLATE}" "${SERVER_CFG_TEMPLATE}"
	fi

	if [ ! -f "${SERVER_CFG_TEMPLATE}" ]; then
		print_tag "Warning: ${SERVER_CFG_TEMPLATE} not found, skipping server.cfg generation"

		return 1
	fi

	if ! mkdir -p "${CFG_DIR}"; then
		print_tag "Failed to create ${CFG_DIR}, skipping server.cfg generation"

		return 1
	fi

	# Environment and GMod data config
	local deploy_env="${DEPLOY_ENV:-local}"
	local server_name="${SERVER_NAME:-Giant\'s Lair TTT}"
	local hostname_prefix=""
	local prep_time=20
	local post_time=20

	case "${deploy_env,,}" in
		local|dev|development)
			hostname_prefix="[LOCAL] "
			prep_time=5
			post_time=5
			;;
		staging|stage)
			hostname_prefix="[STAGING] "
			prep_time=20
			post_time=20
			;;
		prod|production)
			hostname_prefix=""
			prep_time=20
			post_time=20
			;;
		*)
			print_tag "Unknown DEPLOY_ENV: ${deploy_env}, defaulting to production settings"
			hostname_prefix=""
			prep_time=20
			post_time=20
			;;
	esac

	local full_hostname="${hostname_prefix}${server_name}"
	local forums_base_url="${FORUMS_BASE_URL:-https://website.com}"
	local loading_url="${forums_base_url}/loading/index.html"

	print_tag "Generating ${SERVER_CFG} for environment: ${deploy_env}"
	print_tag "  Hostname: ${full_hostname}"
	print_tag "  Prep time: ${prep_time}s, Post time: ${post_time}s"
	print_tag "  Loading URL: ${loading_url}"
	print_tag "  Map rotation: ${MAP_ROTATION_FILE:-rotation_list.json}"

	local escaped_hostname=$(printf '%s\n' "${full_hostname}" | sed -e 's/[\/&]/\\&/g')
	local escaped_loading_url=$(printf '%s\n' "${loading_url}" | sed -e 's/[\/&]/\\&/g')
	local server_location="${SERVER_LOCATION:-us}"

	# Always generate server.cfg from template, overwriting any existing file
	# Use ^ as delimiter instead of | to avoid conflicts since we use | in our hostname
	if cat "${SERVER_CFG_TEMPLATE}" | \
		sed "s^{{HOSTNAME}}^${escaped_hostname}^g" | \
		sed "s^{{LOADING_URL}}^${escaped_loading_url}^g" | \
		sed "s^{{PREP_TIME}}^${prep_time}^g" | \
		sed "s^{{POST_TIME}}^${post_time}^g" | \
		sed "s^{{SERVER_LOCATION}}^${server_location}^g" \
		> "${SERVER_CFG}"; then

		if [ -s "${SERVER_CFG}" ]; then
			print_tag "server.cfg generated successfully ($(wc -l < "${SERVER_CFG}") lines)"
		else
			print_tag "Error: server.cfg was generated but is empty!"
			print_tag "Template file size: $(wc -l < "${SERVER_CFG_TEMPLATE}") lines"

			return 1
		fi
	else
		print_tag "Error: Failed to generate server.cfg from template"

		return 1
	fi
}

generate_server_cfg
