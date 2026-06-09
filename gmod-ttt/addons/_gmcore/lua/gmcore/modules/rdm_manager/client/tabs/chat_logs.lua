function Damagelog:DrawChatLogs()
	self.CurLoadedChatLogs = {}

	self.ChatsPanel = vgui.Create("DPanelList")
	self.ChatsPanel:SetSpacing(10)

	self.LoadLogsBtn = vgui.Create("DButton")
	self.LoadLogsBtn:SetText("Load chat logs for selected round")

	self.LoadLogsBtn.DoClick = function()
	if !tonumber(self.SelectedRound) then return end
	self.CurLoadedChatLogs = {}

	self.ReceivingChatLogs = true

	self.ChatLogsList:Clear()
	self.ChatLogsList:AddLine("", "", "Loading...")

	net.Start("DL_AskChatLogs")
	net.WriteUInt(self.SelectedRound, 8)
	net.SendToServer()
	end

	self.ChatsPanel:AddItem(self.LoadLogsBtn)

	self.ChatLogsList = vgui.Create("DListView")
	self.ChatLogsList:SetHeight(575)
	self.ChatLogsList:AddColumn("Time"):SetFixedWidth(50)
	self.ChatLogsList:AddColumn("Player"):SetFixedWidth(100)
	self.ChatLogsList:AddColumn("Message")
	self.ChatsPanel:AddItem(self.ChatLogsList)

	self.Tabs:AddSheet("Chat Logs", self.ChatsPanel, "icon16/comments.png", false, false)
end

function Damagelog:PopulateChatLogsList(listViewElement, tChatLogs)
	self.ChatLogsList:Clear()

	for _, tChat in ipairs(tChatLogs) do
	local prefixTypeStr = "" -- Prefix in brackets if team msg, last words, etc.

	if tChat[5] == "team" then
		prefixTypeStr = "(TEAM) "
	elseif tChat[5] == "last_words" then
		prefixTypeStr = "(LAST WORDS) "
	end

	self.ChatLogsList:AddLine(string.FormattedTime(tChat[4], "%02i:%02i"), tChat[1], prefixTypeStr .. tChat[6])
	end
end

net.Receive("DL_SendChatLogs", function()
	if !Damagelog.ReceivingChatLogs then return end
	local tChatLogs = net.ReadTable()

	Damagelog.ChatLogsList:Clear()
	Damagelog:PopulateChatLogsList(Damagelog.ChatLogsList, tChatLogs)
end)