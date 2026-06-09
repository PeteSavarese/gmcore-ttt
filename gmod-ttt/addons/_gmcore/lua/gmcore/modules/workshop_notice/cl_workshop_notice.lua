---Client-side Linux workshop notice dialog.
gmcore.WorkshopNotice = gmcore.WorkshopNotice or {}

if not gmcore.WorkshopNotice.Enabled then return end

---@return boolean seen True if ply has previously dismissed the workshop notice
local function hasSeenNotice()
	local cookieKey = gmcore.WorkshopNotice.CookieKey or "gmcore_workshop_notice_hide"

	return cookie.GetNumber(cookieKey, 0) == 1
end

---Displays workshop notice dialog if not previously dismissed.
local function showWorkshopNotice()
	if hasSeenNotice() then return end

	local frame = vgui.Create("GmcoreFrame")
	frame:SetTitle(gmcore.WorkshopNotice.Vgui.Title or "Workshop Notice")
	frame:SetSize(560, 240)
	frame:SetBackgroundBlur(true)
	frame:SetScreenLock(true)
	frame:Center()
	frame:MakePopup()

	local body = vgui.Create("DLabel", frame)
	body:SetFont("gmcore.Derma.DialogText")
	body:SetText(gmcore.WorkshopNotice.Vgui.Body or "")
	body:SetTextColor(CARD_TEXT_SECONDARY_COLOR)
	body:SetWrap(true)
	body:SetAutoStretchVertical(true)
	body:SetPos(20, 70)
	body:SetSize(frame:GetWide() - 40, 90)

	local checkbox = vgui.Create("GmcoreCheckBoxLabel", frame)
	checkbox:SetText(gmcore.WorkshopNotice.Vgui.CheckboxText or "Don't show this again")
	checkbox:SetPos(20, frame:GetTall() - 70)
	checkbox.lblText:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)

	local btnOpen = vgui.Create("GmcoreButton", frame)
	btnOpen:SetText(gmcore.WorkshopNotice.Vgui.ButtonOpenText or "Learn More")
	btnOpen:SetBackgroundColor(BUTTON_ACCENT_COLOR)
	btnOpen:SizeToText()

	local btnClose = vgui.Create("GmcoreButton", frame)
	btnClose:SetText(gmcore.WorkshopNotice.Vgui.ButtonCloseText or "Dismiss")
	btnClose:SetBackgroundColor(BUTTON_ACCENT_COLOR)
	btnClose:SizeToText()

	local buttonY = frame:GetTall() - btnOpen:GetTall() - 15
	btnOpen:SetPos(frame:GetWide() - btnOpen:GetWide() - 20, buttonY)
	btnClose:SetPos(btnOpen:GetX() - btnClose:GetWide() - 10, buttonY)

	btnOpen.DoClick = function()
		if gmcore.WorkshopNotice.Url and gmcore.WorkshopNotice.Url ~= "" then
			if steamworks and steamworks.OpenURL then
				steamworks.OpenURL(gmcore.WorkshopNotice.Url)
			else
				gui.OpenURL(gmcore.WorkshopNotice.Url)
			end
		end
	end

	btnClose.DoClick = function()
		if checkbox:GetChecked() then
			local cookieKey = gmcore.WorkshopNotice.CookieKey or "gmcore_workshop_notice_hide"
			cookie.Set(cookieKey, "1")
		end

		frame:Close()
	end
end

hook.Add("InitPostEntity", "gmcore.WorkshopNotice.InitPostEntity", function()
	if not system.IsLinux() then return end
	if MENU_DLL then return end

	timer.Simple(5, showWorkshopNotice)
end)

concommand.Add("gmcore_workshop_notice_show", showWorkshopNotice, nil, "Show Linux workshop notice dialog")
