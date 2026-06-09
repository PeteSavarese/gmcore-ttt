local FONT_TEXTINPUT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 20,
	weight = 500,
	antialias = true,
})

---@class gmcoreTextInput : EditablePanel
local PANEL = {}

AccessorFunc(PANEL, "m_TextEntryHint", "Hint", FORCE_STRING)
AccessorFunc(PANEL, "m_HintAnimation", "HintAnimation", FORCE_BOOL)
AccessorFunc(PANEL, "m_FocusedAccentColor", "FocusColor", FORCE_COLOR)

function PANEL:Init()
	self:SetHint("")
	self:SetHintAnimation(false)
	self:SetFocusColor(PRIMARY_ACCENT_COLOR)

	self.inputTextField = vgui.Create("DTextEntry", self)
	self.inputTextField:SetSize(self:GetWide(), 26)
	self.inputTextField:SetTextColor(color_white)
	self.inputTextField:SetFont(FONT_TEXTINPUT)
	self.inputTextField.OnChange = function(s)
		return self:OnChange()
	end

	self.inputTextField.Paint = function(s)
		s:DrawTextEntryText(s:GetTextColor(), Color(255, 255, 255, 15), Color(255, 255, 255))
	end

	self.activeIndicatorWidth = 0
end

function PANEL:PaintHintAnim(w, h)
	local HINT_LABEL_PADDING = self:GetHint() ~= "" and 10 or 0

	surface.SetFont(FONT_TEXTINPUT)
	local hintTextW, hintTextH = surface.GetTextSize(self:GetHint())

	if not self.inputTextField.InitWidthSet and self.inputTextField:GetValue() == "" then
		surface.SetFont(FONT_TEXTINPUT)
		local _, fontH = surface.GetTextSize("Ay")
		local desiredTall = math.min(h - 8, math.max(24, fontH + 8))
		self.inputTextField:SetSize(w, desiredTall)
		self.inputTextField:SetPos(0, (h / 2) - (desiredTall / 2))
		self.inputTextField.InitWidthSet = true
	elseif not self.inputTextField.InitWidthSet and self.inputTextField:GetValue() ~= "" then
		surface.SetFont(FONT_TEXTINPUT)
		local _, fontH = surface.GetTextSize("Ay")
		local desiredTall = math.min(h - 8, math.max(24, fontH + 8))
		self.inputTextField:SetSize(self:GetWide() - HINT_LABEL_PADDING, desiredTall)
		self.inputTextField:SetPos(hintTextW + HINT_LABEL_PADDING, (h / 2) - (desiredTall / 2))
	end

	draw.RoundedBox(8, self.inputTextField:GetX(), 0, self.inputTextField:GetWide(), self:GetTall(), INPUT_BG_COLOR)
	surface.SetDrawColor(INPUT_BORDER_COLOR)
	surface.DrawOutlinedRect(self.inputTextField:GetX(), 0, self.inputTextField:GetWide(), self:GetTall(), 1)

	surface.SetTextColor(255, 255, 255, 150)
	surface.SetTextPos(3, (h / 2) - (hintTextH / 2))
	surface.DrawText(self:GetHint())

	if not self.inputTextField:HasFocus() then
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, 0, FrameTime() * 2500)
	else
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, self.inputTextField:GetWide(), FrameTime() * 2500)
	end

	if self.inputTextField:GetText() ~= "" or self.inputTextField:HasFocus() then
		local newWidth = math.Approach(self.inputTextField:GetWide(), self:GetWide() - hintTextW - HINT_LABEL_PADDING, 2)
		local newPosX = math.Approach(self.inputTextField:GetX(), 3 + hintTextW + HINT_LABEL_PADDING, 2)
		surface.SetFont(FONT_TEXTINPUT)
		local _, fontH = surface.GetTextSize("Ay")
		local desiredTall = math.min(h - 8, math.max(24, fontH + 8))
		self.inputTextField:SetSize(newWidth, desiredTall)
		self.inputTextField:SetPos(newPosX, (h / 2) - (desiredTall / 2))
	elseif self.inputTextField:GetText() == "" then
		local newWidth = math.Approach(self.inputTextField:GetWide(), w, 2)
		local newPosX = math.Approach(self.inputTextField:GetX(), 0, 2)
		surface.SetFont(FONT_TEXTINPUT)
		local _, fontH = surface.GetTextSize("Ay")
		local desiredTall = math.min(h - 8, math.max(24, fontH + 8))
		self.inputTextField:SetSize(newWidth, desiredTall)
		self.inputTextField:SetPos(newPosX, (h / 2) - (desiredTall / 2))
	end

	surface.SetDrawColor(self:GetFocusColor())
	surface.DrawRect((self.inputTextField:GetWide() / 2) - (self.activeIndicatorWidth / 2) + self.inputTextField:GetX(), h - 3, self.activeIndicatorWidth, 3)
end

function PANEL:Paint(w, h)
	if self:GetHintAnimation() then
		return self:PaintHintAnim(w, h)
	end

	local HINT_LABEL_PADDING = self:GetHint() ~= "" and 10 or 0

	surface.SetFont(FONT_TEXTINPUT)
	local hintTextW, hintTextH = surface.GetTextSize(self:GetHint())

	self.inputTextField:SetPos(hintTextW + HINT_LABEL_PADDING, (h / 2) - (self.inputTextField:GetTall() / 2))
	surface.SetFont(FONT_TEXTINPUT)
	local _, fontH = surface.GetTextSize("Ay")
	local desiredTall = math.min(h - 8, math.max(24, fontH + 8))
	self.inputTextField:SetSize(self:GetWide() - self.inputTextField:GetX() - HINT_LABEL_PADDING, desiredTall)

	draw.RoundedBox(8, self.inputTextField:GetX(), 0, self.inputTextField:GetWide(), self:GetTall(), INPUT_BG_COLOR)
	surface.SetDrawColor(INPUT_BORDER_COLOR)
	surface.DrawOutlinedRect(self.inputTextField:GetX(), 0, self.inputTextField:GetWide(), self:GetTall(), 1)

	surface.SetTextColor(255, 255, 255, 150)
	surface.SetTextPos(0, (h / 2) - (hintTextH / 2))
	surface.DrawText(self:GetHint())

	if not self.inputTextField:HasFocus() then
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, 0, FrameTime() * 2500)
	else
		self.activeIndicatorWidth = math.Approach(self.activeIndicatorWidth, self.inputTextField:GetWide(), FrameTime() * 2500)
	end

	surface.SetDrawColor(self:GetFocusColor())
	surface.DrawRect((self:GetWide() / 2) - (self.activeIndicatorWidth / 2) + (self.inputTextField:GetX() / 2) - (HINT_LABEL_PADDING / 2), h - 3, self.activeIndicatorWidth, 3)
end

function PANEL:SetValue(text)
	return self.inputTextField:SetValue(text)
end

function PANEL:GetValue(text)
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

function PANEL:OnMousePressed(mouseCode)
	self.inputTextField:RequestFocus()
end

derma.DefineControl("GmcoreTextInput", "A simple window", PANEL, "EditablePanel")
