local FONT_CHECKBOX_TEXT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 18,
	weight = 400,
})

local CHECKBOX_TEXT_LEFT_PADDING = 10

---@class gmcoreCheckBoxLabel : DCheckBox
local PANEL = {}

function PANEL:Init()
	self.Text = ""
	self.CheckProgress = 0
	self.CheckTarget = 0
	self.HoverAlpha = 0
	self:SetSize(50, 25)

	self.lblText = vgui.Create("DLabel", self)
	self.lblText:SetPos(0, 0)
	self.lblText:SetText("")
	self.lblText:SetFont(FONT_CHECKBOX_TEXT)
	self.lblText:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
end

function PANEL:SetText(text)
	self.Text = text
	self.lblText:SetText(self.Text)

	self:PerformLayout()
end

function PANEL:OnChange(val)
	self.CheckTarget = val and 1 or 0
end


local MAT_WHITE = Material("vgui/white")

local function drawSegment(x1, y1, x2, y2, thickness, t)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	if len <= 0 then return end

	local clamped = math.Clamp(t or 1, 0, 1)
	local endx = x1 + dx * clamped
	local endy = y1 + dy * clamped
	local cx = (x1 + endx) * 0.5
	local cy = (y1 + endy) * 0.5
	local segLen = len * clamped
	if segLen <= 0.5 then return end

	local angle = math.deg(math.atan2(dy, dx))
	surface.DrawTexturedRectRotated(cx, cy, thickness, segLen, angle)
end

function PANEL:Paint(w, h)
	draw.RoundedBox(6, 0, 0, self:GetTall(), self:GetTall(), INPUT_BG_COLOR)
	surface.SetDrawColor(INPUT_BORDER_COLOR)
	surface.DrawOutlinedRect(0, 0, self:GetTall(), self:GetTall(), 1)

	local target = self:GetChecked() and 1 or 0
	if self.CheckTarget ~= target then
		self.CheckTarget = target
	end

	self.CheckProgress = Lerp(FrameTime() * 12, self.CheckProgress or 0, self.CheckTarget)
	local ease = (math.ease and math.ease.InOutQuart) and math.ease.InOutQuart or function(t) return t end
	local progress = ease(self.CheckProgress)

	local bg = Color(
		Lerp(progress, INPUT_BG_COLOR.r, BUTTON_ACCENT_COLOR.r),
		Lerp(progress, INPUT_BG_COLOR.g, BUTTON_ACCENT_COLOR.g),
		Lerp(progress, INPUT_BG_COLOR.b, BUTTON_ACCENT_COLOR.b),
		255
	)
	draw.RoundedBox(6, 0, 0, self:GetTall(), self:GetTall(), bg)

	-- Hover highlight
	if self.Hovered then
		self.HoverAlpha = Lerp(FrameTime() * 8, self.HoverAlpha, 30)
	else
		self.HoverAlpha = Lerp(FrameTime() * 8, self.HoverAlpha, 0)
	end
	if self.HoverAlpha > 0.5 then
		draw.RoundedBox(6, 0, 0, self:GetTall(), self:GetTall(), Color(255, 255, 255, self.HoverAlpha))
	end

	if progress > 0 then
		local box = self:GetTall()
		local pad = math.max(3, math.floor(box * 0.2))
		local x1, y1 = pad, box * 0.58
		local x2, y2 = box * 0.46, box * 0.76
		local x3, y3 = box - pad, box * 0.28

		surface.SetDrawColor(255, 255, 255, 245)
		local thickness = math.max(2, box * 0.18)
		surface.SetMaterial(MAT_WHITE)

		if progress <= 0.5 then
			local t = progress / 0.5
			drawSegment(x1, y1, x2, y2, thickness, t)
		else
			local t = (progress - 0.5) / 0.5
			drawSegment(x1, y1, x2, y2, thickness, 1)
			drawSegment(x2, y2, x3, y3, thickness, t)
		end
	end
end

function PANEL:PerformLayout(w, h)
	self.lblText:SizeToContents()
	self.lblText:SetPos(self:GetTall() + CHECKBOX_TEXT_LEFT_PADDING, (self:GetTall() / 2) - (self.lblText:GetTall() / 2))

	self:SetSize(self.lblText:GetWide() + self:GetTall() + CHECKBOX_TEXT_LEFT_PADDING, self.lblText:GetTall() + 10)
end

vgui.Register("GmcoreCheckBoxLabel", PANEL, "DCheckBox")
