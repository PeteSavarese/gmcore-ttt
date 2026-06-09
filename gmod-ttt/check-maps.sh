#!/bin/bash
set -eo pipefail

GMOD_ROOT="${GMOD_ROOT:-/home/container}"
GMOD_DIR="${GMOD_DIR:-${GMOD_ROOT}/garrysmod}"
DATA_DIR="${GMOD_DIR}/data/gmcore"
MAPS_DIR="${GMOD_DIR}/maps"
ROTATION_FILE="${DATA_DIR}/mapvote/${MAP_ROTATION_FILE:-rotation_list.json}"
CONTENT_FILE="${GMOD_DIR}/addons/_gmcore/lua/gm/modules/content/sv_content.lua"
STEAMCMD="${STEAMCMD:-/opt/steamcmd/steamcmd.sh}"
WORKSHOP_TEMP="/tmp/workshop_temp"
GMAD_BIN="${GMOD_ROOT}/bin/linux64/gmad"

COLOR_BLUE=$'\033[1;34m'
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[1;33m'
NO_COLOR=$'\033[0m'

print_tag() {
	local msg="$*"

	printf '[%sGDocker%s] %s\n' "$COLOR_BLUE" "$NO_COLOR" "$msg"
}

if [ ! -f "$ROTATION_FILE" ]; then
	print_tag "${COLOR_YELLOW}Warning: Map rotation file not found in ${ROTATION_FILE}, skipping map check${NO_COLOR}"
	exit 0
fi

if [ ! -f "$CONTENT_FILE" ]; then
	print_tag "${COLOR_YELLOW}Warning: Content file not found in ${CONTENT_FILE}, skipping map check${NO_COLOR}"
	exit 0
fi

if [ ! -f "$STEAMCMD" ]; then
	print_tag "${COLOR_YELLOW}Warning: SteamCMD not found in ${STEAMCMD}, skipping map check${NO_COLOR}"
	exit 0
fi

if ! command -v jq &> /dev/null; then
	print_tag "${COLOR_YELLOW}Warning: jq not found, skipping map check${NO_COLOR}"
	exit 0
fi

# Create maps dir
mkdir -p "$MAPS_DIR"

print_tag "Checking for missing maps..."

# Extract map names from rotation JSON
mapnames=$(jq -r '.[].map' "$ROTATION_FILE" 2>/dev/null | sort -u || echo "")

if [ -z "$mapnames" ]; then
	print_tag "${COLOR_YELLOW}No maps found in rotation${NO_COLOR}"
	exit 0
fi

# Parse sv_content.lua to extract workshop IDs
temp_lua_table=$(mktemp)
sed -n '/mapsToWorkshopID = {/,/^}/p' "$CONTENT_FILE" > "$temp_lua_table"

# Extract workshop ID from content.lua for a map name
get_workshop_id() {
	local mapname="$1"
	# Remove suffixes like _ahg_v1, _gl, _opt for lookup
	local clean_name=$(echo "$mapname" | sed -E 's/_(ahg|gl|opt)(_v[0-9]+)?$//')

	# Try exact match first (take only first match and first line)
	workshop_id=$(grep -oP '^\s*\["'"$mapname"'"\]\s*=\s*"\K[0-9]+' "$temp_lua_table" | head -n 1 | tr -d '\n\r\t ' || true)

	# Try clean name if no exact match
	if [ -z "$workshop_id" ]; then
		workshop_id=$(grep -oP '^\s*\["'"$clean_name"'"\]\s*=\s*"\K[0-9]+' "$temp_lua_table" | head -n 1 | tr -d '\n\r\t ' || true)
	fi

	echo "$workshop_id"
}

download_workshop_item() {
	local workshop_id="$1"
	local max_retries=3
	local retry_count=0

	print_tag "Downloading workshop item ${workshop_id}..."

	# Create temp dir to mimic Steam structure since we bug out sometimes without it
	mkdir -p "${WORKSHOP_TEMP}/steamapps/workshop/content/4000"

	while [ $retry_count -lt $max_retries ]; do
		retry_count=$((retry_count + 1))

		if [ $retry_count -gt 1 ]; then
			print_tag "Retry attempt ${retry_count}/${max_retries} for workshop item ${workshop_id}..."
			sleep 2
		fi

		"$STEAMCMD" +force_install_dir "${WORKSHOP_TEMP}" \
			+login anonymous \
			+workshop_download_item 4000 "$workshop_id" validate \
			+quit > /dev/null 2>&1

		# Check if addon was downloaded if dir exists
		if [ -d "${WORKSHOP_TEMP}/steamapps/workshop/content/4000/${workshop_id}" ]; then
			return 0
		fi
	done

	# Welp, something went wrong. OVH keeps thinking gmad is a DDoS attack smh
	print_tag "${COLOR_RED}Failed to download workshop item ${workshop_id} after ${max_retries} attempts${NO_COLOR}"

	return 1
}

extract_map() {
	local workshop_id="$1"
	local workshop_path="${WORKSHOP_TEMP}/steamapps/workshop/content/4000/${workshop_id}"

	print_tag "Extracting maps from workshop item ${workshop_id}..."

	if [ ! -d "$workshop_path" ]; then
		print_tag "${COLOR_RED}Workshop item directory not found: ${workshop_path}${NO_COLOR}"

		return 1
	fi

	# Look for .gma files in the workshop directory
	local gma_file=$(find "$workshop_path" -name "*.gma" -type f 2>/dev/null | head -n 1)

	# Some legacy workshop items are legacy.bin instead of .gma
	if [ -z "$gma_file" ]; then
		local legacy_file=$(find "$workshop_path" -name "*legacy.bin" -type f 2>/dev/null | head -n 1)

		if [ -n "$legacy_file" ]; then
			print_tag "${COLOR_YELLOW}Legacy.bin detected for ${workshop_id}. Extracting with 7zip...${NO_COLOR}"

			# Extract legacy.bin with 7zip to temp directory (ignore exit code, 7z returns error but still extracts)
			local legacy_temp=$(mktemp -d)
			7z x "$legacy_file" -o"$legacy_temp" > /dev/null 2>&1 || true

			# First check if extraction produced a .gma file directly
			gma_file=$(find "$legacy_temp" -name "*.gma" -type f 2>/dev/null | head -n 1)

			if [ -z "$gma_file" ]; then
				# If no .gma, look for extracted file (usually has no extension)
				local extracted_file=$(find "$legacy_temp" -type f ! -name "*.bin" 2>/dev/null | head -n 1)

				if [ -n "$extracted_file" ]; then
					gma_file="${legacy_temp}/addon.gma"
					mv "$extracted_file" "$gma_file"
					print_tag "Converted legacy.bin to .gma format"
				else
					print_tag "${COLOR_RED}Failed to find extracted file from legacy.bin${NO_COLOR}"
					rm -rf "$legacy_temp"

					return 1
				fi
			else
				print_tag "Found .gma file in legacy.bin extraction"
			fi
		else
			print_tag "${COLOR_YELLOW}No .gma or legacy.bin file found for workshop item ${workshop_id}${NO_COLOR}"

			return 1
		fi
	fi

	if [ ! -f "$GMAD_BIN" ]; then
		print_tag "${COLOR_RED}gmad not found at ${GMAD_BIN}${NO_COLOR}"

		return 1
	fi

	# Extract to temp directory
	local temp_extract=$(mktemp -d)

	print_tag "Extracting $(basename "$gma_file") with gmad..."
	local extract_output
	extract_output=$("$GMAD_BIN" extract -file "$gma_file" -out "$temp_extract" 2>&1)
	local extract_result=$?

	if [ $extract_result -ne 0 ]; then
		print_tag "${COLOR_RED}Failed to extract with gmad (exit code: $extract_result)${NO_COLOR}"
		print_tag "${COLOR_RED}gmad output: $extract_output${NO_COLOR}"
		rm -rf "$temp_extract"

		return 1
	fi

	# Look for .bsp files in extracted content
	local found_maps=$(find "$temp_extract" -name "*.bsp" -type f 2>/dev/null || true)

	if [ -z "$found_maps" ]; then
		print_tag "${COLOR_YELLOW}No .bsp files found in extracted content${NO_COLOR}"
		print_tag "${COLOR_YELLOW}Contents of temp dir: $(ls -la "$temp_extract")${NO_COLOR}"
		rm -rf "$temp_extract"

		return 1
	fi

	print_tag "Found .bsp files, copying to $MAPS_DIR..."

	while IFS= read -r bsp_file; do
		local filename=$(basename "$bsp_file")
		print_tag "Copying $filename from $bsp_file to $MAPS_DIR/"
		if cp "$bsp_file" "$MAPS_DIR/"; then
			print_tag "${COLOR_GREEN}Downloaded: $filename${NO_COLOR}"
		else
			print_tag "${COLOR_RED}Failed to copy $filename${NO_COLOR}"
		fi
	done <<< "$found_maps"

	rm -rf "$temp_extract"
	rm -rf "$workshop_path"

	return 0
}

# Check for missing maps and download
missing_count=0
downloaded_count=0

print_tag "Checking for missing maps..."

for mapname in $mapnames; do
	print_tag "Checking map: ${mapname}"

	if [ -f "$MAPS_DIR/${mapname}.bsp" ]; then
		print_tag "${COLOR_GREEN}Map ${mapname} already present${NO_COLOR}"

		continue
	fi

	missing_count=$((missing_count + 1))
	workshop_id=$(get_workshop_id "$mapname")

	if [ -z "$workshop_id" ]; then
		print_tag "${COLOR_YELLOW}Missing map ${mapname} (no workshop ID found)${NO_COLOR}"

		continue
	fi

	print_tag "${COLOR_YELLOW}Missing map: ${mapname} (workshop: ${workshop_id})${NO_COLOR}"

	# Download and extract
	if download_workshop_item "$workshop_id"; then
		extract_map "$workshop_id" && downloaded_count=$((downloaded_count + 1))
	else
		print_tag "${COLOR_RED}Failed to download ${mapname}${NO_COLOR}"
	fi
done

# Cleanup
rm -f "$temp_lua_table"

if [ $missing_count -eq 0 ]; then
	print_tag "${COLOR_GREEN}All maps present${NO_COLOR}"
else
	print_tag "Missing: ${missing_count}, Downloaded: ${downloaded_count}"
fi
