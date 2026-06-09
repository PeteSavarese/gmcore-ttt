---@class gmcoreCardPanel : DPanel
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
end

function PANEL:Close()
	self.RemoveTime = CurTime()
end

function PANEL:Paint(w, h)
	local parent = self:GetParent()
	if not IsValid(parent) or parent == vgui.GetWorldPanel() then
		draw.RoundedBox(12, 0, 0, w, h, CARD_BORDER_COLOR)
		draw.RoundedBox(12, 1, 1, w - 2, h - 2, CARD_BACKGROUND_COLOR)
	else
		draw.RoundedBox(12, 0, 0, w, h, CARD_BACKGROUND_COLOR)
	end
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

derma.DefineControl("GmcoreCardPanel", "", PANEL, "DPanel")
