---@class gmcore
---@field Notify fun(msg: string|number|table, duration?: number, kind?: GLNotifyKind, sound?: string) Show a HUD notification (client-side).
---@field NotifyType table<string, GLNotifyKind> Notification type enums.

-- Types are defined in `sh_notifications.lua`.
local GLNotifyKind = gmcore.NotifyType

---@class gmcoreNotifyEntry
---@field text string Raw notification message text.
---@field kind GLNotifyKind Notification category (controls theme color, icon, title).
---@field start number `CurTime()` when the notification was created.
---@field expires number `CurTime()` when the notification should be removed.
---@field duration number Display duration in seconds.
---@field lines string[] Word-wrapped body lines for rendering.
---@field width number Pre-computed pixel width of the notification card.
---@field height number Pre-computed pixel height of the notification card.
---@field content_h number Height of the content area (title + body); also used as the icon size.

---@class gmcoreNotifyState
---@field list GLNotifyEntry[] Active notifications, ordered oldest-first.
---@type GLNotifyState
local NOTIFY = NOTIFY or {}
NOTIFY.list = NOTIFY.list or {}

local FONT_BODY = "GL_Notify_Body"
local FONT_TITLE = "GL_Notify_Title"
local MAX_WIDTH_RATIO = 0.42
local MAX_LINES = 4
local ICON_SIZE = 18

local iconMats = {}
---Returns cached IMaterial for the given texture path. Will create
---a new IMaterial if it doesn't already exist.
---@param path string Texture path (e.g. `"vgui/bell"`).
---@return IMaterial
local function getIconMat(path)
	if not iconMats[path] then
		iconMats[path] = Material(path, "smooth noclamp")
	end

	return iconMats[path]
end

local THEMES = {
	pointshop = {
		color = Color(46, 204, 113),
		icon = "gmcore/icons/shop",
		title = "Pointshop"
	},
	admin = {
		color = Color(243, 156, 18),
		icon = "gmcore/icons/shield-solid",
		title = "Admin"
	},
	game = {
		color = Color(52, 152, 219),
		icon = "gmcore/icons/bell",
		title = "Notice"
	},
	warn = {
		color = Color(231, 76, 60),
		icon = "gmcore/icons/triangle-solid",
		title = "Warning"
	},
	info = {
		color = Color(236, 240, 241),
		icon = "gmcore/icons/info-solid",
		title = "Info"
	}
}

surface.CreateFont(FONT_BODY, {
	font = "Space Grotesk",
	size = 20,
	weight = 500,
	antialias = true
})
surface.CreateFont(FONT_TITLE, {
	font = "Space Grotesk",
	size = 18,
	weight = 800,
	antialias = true
})

---Safely convert any nil value to string, or return string if not nil.
---@param msg any
---@return string
local function normalizeMessage(msg)
	if msg == nil then return "" end

	return tostring(msg)
end

---Wraps `text` into lines no wider than `max_width` pixels using `FONT_BODY`.
---Truncates to `MAX_LINES` lines, appending `...` to the last line if cut short.
---This is pretty hacky but hey, it works!
---@param text string Text to wrap.
---@param max_width number Maximum pixel width per line.
---@return string[] lines
local function wrapText(text, max_width)
	surface.SetFont(FONT_BODY)
	local words = string.Explode(" ", text)
	local lines = {}
	local current = ""

	for _, word in ipairs(words) do
		local test = current == "" and word or (current .. " " .. word)
		local w = surface.GetTextSize(test)

		if w > max_width and current != "" then
			table.insert(lines, current)
			current = word

			if #lines >= MAX_LINES then
				current = current .. "..."

				break
			end
		else
			current = test
		end
	end

	if current != "" and #lines < MAX_LINES then
		table.insert(lines, current)
	end

	return lines
end

---Returns theme table for the given kind. Falls back to `info` if unknown.
---@param kind GLNotifyKind
---@return {color: Color, icon: string, title: string}
local function getTheme(kind)
	return THEMES[kind] or THEMES.info
end

---Cubic ease-out: Used for slide-in animation.
---@param t number Normalised time [0, 1].
---@return number
local function easeOutCubic(t)
	t = math.Clamp(t, 0, 1)

	return 1 - (1 - t) ^ 3
end

---Cubic ease-in: Used for slide-out animation.
---@param t number Normalised time [0, 1].
---@return number
local function easeInCubic(t)
	t = math.Clamp(t, 0, 1)

	return t ^ 3
end

---@param msg string|number|table
---@param duration? number
---@param kind? GLNotifyKind
---@param sound? string Optional sound path to play when the notification appears (e.g. `"buttons/button15.wav"`).
---@return nil
function gmcore.Notify(msg, duration, kind, sound)
	local text = normalizeMessage(msg)
	if text == "" then return end

	local now = CurTime()
	local len = tonumber(duration) or 5
	len = math.Clamp(len, 1, 15)
	local k = kind or GLNotifyKind.INFO

	local title_h = 18
	local padding_x = 12
	local padding_y = 10
	local max_w = math.floor(ScrW() * MAX_WIDTH_RATIO)

	local theme = getTheme(k)
	surface.SetFont(FONT_TITLE)
	local title_w = surface.GetTextSize(theme.title)

	-- Estimate icon size with ICON_SIZE placeholder to get initial line count
	local text_w = max_w - (ICON_SIZE + padding_x + 8)
	local lines = wrapText(text, text_w)
	local body_h = #lines * 20
	local content_h = body_h + title_h - 2

	-- Re-wrap with actual icon size (content_h) if it grew beyond ICON_SIZE
	local real_text_w = max_w - (content_h + padding_x + 8)
	if real_text_w < text_w then
		lines = wrapText(text, real_text_w)
		body_h = #lines * 20
		content_h = body_h + title_h - 2
	end

	surface.SetFont(FONT_BODY)
	local max_line_w = 0
	for _, line in ipairs(lines) do
		local w = surface.GetTextSize(line)
		if w > max_line_w then max_line_w = w end
	end

	local content_w = math.max(max_line_w, title_w)
	local width = math.min(max_w, content_h + padding_x * 2 + content_w + 8) 	-- width = left pad + icon + gap + text + right pad
	local height = padding_y * 2 + content_h

	table.insert(NOTIFY.list, {
		text = text,
		kind = k,
		start = now,
		expires = now + len,
		duration = len,
		lines = lines,
		width = width,
		height = height,
		content_h = content_h
	})

	if sound and sound ~= "" then
		surface.PlaySound(sound)
	end
end

---Computes the current draw alpha [0-255] for a notification, applying linear
---fade-in and fade-out at the start and end of its lifetime.
---@param entry GLNotifyEntry
---@param now number Current `CurTime()`.
---@return number alpha Value in [0, 255].
local function calcAlpha(entry, now)
	local fade_in = 0.2
	local fade_out = 0.35
	local a = 255

	if now < entry.start + fade_in then
		a = math.Clamp((now - entry.start) / fade_in, 0, 1) * 255
	elseif now > entry.expires - fade_out then
		a = math.Clamp((entry.expires - now) / fade_out, 0, 1) * 255
	end

	return a
end

hook.Add("PostRenderVGUI", "gmcore.NotifyStack", function()
	if #NOTIFY.list == 0 then return end

	local now = CurTime()
	for i = #NOTIFY.list, 1, -1 do
		if now >= NOTIFY.list[i].expires then
			table.remove(NOTIFY.list, i)
		end
	end

	if #NOTIFY.list == 0 then return end

	local margin = 16
	local x = ScrW() - margin
	local y = ScrH() - margin

	for _, entry in ipairs(NOTIFY.list) do
		local theme = getTheme(entry.kind)
		local w = entry.width
		local h = entry.height
		local alpha = calcAlpha(entry, now)
		if alpha <= 0 then continue end

		local anim_in = easeOutCubic((now - entry.start) / 0.28)
		local anim_out = easeInCubic((entry.expires - now) / 0.25)
		local slide = (1 - anim_in) * 28 + (1 - anim_out) * -14
		local lift = (1 - anim_in) * 6

		local bx = x - w + slide
		local by = y - h + lift

		local bg_alpha = math.floor(alpha * 0.92)
		draw.RoundedBox(8, bx, by, w, h, Color(30, 42, 56, bg_alpha))
		draw.RoundedBox(8, bx, by, w, 1, Color(52, 73, 94, math.floor(alpha * 0.6)))
		draw.RoundedBox(8, bx, by, 4, h, Color(theme.color.r, theme.color.g, theme.color.b, alpha))

		local icon_x = bx + 12
		local icon_y = by + 10
		local icon_size = entry.content_h or ICON_SIZE

		if theme.icon then
			local mat = getIconMat(theme.icon)
			surface.SetMaterial(mat)
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawTexturedRect(icon_x, icon_y, icon_size, icon_size)
		end

		surface.SetFont(FONT_TITLE)
		surface.SetTextColor(theme.color.r, theme.color.g, theme.color.b, alpha)
		surface.SetTextPos(icon_x + icon_size + 8, by + 8)
		surface.DrawText(theme.title)

		surface.SetFont(FONT_BODY)
		surface.SetTextColor(236, 240, 241, alpha)

		local text_y = by + 28
		for _, line in ipairs(entry.lines) do
			surface.SetTextPos(icon_x + icon_size + 8, text_y)
			surface.DrawText(line)
			text_y = text_y + 20
		end

		y = y - (h + 10)
	end
end)

net.Receive("gmcore.Notifications.SendNotification", function()
	local msg = net.ReadString()
	local kind = net.ReadString()
	local length = net.ReadFloat()
	local sound = net.ReadString()

	gmcore.Notify(msg, length, kind, sound ~= "" and sound or nil)
end)
