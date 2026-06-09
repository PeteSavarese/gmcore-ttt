local FONT_NOTICE_CARD_TEXT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 18,
	weight = 500,
	antialias = true,
})

---@class gmcoreNoticeCard : DPanel
---@field SetFadeOnOpen fun(self: GLNoticeCard, val: boolean) Enable or disable the fade-in animation when the panel is created.
---@field GetFadeOnOpen fun(self: GLNoticeCard): boolean Returns whether the fade-in animation is enabled.
---@field SetFadeOnRemove fun(self: GLNoticeCard, val: boolean) Enable or disable the fade-out animation when the panel is closed.
---@field GetFadeOnRemove fun(self: GLNoticeCard): boolean Returns whether the fade-out animation is enabled.
local PANEL = {}

AccessorFunc(PANEL, "m_bFadeOnOpen", "FadeOnOpen", FORCE_BOOL)
AccessorFunc(PANEL, "m_bFadeOnRemove", "FadeOnRemove", FORCE_BOOL)

function PANEL:Init()
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetFadeOnOpen(true)
	self:SetFadeOnRemove(true)

	self.CreateTime = CurTime()
	self.RemoveTime = 0

	self.infoIcon = vgui.Create("DImage", self)
	self.infoIcon.Material = Material("vgui/info-circle-solid.png", "mips smooth")
	self.infoIcon:SetSize(20, 20)
	self.infoIcon:SetPos(15, 15)
	self.infoIcon.Paint = function(s, w, h)
		surface.SetMaterial(s.Material)
		surface.SetDrawColor(PRIMARY_ACCENT_COLOR)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	self.textLabel = vgui.Create("DLabel", self)
	self.textLabel:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	self.textLabel:SetFont(FONT_NOTICE_CARD_TEXT)
	self.textLabel:SetWrap(true)
	self.textLabel:SetContentAlignment(7)
end

function PANEL:Close()
	self.RemoveTime = CurTime()
end

function PANEL:SetText(text)
	self.textLabel:SetText(text)
	self:InvalidateLayout(true)
end

function PANEL:PerformLayout(w, h)
	local contentWidth = w - 30
	local iconSize = self.infoIcon:GetWide()

	self.textLabel:SetPos(15 + iconSize + 15, 15)
	self.textLabel:SetWide(contentWidth - iconSize - 15)

	self.textLabel:SizeToContentsY()

	local contentHeight = math.max(self.textLabel:GetTall(), iconSize)
	self:SetTall(contentHeight + 30)
end

function PANEL:Paint(w, h)
	draw.RoundedBox(10, 0, 0, w, h, CARD_BACKGROUND_COLOR)

	-- Left accent bar
	draw.RoundedBoxEx(10, 0, 0, 4, h, PRIMARY_ACCENT_COLOR, true, false, true, false)
	surface.SetDrawColor(CARD_BORDER_COLOR)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function PANEL:Think()
	if self.RemoveTime == 0 and self:GetFadeOnOpen() then
		local frac = math.TimeFraction(self.CreateTime, self.CreateTime + 0.45, CurTime())
		self:SetAlpha(Lerp(math.ease.InOutQuart(frac), self:GetAlpha(), 255))
	elseif self.RemoveTime ~= 0 and self:GetFadeOnRemove() then
		if self:GetAlpha() == 0 then
			self:Remove()
		end

		local frac = math.TimeFraction(self.RemoveTime, self.RemoveTime + 0.45, CurTime())
		self:SetAlpha(Lerp(math.ease.InOutQuart(frac), self:GetAlpha(), 0))
	end
end

derma.DefineControl("GmcoreNoticeCard", "", PANEL, "DPanel")
