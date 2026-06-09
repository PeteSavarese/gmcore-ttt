local FONT_TITLE = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 22,
	weight = 600,
	antialias = true,
})

local FONT_INFO = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 16,
	weight = 500,
	antialias = true,
})

local FONT_PILL = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 13,
	weight = 500,
	antialias = true,
})

--- Height in pixels of each server card. **Must match CARD_H in cl_serverhopper.lua.**
local CARD_HEIGHT = 90
local CARD_RADIUS = 12
local IMG_W = 100 -- map thumbnail width (px)
local IMG_H = 74 -- map thumbnail height (px)
local IMG_PAD = 8 -- horizontal gap on either side of the thumbnail
local PILL_PAD_X = 8 -- horizontal inner padding of the player-count pill
local PILL_PAD_Y = 3 -- vertical inner padding of the player-count pill
local DOT_SIZE = 8 -- diameter of the online-status dot
local DOT_COLOUR = Color(46, 213, 115) -- Online status indicator colour. All servers from the API feed are considered reachable.

---@class gmcoreServerCard : DPanel
local PANEL = {}

function PANEL:Init()
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetTall(CARD_HEIGHT)

	---@type number Hover-border animation accumulator (0 = idle, 1 = fully hovered).
	self.HoverAlpha = 0

	---@type string Player-count pill text populated by SetServerData
	self._pillText = ""

	-- Map thumbnail rendered by off-screen Chromium HTML panel.
	self.mapImg = vgui.Create("HTML", self)
	self.mapImg:SetSize(IMG_W, IMG_H)
	self.mapImg:SetPos(IMG_PAD, (CARD_HEIGHT - IMG_H) / 2)
	self.mapImg:SetMouseInputEnabled(false)
	-- Scrollbars are suppressed via `overflow: hidden` in the injected CSS;
	-- SetScrollbarsEnabled is only available on DHTML, not the base HTML panel.

	-- Server hostname in bold title weight.
	self.lblName = vgui.Create("DLabel", self)
	self.lblName:SetFont(FONT_TITLE)
	self.lblName:SetTextColor(CARD_TITLE_TEXT_COLOR)
	self.lblName:SetText("")
	self.lblName:SetAutoStretchVertical(true)

	-- Current map name in muted secondary colour (player pill drawn in Paint beside it).
	self.lblMap = vgui.Create("DLabel", self)
	self.lblMap:SetFont(FONT_INFO)
	self.lblMap:SetTextColor(CARD_TEXT_SECONDARY_COLOR)
	self.lblMap:SetText("")

	-- Connect button - right-aligned, vertically centred.
	self.btnConnect = vgui.Create("GmcoreButton", self)
	self.btnConnect:SetText("Connect")
	self.btnConnect:SizeToText()
	self.btnConnect:SetBackgroundColor(BUTTON_ACCENT_COLOR)
end

--- Populates the card from a server-list API entry.
---@param data table Server entry with fields: hostName, currentMap, playerCount, maxCount, serverAddr
function PANEL:SetServerData(data)
	self.lblName:SetText(data.hostName or "Unknown")
	self.lblMap:SetText(data.currentMap or "")

	self._pillText = string.format("%d / %d", data.playerCount or 0, data.maxCount or 0)

	local base = (GetGlobalString("gmcore.ForumsBaseUrl", ""):gsub("/+$", ""))
	self.mapImg:SetHTML(string.format([[
		<style>
			html, body { margin: 0; padding: 0; overflow: hidden; background: #0e141c; }
			img { display: block; width: %dpx; height: %dpx; object-fit: cover; }
		</style>
		<img src="%s/images/maps/%s.png">
	]], IMG_W, IMG_H, base, data.currentMap or ""))

	self:InvalidateLayout(true)
end

--- Sets callback fired when the Connect button is clicked.
---@param fn fun() Called with no arguments; implement connect and menu-close logic inside.
function PANEL:SetOnConnect(fn)
	self.btnConnect.DoClick = fn
end

--- Positions all child elements. Called automatically by dock.
---@param w number Current panel width.
---@param h number Current panel height.
function PANEL:PerformLayout(w, h)
	local btnW = self.btnConnect:GetWide()
	local btnH = self.btnConnect:GetTall()
	self.btnConnect:SetPos(w - btnW - 12, (h - btnH) / 2)

	local contentX = IMG_PAD + IMG_W + 10

	-- Reserve space for status dot.
	local contentW = self.btnConnect.x - DOT_SIZE - 20 - contentX

	-- Server name
	self.lblName:SetPos(contentX, 14)
	self.lblName:SetWide(contentW)
	self.lblName:SizeToContentsY()

	self.lblMap:SetPos(contentX, self.lblName.y + self.lblName:GetTall() + 4)
	self.lblMap:SizeToContents()
end

--- Advances the hover-border lerp animation each frame.
function PANEL:Think()
	if self.Hovered then
		self.HoverAlpha = Lerp(FrameTime() * 8, self.HoverAlpha, 1)
	else
		self.HoverAlpha = Lerp(FrameTime() * 8, self.HoverAlpha, 0)
	end
end

--- Draws card background, animated border, left accent bar, status dot and player-count pill.
---@param w number Panel width.
---@param h number Panel height.
function PANEL:Paint(w, h)
	-- Card background.
	draw.RoundedBox(CARD_RADIUS, 0, 0, w, h, CARD_BACKGROUND_COLOR)

	-- 3 px left accent bar
	draw.RoundedBoxEx(CARD_RADIUS, 0, 0, 3, h, PRIMARY_ACCENT_COLOR, true, false, true, false)

	-- Border that lerps from default dark-blue to accent colour on hover.
	local a = self.HoverAlpha
	surface.SetDrawColor(
		Lerp(a, CARD_BORDER_COLOR.r, PRIMARY_ACCENT_COLOR.r),
		Lerp(a, CARD_BORDER_COLOR.g, PRIMARY_ACCENT_COLOR.g),
		Lerp(a, CARD_BORDER_COLOR.b, PRIMARY_ACCENT_COLOR.b),
		Lerp(a, CARD_BORDER_COLOR.a, 255)
	)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	-- Online status dot
	if IsValid(self.btnConnect) then
		local dotX = self.btnConnect.x - DOT_SIZE - 10
		local dotY = (h - DOT_SIZE) / 2

		draw.RoundedBox(DOT_SIZE / 2, dotX, dotY, DOT_SIZE, DOT_SIZE, DOT_COLOUR)
	end

	-- Player-count pill
	if self._pillText ~= "" and IsValid(self.lblMap) then
		surface.SetFont(FONT_PILL)

		local tw, th = surface.GetTextSize(self._pillText)
		local pillW = tw + PILL_PAD_X * 2
		local pillH = th + PILL_PAD_Y * 2
		local pillX = self.lblMap.x + self.lblMap:GetWide() + 6
		local pillY = self.lblMap.y + (self.lblMap:GetTall() - pillH) / 2

		draw.RoundedBox(999, pillX, pillY, pillW, pillH, Color(14, 20, 28, 210))
		surface.SetDrawColor(52, 73, 94, 120)
		surface.DrawOutlinedRect(pillX, pillY, pillW, pillH, 1)
		draw.SimpleText(
			self._pillText, FONT_PILL,
			pillX + pillW / 2, pillY + PILL_PAD_Y,
			PRIMARY_ACCENT_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
		)
	end
end

derma.DefineControl("GmcoreServerCard", "GMCore server entry card", PANEL, "DPanel")
