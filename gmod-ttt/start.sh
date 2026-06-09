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

write_gmcore_config_json() {
	local data_dir="${GMOD_DIR}/data"
	local gmcore_dir="${data_dir}/gmcore"
	local gmcore_config="${gmcore_dir}/gmcore_config.json"

	if ! mkdir -p "${gmcore_dir}"; then
		print_tag "Failed to create ${gmcore_dir}, skipping config initialization"
		return 1
	fi

	local server_id="${SERVER_ID:-1}"
	local server_name="${SERVER_NAME:-Giant\'s Lair TTT}"
	local server_tag="${SERVER_TAG:-gmod-ttt}"
	local deploy_env="${DEPLOY_ENV:-local}"
	local db_host="${MARIADB_HOST:-mariadb}"
	local db_port="${MARIADB_PORT:-3306}"
	local db_user="${MARIADB_USER:-user}"
	local db_pass="${MARIADB_PASS:-password}"
	local db_core="${MARIADB_DB_CORE:-gmcore_core}"
	local db_forums="${MARIADB_DB_FORUMS:-gmcore_forums}"
	local forums_base_url="${FORUMS_BASE_URL:-}"
	local map_rotation_file="${MAP_ROTATION_FILE:-rotation_list.json}"

	print_tag "Initializing ${gmcore_config} from environment variables"
	cat > "${gmcore_config}" <<EOF
{
	"server": {
		"id": ${server_id},
		"name": "${server_name}",
		"tag": "${server_tag}",
		"deploy_env": "${deploy_env}"
	},
	"databases": {
		"core": {
			"ip": "${db_host}",
			"username": "${db_user}",
			"password": "${db_pass}",
			"database": "${db_core}",
			"port": ${db_port}
		},
		"forums": {
			"ip": "${db_host}",
			"username": "${db_user}",
			"password": "${db_pass}",
			"database": "${db_forums}",
			"port": ${db_port}
		}
	},
	"forums_base_url": "${forums_base_url}",
	"map_rotation_file": "${map_rotation_file}"
}
EOF
}

AUTO_UPDATE="${AUTO_UPDATE:-0}"
if [ "${AUTO_UPDATE}" = "1" ]; then
	print_tag "Running SteamCMD update..."
	if [ -f /opt/steamcmd/steamcmd.sh ]; then
		/opt/steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 4020 -beta x86-64 validate +quit
	fi
fi

write_gmcore_config_json

GENERATE_CFG_SCRIPT="${GENERATE_CFG_SCRIPT:-/generate-server-cfg.sh}"
if [ -f "$GENERATE_CFG_SCRIPT" ]; then
	if ! "$GENERATE_CFG_SCRIPT"; then
		print_tag "server.cfg generation failed (exit code: $?), continuing anyway..."
	fi
fi

CHECK_MAPS_SCRIPT="${CHECK_MAPS_SCRIPT:-/check-maps.sh}"
if [ -f "$CHECK_MAPS_SCRIPT" ]; then
	if ! "$CHECK_MAPS_SCRIPT"; then
		print_tag "Map check failed (exit code: $?), continuing anyway..."
	fi
fi

# Start watchdog now that maps are downloaded
print_tag "Starting watchdog..."
/healthcheck.sh &

SERVER_PORT="${SERVER_PORT:-${PORT:-27015}}"
GAMEMODE="${GAMEMODE:-terrortown}"
MAP="${MAP:-gm_construct}"
MAXPLAYERS="${MAX_PLAYERS:-${MAXPLAYERS:-16}}"

ARGS=()

if [ -n "${GSLT}" ]; then
	ARGS+=("+sv_setsteamaccount" "${GSLT}")
fi

if [ -n "${AUTHKEY}" ]; then
	ARGS+=("-authkey" "${AUTHKEY}")
fi

deploy_env="${DEPLOY_ENV:-local}"
case "${deploy_env,,}" in
	prod|production)
		MODE="production"
		ARGS+=("-disableluarefresh")
		;;
	*)
		MODE="development"
		;;
esac

ADDON_COUNT=$(find ${GMOD_DIR}/addons -maxdepth 1 -type d | wc -l)
print_tag "Found ${ADDON_COUNT} addon directories"

print_tag "Killing any existing srcds processes..."
pkill -9 srcds || true
sleep 2

print_tag "Starting TTT Garry's Mod in ${MODE} mode..."
print_tag "Launch args: -port ${SERVER_PORT} -maxplayers ${MAXPLAYERS} +gamemode ${GAMEMODE} +map ${MAP}"

cd ${GMOD_ROOT}
export LD_LIBRARY_PATH="${GMOD_ROOT}:${GMOD_ROOT}/bin:${GMOD_DIR}/bin:${LD_LIBRARY_PATH}"
exec ./srcds_run_x64 \
	-game garrysmod \
	-console \
	-usercon \
	-strictportbind \
	-port "${SERVER_PORT}" \
	-maxplayers "${MAXPLAYERS}" \
	+gamemode "${GAMEMODE}" \
	+map "${MAP}" \
	-ip 0.0.0.0 \
	"${ARGS[@]}"
