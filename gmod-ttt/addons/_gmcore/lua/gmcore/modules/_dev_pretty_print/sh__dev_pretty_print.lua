---Dev pretty print. Overrides print() and PrintTable() with colorized output showing file paths.
---@type string[]
local allowedDevPrintRanks = {
	"owner",
	"assistantdirector",
	"developer",
	"leadadmin"
}

local fileColors = {}
local fileAbbrev = {}
local incr = SERVER and 72 or 0 -- server side version of file gets different color from client... way less confusing like that
local oldPrint = print
local oldPTable = PrintTable
local conVarCheck

if CLIENT then
	conVarCheck = CreateClientConVar("gmcore_devprint", "0", true, false, "Show file path of where print is being executed from")
else
	conVarCheck = CreateConVar("gmcore_devprint", "0", _, "Show file path of where print is being executed from")
end

function print(...)
	local info = debug.getinfo(2)

	if !info or conVarCheck:GetBool() == false then
		oldPrint(...)

		return
	end

	if CLIENT and !table.HasValue(allowedDevPrintRanks, LocalPlayer():GetUserGroup()) then
		oldPrint(...)

		return
	end

	local fname = info.short_src

	if fileAbbrev[fname] then
		fname = fileAbbrev[fname]
	else
		local oldfname = fname
		fname = string.Explode('/', fname)
		fname = fname[#fname]
		fileAbbrev[oldfname] = fname
	end

	if !fileColors[fname] then
		incr = incr + 1
		fileColors[fname] = HSVToColor(incr * 100 % 255, 1, 1)
	end

	MsgC(fileColors[fname], debug.getinfo(2).short_src .. ":" .. debug.getinfo(2).lastlinedefined)
	oldPrint("  ", ...)
end

---Begin beautified PrintTable output. I found this in old GitLab project with no credits. I didn't make this and think it came from now deleted workshop addon but who did but credit to them
---@param val any The value to convert to markup
---@param spacing number The current indentation level
---@param colors table<string, Color>
---@param parsed table<table, boolean>
---@return table[] markup Array of markup entries with value, indent, and color fields
local function _toMarkup(val, spacing, colors, parsed)
		if type(val) == "string" then
			return {{v = string.format("%q", val), i = spacing, c = colors.string or colors["default"]}}
		elseif type(val) == "boolean" then
			return {{v = val and "true" or "false", i = spacing, c = colors.boolean or colors["default"]}}
		elseif type(val) == "number" then
			return {{v = tostring(val), i = spacing, c = colors.number or colors["default"]}}
		elseif type(val) == "function" then
			local info = debug.getinfo(val, "S")
			if !info or info.what == "C" then
					return {{v = "function:([C])", i = spacing, c = colors.c_function or colors["function"] or colors["default"]}}
			else
					return {{v = ("function:(%s : %s-%s)"):format(info.short_src, info.linedefined, info.lastlinedefined), i = spacing, c = colors["function"] or colors["default"]}} --"..table.concat(debug.getparams(val), ",").."
			end
		elseif type(val) == "table" then
			if parsed[val] then
				return {{v = "<" .. tostring(val) .. ">", i = spacing, c = colors.table or colors["default"]}}
			else
				parsed[val] = true

				local s = {{v = "{", n = true, i = spacing, c = colors.table or colors["default"]}}

				for key,val2 in pairs(val) do
					table.insert(s, {v = "[", i = spacing + 1, c = colors.table or colors["default"]})

					local k_s = _toMarkup(key, spacing + 1, colors, parsed)

					k_s.i = spacing + 1

					for k_i = 1, #k_s do
						table.insert(s, k_s[k_i])

					end
					table.insert(s, {v = "]", i = spacing + 1, c = colors.table or colors["default"]})
					table.insert(s, {v = " = ", i = spacing, c = colors.table or colors["default"]})

					local v_s = _toMarkup(val2, spacing + 1, colors, parsed)

					v_s.i = spacing + 1
					for v_i = 1, #v_s do
							table.insert(s, v_s[v_i])
					end

					table.insert(s, {v = ",", n = true, c = colors.table or colors["default"]})
				end

				table.insert(s, {v = "}", i = spacing, c = colors.table or colors["default"]})
			return s
		end
	elseif type(val) == "nil" then
		return {{v = "nil", c = colors["nil"] or colors["default"]}}
	end

	return {{v = "<" .. type(val) .. ">: " .. tostring(val) .. ">", c = colors["default"]}}
end

---@param val any The value to convert to markup
---@param colors table<string, Color>
---@return table[] markup Array of markup entries representing the value
function toMarkup(val, colors)
	return _toMarkup(val, 0, colors, {})
end

---@param markup table[] The array of markup entries to convert
---@param colors_override? table<string, Color>
---@return string html The markup converted to an HTML-formatted string
function MarkupToHTML(markup, colors_override)
	local colors = colors_override or table.markup_colors
	local s, cc, ic, first = "", colors.default, 0, true
	local jn = true

	for oi = 1, #markup do
		local object = markup[oi]
		local c = object.c
		local changes = ""

		if c and c.r ~= cc.r or c.g ~= cc.g or c.b ~= cc.b then
			changes = changes .. "color:#" .. string.format("%X", (c.r * 256 + c.g) * 256 + c.b) .. ";"
			cc = c
		end

		if changes ~= "" then
			s = s .. (first and "" or "</span>") .. '<span style="' .. changes .. '">'
			first = false
		end

		s = s .. (jn and ("&nbsp;"):rep((object.i or 0) * 4) or "") .. string.gsub(object.v or "", ".", function(c)
			local b = string.byte(c)

			return (b < 32 or b > 155 or b == 60 or b == 62 or b == 38) and "&#" .. b .. ";"
		end) .. (object.n and "<br/>\n" or "")

		jn = object.n
	end

	if !first then
		s = s .. "</span>"
	end

	return s
end

table.markup_colors = {
	table = Color(255, 150, 255),
	string = color_white,
	number = Color(255, 128, 0),
	boolean = Color(150, 255, 150),
	["function"] = Color(100, 150, 255),
	c_function = Color(100, 255, 255), -- what colour is this? :S
	default = Color(255, 100, 100),
}

table.markup_indent = "  "

function table.tomarkup(t, colors_override)
	return toMarkup(t, colors_override or table.markup_colors)
end

function table.print(tbl, colors_override)
	local markup = table.tomarkup(tbl, colors_override)
	local jn = true

	for oi = 1, #markup do
		local object = markup[oi]
		MsgC(object.c, (table.markup_indent):rep(jn and object.i or 0) .. (object.v or "") .. (object.n and "\n" or ""))
		jn = object.n
	end

	MsgC(table.markup_colors.default, "\n")
end

-- so we don't pass extra tables..
PrintTable = function(...)
	local info = debug.getinfo(2)

	if !info or conVarCheck:GetBool() == false then
		oldPTable(...)

		return
	end

	for k, tbl in pairs{...} do
		table.print(tbl)
	end
end

function table.tohtml(tbl, colors_override)
	return MarkupToHTML(table.tomarkup(tbl, colors_override))
end
