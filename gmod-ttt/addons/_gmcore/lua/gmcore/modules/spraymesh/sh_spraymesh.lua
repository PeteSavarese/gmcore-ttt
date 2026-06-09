--
-- * SPRAYMESH EXTENDED CONFIGURATION FILE
-- * If you are a server owner, feel free to edit the settings in here to your liking.
--
-- Ideally, this should be the only Lua file you have to modify--if you want to add or remove other features,
-- leave a suggestion and I might make it something configurable. :)
--
-- You can leave suggestions on either:
-- - The Steam Workshop page, or
-- - The GitHub repository: https://github.com/chev2/gmod-addons/issues
--

spraymesh = spraymesh or {}

-- Default spray, often used when player's current spray is invalid or they otherwise haven't set a spray yet
---@type string Default spray URL (without protocol prefix)
spraymesh.SPRAY_URL_DEFAULT = "https://i.imgur.com/xkJx3md.png"

-- Units between points (default: 1.75). The dimensions (size) of all player sprays
-- Bigger values means spray sizes will increase
---@type number Units between mesh points
spraymesh.COORD_DIST_DEFAULT = 1.75

-- Mesh resolution (default: 30); this controls how many points make up the mesh grid, such as 30x30,
-- which affects how smooth or jagged the mesh cuts off or wraps around the map diagonally
-- * Tip: try to keep res as 10x the coord dist, and remember that the maximum res is 105 before this breaks
---@type number Grid resolution for spray mesh
spraymesh.MESH_RESOLUTION = 30

-- The image resolution used for sprays
-- e.g. 512 means the image is resized to be 512x512 pixels
-- Default: 512
-- * The resolution MUST be a power of 2 (256, 512, 1024, etc.), otherwise sprays will be sized weirdly
---@type number Image resolution in pixels (must be power of 2)
spraymesh.IMAGE_RESOLUTION = 512

-- How often players can spray (in seconds).
---@type number Cooldown between sprays in seconds
spraymesh.SPRAY_COOLDOWN = 3

-- Command prefixes for the spraymesh command, e.g. "!", "/" will allow both !spraymesh and /spraymesh.
-- * If you want to disable chat commands, just remove all the entries in this list.
---@type string[]
spraymesh.CHAT_COMMAND_PREFIXES = {
		"!",
		"/",
		"."
}

-- A list of valid IMAGE domains that sprays can use.
---@type table<string, boolean>
spraymesh.VALID_URL_DOMAINS_IMAGE = {
		["i.imgur.com"] = true,
		["files.catbox.moe"] = true,
		["litter.catbox.moe"] = true,
		["cdn.discordapp.com"] = true,
}

-- A list of valid VIDEO domains that sprays can use.
---@type table<string, boolean>
spraymesh.VALID_URL_DOMAINS_VIDEO = {
		["i.imgur.com"] = true,
}

-- A list of valid IMAGE extensions that sprays can use.
-- * NOTE: SprayMesh (the original addon) disabled GIF sprays due to heavy performance impact.
-- * I'm not sure if modern Garry's Mod still has the same issue, but if it does (at least, in your tests),
-- * simply remove gif from this list to disable GIFs.
---@type table<string, boolean>
spraymesh.VALID_URL_EXTENSIONS_IMAGE = {
		["jpeg"] = true,
		["jpg"] = true,
		["png"] = true,
		["webp"] = true,
		["gif"] = true,
		["avif"] = true,
}

-- A list of valid VIDEO extensions that sprays can use.
---@type table<string, boolean>
spraymesh.VALID_URL_EXTENSIONS_VIDEO = {
		["webm"] = true,
		["gifv"] = true,
		["mp4"] = true,
}

-- Set to true to enable boring debugging stuff like filling the console with various print statements.
---@type boolean
spraymesh.DEBUG_MODE = false

--[[
	HELPER FUNCTIONS
]]

-- To ensure that the URLs in the config don't start with HTTP or HTTPS
-- ConVars (such as spraymesh_url) don't allow "//" in the string, so we need to remove it
spraymesh.SPRAY_URL_DEFAULT = string.Replace(spraymesh.SPRAY_URL_DEFAULT, "http://", "https://")
spraymesh.SPRAY_URL_DEFAULT = string.Replace(spraymesh.SPRAY_URL_DEFAULT, "https://", "")

--spraymesh.SPRAY_URL_DISABLED = string.Replace(spraymesh.SPRAY_URL_DISABLED, "http://", "https://")
--spraymesh.SPRAY_URL_DISABLED = string.Replace(spraymesh.SPRAY_URL_DISABLED, "https://", "")

--spraymesh.SPRAY_URL_ANTIGIF = string.Replace(spraymesh.SPRAY_URL_ANTIGIF, "http://", "https://")
--spraymesh.SPRAY_URL_ANTIGIF = string.Replace(spraymesh.SPRAY_URL_ANTIGIF, "https://", "")

-- Stores SteamID64 keys that contain url and delay/immediate vars serverside, and a meshdata var clientside
---@type table<string, table> Keyed by SteamID64
spraymesh.SPRAYDATA = spraymesh.SPRAYDATA or {}

-- Enums for spray types.
-- SPRAYTYPE_INVALID: The spray is not a valid spray.
-- SPRAYTYPE_IMAGE: The spray is an image.
-- SPRAYTYPE_VIDEO: The spray is a video.
SPRAYTYPE_INVALID = 0
SPRAYTYPE_IMAGE = 1
SPRAYTYPE_VIDEO = 2

-- Checks if the spray URL is valid (image OR video)
---@param url string URL to validate as an image or video spray
---@return boolean isValid True if the URL is a valid image or video spray URL
function spraymesh.IsValidAnyURL(url)
		return spraymesh.IsValidImageURL(url) or spraymesh.IsValidVideoURL(url)
end

-- Checks if the spray URL is valid (images ONLY)
---@param url string URL to validate as an image spray
---@return boolean isValid True if the URL is a valid whitelisted image spray URL
function spraymesh.IsValidImageURL(url)
		-- Needs to be HTTPS
		if not url:StartWith("https://") then return false end

		-- Needs to be from a whitelisted domain
		if not url:EndsWith("/") then url = url .. "/" end
		urlDomain = string.match(url, "https://(.-)/")
		if not spraymesh.VALID_URL_DOMAINS_IMAGE[urlDomain] then return false end

		-- Must have a valid file extension
		local extension = string.match(url, "%.(%w+)/$")
		if not extension or not spraymesh.VALID_URL_EXTENSIONS_IMAGE[extension] then return false end

		-- Must be 512 characters or fewer
		if #url > 512 then return false end

		return true
end

-- Checks if the spray URL is valid (videos ONLY)
---@param url string URL to validate as a video spray
---@return boolean isValid True if the URL is a valid whitelisted video spray URL
function spraymesh.IsValidVideoURL(url)
		-- Needs to be HTTPS
		if not url:StartWith("https://") then return false end

		-- Needs to be from a whitelisted domain
		if not url:EndsWith("/") then url = url .. "/" end
		urlDomain = string.match(url, "https://(.-)/")
		if not spraymesh.VALID_URL_DOMAINS_VIDEO[urlDomain] then return false end

		-- Must have a valid file extension
		local extension = string.match(url, "%.(%w+)/$")
		if not extension or not spraymesh.VALID_URL_EXTENSIONS_VIDEO[extension] then return false end

		-- Must be 512 characters or fewer
		if #url > 512 then return false end

		return true
end

-- Checks if the URL has an IMAGE extension
---@param url string URL to check for a valid image file extension
---@return boolean isImage True if the URL ends with a valid image file extension
function spraymesh.IsImageExtension(url)
		local extension = string.match(url, "%.(%w+)$")

		return spraymesh.VALID_URL_EXTENSIONS_IMAGE[extension] == true
end

-- Checks if the URL has a VIDEO extension
---@param url string URL to check for a valid video file extension
---@return boolean isVideo True if the URL ends with a valid video file extension
function spraymesh.IsVideoExtension(url)
		local extension = string.match(url, "%.(%w+)$")

		return spraymesh.VALID_URL_EXTENSIONS_VIDEO[extension] == true
end

-- Checks if the URL is valid, and returns the type (image or video)
---@param url string URL to determine the spray type for
---@return number sprayType SPRAYTYPE_INVALID, SPRAYTYPE_IMAGE, or SPRAYTYPE_VIDEO
function spraymesh.GetURLInfo(url)
		-- Ensure URL is set to HTTPS
		url = string.Replace(url, "http://", "https://")
		url = string.Replace(url, "https://", "")
		url = "https://" .. url

		if not spraymesh.IsValidAnyURL(url) then
				spraymesh.DebugPrint("URL does not pass IsValidAnyURL check!")

				return SPRAYTYPE_INVALID
		end

		local sprayType = SPRAYTYPE_INVALID
		if spraymesh.IsImageExtension(url) then
				sprayType = SPRAYTYPE_IMAGE
		elseif spraymesh.IsVideoExtension(url) then
				sprayType = SPRAYTYPE_VIDEO
		end

		return sprayType
end

---Prints debug info to console when DEBUG_MODE is enabled.
---@param msg string Debug message to print to console
function spraymesh.DebugPrint(msg)
		if spraymesh.DEBUG_MODE then print("[SprayMesh Extended Debug]: " .. msg) end
end
