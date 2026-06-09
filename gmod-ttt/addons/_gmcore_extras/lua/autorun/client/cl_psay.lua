local allowedRanks = {
	["admin"] = true,
	["leadadmin"] = true,
	["developer"] = true,
	["communitymanager"] = true,
	["owner"] = true,
}

function openPsayMenu(ply, cmd, args, str)
	local disconnectTable = {}
	if !allowedRanks[ply:GetUserGroup()] then return end

	net.Start("gmcore.RequestPSays")
	net.SendToServer()

	local main = vgui.Create("DFrame")
	main:SetPos(50, 50)
	main:SetSize(800, 700)
	main:SetTitle("Private Messages This Map")
	main:SetVisible(true)
	main:SetDraggable(true)
	main:MakePopup()
	main:Center()

	local list = vgui.Create("DListView")
	list:SetParent(main)
	list:SetPos(4, 27)
	list:SetSize(792, 669)
	list:SetMultiSelect(false)
	list:AddColumn("From")
	list:AddColumn("From SteamID")
	list:AddColumn("To")
	list:AddColumn("Message")
	list:AddColumn("Time")

	list.OnRowRightClick = function(main, line)
		local menu = DermaMenu()

		if allowedRanks[ply:GetUserGroup()] then
		menu:AddOption("Ban by SteamID", function()
			local Frame = vgui.Create("DFrame")
			Frame:SetSize(250, 98)
			Frame:Center()
			Frame:MakePopup()
			Frame:SetTitle("Ban by SteamID...")
			local TimeLabel = vgui.Create("DLabel", Frame)
			TimeLabel:SetPos(5, 27)
			TimeLabel:SetColor(Color(0, 0, 0, 255))
			TimeLabel:SetFont("DermaDefault")
			TimeLabel:SetText("Time:")
			local Time = vgui.Create("DTextEntry", Frame)
			Time:SetPos(47, 27)
			Time:SetSize(198, 20)
			Time:SetDisabled(false)
			Time:SetText("")
			local ReasonLabel = vgui.Create("DLabel", Frame)
			ReasonLabel:SetPos(5, 50)
			ReasonLabel:SetColor(Color(0, 0, 0, 255))
			ReasonLabel:SetFont("DermaDefault")
			ReasonLabel:SetText("Reason:")
			local Reason = vgui.Create("DTextEntry", Frame)
			Reason:SetPos(47, 50)
			Reason:SetSize(198, 20)
			Reason:SetText("")
			local execbutton = vgui.Create("DButton", Frame)
			execbutton:SetSize(75, 20)
			execbutton:SetPos(47, 73)
			execbutton:SetText("Ban!")

			execbutton.DoClick = function()
				RunConsoleCommand("ulx", "banid", tostring(list:GetLine(line):GetValue(2)), Time:GetText(), Reason:GetText())
				Frame:Close()
			end

			local cancelbutton = vgui.Create("DButton", Frame)
			cancelbutton:SetSize(75, 20)
			cancelbutton:SetPos(127, 73)
			cancelbutton:SetText("Cancel")

			cancelbutton.DoClick = function(cancelbutton)
				Frame:Close()
			end
		end):SetIcon("icon16/tag_blue_delete.png")

		menu:AddOption("Ban by IP Address", function()
			local Frame = vgui.Create("DFrame")
			Frame:SetSize(250, 98)
			Frame:Center()
			Frame:MakePopup()
			Frame:SetTitle("Ban by IP Address...")
			local TimeLabel = vgui.Create("DLabel", Frame)
			TimeLabel:SetPos(5, 27)
			TimeLabel:SetColor(Color(0, 0, 0, 255))
			TimeLabel:SetFont("DermaDefault")
			TimeLabel:SetText("Time:")
			local Time = vgui.Create("DTextEntry", Frame)
			Time:SetPos(47, 27)
			Time:SetSize(198, 20)
			Time:SetText("")
			local ReasonLabel = vgui.Create("DLabel", Frame)
			ReasonLabel:SetPos(5, 50)
			ReasonLabel:SetColor(Color(0, 0, 0, 255))
			ReasonLabel:SetFont("DermaDefault")
			ReasonLabel:SetText("Reason:")
			local Reason = vgui.Create("DTextEntry", Frame)
			Reason:SetPos(47, 50)
			Reason:SetSize(198, 20)
			Reason:SetText("No reason required")
			Reason:SetDisabled(true)
			local execbutton = vgui.Create("DButton", Frame)
			execbutton:SetSize(75, 20)
			execbutton:SetPos(47, 73)
			execbutton:SetText("Ban!")

			execbutton.DoClick = function()
				RunConsoleCommand("ulx", "banip", Time:GetText(), (list:GetLine(line):GetValue(3)))
				Frame:Close()
			end

			local cancelbutton = vgui.Create("DButton", Frame)
			cancelbutton:SetSize(75, 20)
			cancelbutton:SetPos(127, 73)
			cancelbutton:SetText("Cancel")

			cancelbutton.DoClick = function(cancelbutton)
				Frame:Close()
			end
		end):SetIcon("icon16/vcard_delete.png")
	end

		menu:AddOption("Copy Sender Name", function()
			SetClipboardText(disconnectTable[line]["fromNick"])
		end):SetIcon("icon16/user_edit.png")

		menu:AddOption("Copy Sender SteamID", function()
			SetClipboardText(disconnectTable[line]["fromSteamID"])
		end):SetIcon("icon16/tag_blue_edit.png")

		menu:AddOption("Copy Time", function()
			SetClipboardText(disconnectTable[line]["ostime"])
		end):SetIcon("icon16/time.png")

		menu:AddOption("Fetch Sender Player History", function()
			gui.OpenURL(GetGlobalString("gmcore.ForumsBaseUrl", "") .. "/gmcore/hlogs/results?steamid=" .. disconnectTable[line]["fromSteamID"])
		end):SetIcon("icon16/application_view_list.png")

		menu:AddOption("Full Display", function()
			Derma_Message(list:GetLine(line):GetValue(1) .. " to " .. list:GetLine(line):GetValue(3) .. ": " .. list:GetLine(line):GetValue(4), "Full display", "Close")
		end):SetIcon("icon16/eye.png")

		menu:Open()
	end

	net.Receive("gmcore.RequestPSays", function()
		disconnectTable = net.ReadTable()

		for k, v in pairs(disconnectTable) do
			list:AddLine(v["fromNick"], v["fromSteamID"], v["toNick"], v["message"], tostring(os.date("%H:%M"), v["ostime"]))


			list:SortByColumn(5, true)
			main:ShowCloseButton(true)
		end
	end)
end

concommand.Add("menu_psays", openPsayMenu)
