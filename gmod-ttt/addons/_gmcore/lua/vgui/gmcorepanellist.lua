---@class gmcorePanelList : DPanelList
local PANEL = {}

AccessorFunc(PANEL, "m_BackgroundColor", "BackgroundColor", FORCE_COLOR)
AccessorFunc(PANEL, "m_BorderColor", "BorderColor", FORCE_COLOR)

function PANEL:Init()
	self.BaseClass.Init(self)
	self:SetBackgroundColor(CARD_BACKGROUND_COLOR)
	self:SetBorderColor(CARD_BORDER_COLOR)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
end

function PANEL:Paint(w, h)
	local parent = self:GetParent()
	local bg = self:GetBackgroundColor() or CARD_BACKGROUND_COLOR
	if not IsValid(parent) or parent == vgui.GetWorldPanel() then
		draw.RoundedBox(8, 0, 0, w, h, self:GetBorderColor() or CARD_BORDER_COLOR)
		draw.RoundedBox(8, 1, 1, w - 2, h - 2, bg)
	else
		draw.RoundedBox(8, 0, 0, w, h, bg)
	end
end

derma.DefineControl("GmcorePanelList", "GL-styled DPanelList", PANEL, "DPanelList")
