local FONT_TEXTAREA = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 18,
	weight = 500,
	antialias = true,
})

---@class gmcoreTextArea : EditablePanel
local PANEL = {}

AccessorFunc(PANEL, "m_TextEntryHint", "Hint", FORCE_STRING)
AccessorFunc(PANEL, "m_FocusedAccentColor", "FocusColor", FORCE_COLOR)

function PANEL:Init()
	self:SetHint("")
	self:SetFocusColor(PRIMARY_ACCENT_COLOR)

	self.Padding = 8

	self.inputTextField = vgui.Create("DTextEntry", self)
	self.inputTextField:SetMultiline(true)
	self.inputTextField:SetTextColor(color_white)
	self.inputTextField:SetFont(FONT_TEXTAREA)
	self.inputTextField.OnChange = function()
		return self:OnChange()
	end

	self.inputTextField.Paint = function(s)
		s:DrawTextEntryText(s:GetTextColor(), Color(255, 255, 255, 15), Color(255, 255, 255))
	end

	self.activeIndicatorWidth = 0
end

function PANEL:PerformLayout(w, h)
	local pad = self.Padding or 0
	self.inputTextField:SetPos(pad, pad)
	self.inputTextField:SetSize(math.max(w - pad * 2, 0), math.max(h - pad * 2, 0))
end

function PANEL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, INPUT_BG_COLOR)
	surface.SetDrawColor(INPUT_BORDER_COLOR)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	if self:GetHint() ~= "" and self.inputTextField:GetText() == "" and not self.inputTextField:HasFocus() then
		local pad = self.Padding or 0
		surface.SetFont(FONT_TEXTAREA)
		surface.SetTextColor(255, 255, 255, 160)
		surface.SetTextPos(pad + 2, pad + 2)
		surface.DrawText(self:GetHint())
	end

	if not self.inputTextField:HasFocus() then
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, 0, FrameTime() * 2500)
	else
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, w, FrameTime() * 2500)
	end

	surface.SetDrawColor(self:GetFocusColor())
	surface.DrawRect((w / 2) - (self.activeIndicatorWidth / 2), h - 3, self.activeIndicatorWidth, 3)
end

function PANEL:SetValue(text)
	return self.inputTextField:SetValue(text)
end

function PANEL:GetValue()
	return self.inputTextField:GetValue()
end

function PANEL:GetInputPanel()
	return self.inputTextField
end

function PANEL:SetTextColor(...)
	return self.inputTextField:SetTextColor(...)
end

function PANEL:SetNumeric(...)
	return self.inputTextField:SetNumeric(...)
end

function PANEL:OnChange()
	return self.inputTextField.OnChange
end

function PANEL:Think()
	if self.Hovered then
		self:SetCursor("beam")
	end
end

function PANEL:OnMousePressed()
	self.inputTextField:RequestFocus()
end

derma.DefineControl("GmcoreTextArea", "Multiline GL text input", PANEL, "EditablePanel")
