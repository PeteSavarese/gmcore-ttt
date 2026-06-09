---Shared Derma utility functions (blur, popups, dialogs, etc.).

local FONT_DIALOG_HEADER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 28,
	weight = 600,
	antialias = true,
})

local FONT_DIALOG_TEXT = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 22,
	weight = 400,
	antialias = true,
})


local matBlurScreen = Material( "pp/blurscreen" )

function Derma_DrawBackgroundBlur(panel, starttime)
	local Fraction = 1

	if (starttime) then
		Fraction = math.Clamp((CurTime() - starttime) / 1, 0, 1)
	end

	local x, y = panel:LocalToScreen(0, 0)
	local wasEnabled = DisableClipping(true)

	if not MENU_DLL then
		surface.SetMaterial(matBlurScreen)
		surface.SetDrawColor(255, 255, 255, 255)

		for i = 0.33, 1, 0.33 do
			matBlurScreen:SetFloat("$blur", Fraction * 5 * i)
			matBlurScreen:Recompute()

			if (render) then
				render.UpdateScreenEffectTexture()
			end

			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	surface.SetDrawColor(10, 10, 10, 200 * Fraction)
	surface.DrawRect(x * -1, y * -1, ScrW(), ScrH())
	DisableClipping(wasEnabled)
end

function GMCore_MessageDialog(strText, strTitle, strButtonText)
	local window = vgui.Create("EditablePanel")
	window:SetAlpha(0)
	window.CreateTime = CurTime()
	window.RemoveTime = 0
	window.Paint = function(s, w, h)
		Derma_DrawBackgroundBlur(s, 0)

		if s.RemoveTime == 0 then
			local frac = math.TimeFraction(s.CreateTime, s.CreateTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 255))
		else
			local frac = math.TimeFraction(s.RemoveTime, s.RemoveTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 0))
		end

		draw.RoundedBox(10, 0, 0, w, h, FRAME_BACKGROUND_COLOR)
		surface.SetDrawColor(FRAME_BORDER_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	window.Think = function(s)
		if s.RemoveTime ~= 0 and s:GetAlpha() == 0 then
			s:Remove()
		end
	end

	local windowTitle = vgui.Create("DLabel", window)
	windowTitle:SetText(strTitle)
	windowTitle:SetFont(FONT_DIALOG_HEADER)
	windowTitle:SetTextColor(CARD_TITLE_TEXT_COLOR)
	windowTitle:SizeToContents()
	windowTitle:SetPos(16, 14)

	local mainContainer = vgui.Create("Panel", window)

	local dialogText = vgui.Create("DLabel", mainContainer)
	dialogText:SetText(strText or "Message Text")
	dialogText:SetFont(FONT_DIALOG_TEXT)
	dialogText:SizeToContents()
	dialogText:SetContentAlignment(5)
	dialogText:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	dialogText:SetPos(16, windowTitle:GetY() - 5)

	local button

	function window:SetDialogText(newText)
		if not IsValid(dialogText) then return end

		dialogText:SetText(newText or "")
		dialogText:SizeToContents()

		local w = dialogText:GetWide()
		if IsValid(button) then
			w = math.max(w, button:GetWide())
		end

		local buttonH = IsValid(button) and button:GetTall() or 0
		local winH = 36 + dialogText:GetTall() + 12 + buttonH + 12

		window:SetSize(w + 60, winH)
		window:Center()

		mainContainer:SetSize(window:GetWide(), window:GetTall() - 36)
		mainContainer:SetPos(0, 36)

		if IsValid(button) then
			button:SetPos(mainContainer:GetWide() - button:GetWide() - 16, mainContainer:GetTall() - button:GetTall() - 8)
		end
	end

	button = vgui.Create("GmcoreButton", mainContainer)
	button:SetText(strButtonText or "OK")
	button:SetTextColor(color_white)
	button:SizeToText()
	button.DoClick = function()
		window.RemoveTime = CurTime()

		timer.Simple(1, function()
			if not IsValid(window) or window == nil then return end
			window:Remove()
		end)
	end

	local w = dialogText:GetWide()
	w = math.max(w, button:GetWide())

	local buttonH = button:GetTall()
	local winH = 36 + dialogText:GetTall() + 12 + buttonH + 12

	window:SetSize(w + 60, winH)
	window:Center()

	mainContainer:SetSize(window:GetWide(), window:GetTall() - 36)
	mainContainer:SetPos(0, 36)

	button:SetPos(mainContainer:GetWide() - button:GetWide() - 16, mainContainer:GetTall() - button:GetTall() - 8)

	window:MakePopup()
	window:DoModal()

	return window
end

function GL_StringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )
	local window = vgui.Create("EditablePanel")
	window:SetAlpha(0)
	window.CreateTime = CurTime()
	window.RemoveTime = 0
	window.Paint = function(s, w, h)
		Derma_DrawBackgroundBlur(s, 0)

		if s.RemoveTime == 0 then
			local frac = math.TimeFraction(s.CreateTime, s.CreateTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 255))
		else
			local frac = math.TimeFraction(s.RemoveTime, s.RemoveTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 0))
		end

		draw.RoundedBox(10, 0, 0, w, h, FRAME_BACKGROUND_COLOR)
		surface.SetDrawColor(FRAME_BORDER_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	window.Think = function(s)
		if s.RemoveTime ~= 0 and s:GetAlpha() == 0 then
			s:Remove()
		end
	end

	local windowTitle = vgui.Create("DLabel", window)
	windowTitle:SetText(strTitle or "Message")
	windowTitle:SetFont(FONT_DIALOG_HEADER)
	windowTitle:SetTextColor(CARD_TITLE_TEXT_COLOR)
	windowTitle:SizeToContents()
	windowTitle:SetPos(16, 14)

	local mainContainer = vgui.Create("Panel", window)

	local dialogText = vgui.Create("DLabel", mainContainer)
	dialogText:SetText(strText or "Message Text")
	dialogText:SetFont(FONT_DIALOG_TEXT)
	dialogText:SizeToContents()
	dialogText:SetContentAlignment(5)
	dialogText:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	dialogText:SetPos(16, windowTitle:GetY() - 5)

	local textEntry = vgui.Create("GmcoreTextInput", mainContainer)
	textEntry:SetValue(strDefaultText or "")
	local innerInput = textEntry:GetInputPanel()
	local buttonPanel = vgui.Create("DPanel", window)
	buttonPanel.Paint = function() end

	local function closeAndCall(cb, ...)
		if IsValid(window) then
			window.RemoveTime = CurTime()
		end
		if cb and isfunction(cb) then
			pcall(cb, ...)
		end

		timer.Simple(1, function()
			if IsValid(window) then window:Remove() end
		end)
	end

	if IsValid(innerInput) then
		innerInput:RequestFocus()
		innerInput:SelectAll(true)
		innerInput:SetAllowNonAsciiCharacters(true)
		innerInput.OnEnter = function()
			closeAndCall(fnEnter, textEntry:GetValue())
		end
	end

	local btnOK = vgui.Create("GmcoreButton", buttonPanel)
	btnOK:SetText(strButtonText or "OK")
	btnOK:SetTextColor(color_white)
	btnOK:SizeToText()
	btnOK.DoClick = function()
		closeAndCall(fnEnter, textEntry:GetValue())
	end

	local btnCancel = vgui.Create("GmcoreButton", buttonPanel)
	btnCancel:SetText(strButtonCancelText or "Cancel")
	btnCancel:SetTextColor(color_white)
	btnCancel:SizeToText()
	btnCancel.DoClick = function()
		closeAndCall(fnCancel, textEntry:GetValue())
	end

	textEntry.OnEnter = function()
		closeAndCall(fnEnter, textEntry:GetValue())
	end

	local w = dialogText:GetWide()
	w = math.max(w, 380)

	local entryH = 30
	local buttonPanelH = 38
	local winH = 36 + dialogText:GetTall() + 12 + entryH + 12 + buttonPanelH + 12

	window:SetSize(w + 60, winH)
	window:Center()

	mainContainer:SetSize(window:GetWide(), window:GetTall() - 36)
	mainContainer:SetPos(0, 36)

	local entryY = dialogText:GetY() + dialogText:GetTall() + 12
	textEntry:SetPos(16, entryY)
	textEntry:SetSize(mainContainer:GetWide() - 32, 30)

	buttonPanel:SetSize(window:GetWide() - 16, 38)
	buttonPanel:SetPos(8, window:GetTall() - 46)

	btnCancel:SetPos(buttonPanel:GetWide() - btnCancel:GetWide() - 16, 5)
	btnOK:SetPos(btnCancel:GetX() - btnOK:GetWide() - 8, 5)

	window:MakePopup()
	window:DoModal()

	return window
end

function GMCore_DialogQuery(strText, strTitle, ...)
	local window = vgui.Create("EditablePanel")
	window:SetAlpha(0)
	window.CreateTime = CurTime()
	window.RemoveTime = 0
	window.Paint = function(s, w, h)
		Derma_DrawBackgroundBlur(s, 0)

		if s.RemoveTime == 0 then
			local frac = math.TimeFraction(s.CreateTime, s.CreateTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 255))
		else
			local frac = math.TimeFraction(s.RemoveTime, s.RemoveTime + 0.45, CurTime())
			s:SetAlpha(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 0))
		end

		draw.RoundedBox(10, 0, 0, w, h, FRAME_BACKGROUND_COLOR)
		surface.SetDrawColor(FRAME_BORDER_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	window.Think = function(s)
		if s.RemoveTime ~= 0 and s:GetAlpha() == 0 then
			s:Remove()
		end
	end

	local windowTitle = vgui.Create("DLabel", window)
	windowTitle:SetText(strTitle)
	windowTitle:SetFont(FONT_DIALOG_HEADER)
	windowTitle:SetTextColor(CARD_TITLE_TEXT_COLOR)
	windowTitle:SizeToContents()
	windowTitle:SetPos(16, 14)

	local mainContainer = vgui.Create("Panel", window)

	local dialogText = vgui.Create("DLabel", mainContainer)
	dialogText:SetText(strText or "Message Text")
	dialogText:SetFont(FONT_DIALOG_TEXT)
	dialogText:SizeToContents()
	dialogText:SetContentAlignment(5)
	dialogText:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
	dialogText:SetPos(16, windowTitle:GetY() - 5)

	local buttonPanel = vgui.Create("DPanel", window)
	buttonPanel.Paint = function() end

	local numOptions = 0
	local btnPosX = 5

	for i = 1, 8, 2 do
		local btnText = select(i, ...)
		if btnText == nil then break end

		local btnFunc = select(i + 1, ...) or function() end

		local button = vgui.Create("GmcoreButton", buttonPanel)
		button:SetText(btnText)
		button:SetPos(btnPosX)
		button:SetTextColor(color_white)
		button:SizeToText()

		button.DoClick = function()
			window.RemoveTime = CurTime()
			btnFunc(window)
		end

		btnPosX = btnPosX + button:GetWide() + 8
		numOptions = numOptions + 1
	end

	local w = math.max(dialogText:GetWide(), btnPosX)
	w = math.max(w, 200)

	local buttonPanelH = 38
	local winH = 36 + dialogText:GetTall() + 12 + buttonPanelH + 12

	window:SetSize(w + 60, winH)
	window:Center()

	buttonPanel:SetSize(window:GetWide() - 16, 38)
	buttonPanel:SetPos(8, window:GetTall() - 42)

	mainContainer:SetSize(window:GetWide(), window:GetTall() - 36)
	mainContainer:SetPos(0, 36)

	window:MakePopup()
	window:DoModal()

	return window
end
