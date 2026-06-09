gmcore = gmcore or {}
gmcore.Fonts = gmcore.Fonts or {}
gmcore.Fonts.defs = gmcore.Fonts.defs or {}

local function normalizeFontOptions(opts)
	local font = opts.font or "DermaDefault"
	local size = tonumber(opts.size) or 16
	local weight = tonumber(opts.weight) or (opts.bold and 700 or 500)

	return {
		font = font,
		size = size,
		weight = weight,
		blursize = tonumber(opts.blursize) or 0,
		antialias = opts.antialias ~= false,
		shadow = opts.shadow == true,
		outline = opts.outline == true,
		additive = opts.additive == true,
		underline = opts.underline == true,
		italic = opts.italic == true,
		extended = opts.extended == true,
		scanlines = tonumber(opts.scanlines) or 0,
	}
end

local function buildFontKey(opts)
	local keyParts = {
		"font=" .. tostring(opts.font),
		"size=" .. tostring(opts.size),
		"weight=" .. tostring(opts.weight),
		"blursize=" .. tostring(opts.blursize),
		"antialias=" .. tostring(opts.antialias),
		"shadow=" .. tostring(opts.shadow),
		"outline=" .. tostring(opts.outline),
		"additive=" .. tostring(opts.additive),
		"underline=" .. tostring(opts.underline),
		"italic=" .. tostring(opts.italic),
		"extended=" .. tostring(opts.extended),
		"scanlines=" .. tostring(opts.scanlines),
	}

	return table.concat(keyParts, "|")
end

---Get a font name for the given options. Creates font if needed.
---@param opts table
---@return string
function gmcore.Fonts:Get(opts)
	if type(opts) ~= "table" then
		return "DermaDefault"
	end

	local normalized = normalizeFontOptions(opts)
	local key = buildFontKey(normalized)
	local name = "gmcore.Fonts." .. util.CRC(key)

	if not gmcore.Fonts.defs[name] then
		gmcore.Fonts.defs[name] = normalized
		surface.CreateFont(name, normalized)
		gmcore.DebugPrint("Registered font: " .. name)
	end

	return name
end

---Register a font definition and create immediately.
---@param name string
---@param data table
function gmcore.Fonts:Register(name, data)
	if not name or not data then return end

	gmcore.Fonts.defs[name] = table.Copy(data)
	surface.CreateFont(name, data)

	gmcore.DebugPrint("Registered font: " .. name)
end

---Ensure a font exists without re-registering.
---@param name string
---@param data table
function gmcore.Fonts:Ensure(name, data)
	if gmcore.Fonts.defs[name] then return end

	gmcore.Fonts:Register(name, data)
end

---Recreate all registered fonts
function gmcore.Fonts:Rebuild()
	for name, data in pairs(gmcore.Fonts.defs) do
		surface.CreateFont(name, data)
	end
end

hook.Add("OnScreenSizeChanged", "gmcore.Fonts.Rebuild", function()
	gmcore.Fonts:Rebuild()
end)
