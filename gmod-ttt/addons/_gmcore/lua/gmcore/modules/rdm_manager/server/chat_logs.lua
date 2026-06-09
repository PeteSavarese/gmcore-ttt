util.AddNetworkString("DL_AskChatLogs")
util.AddNetworkString("DL_SendChatLogs")

---Chat logs for the current map
---Key/index is round number, value is subtable of all chats entries
---@type table<number, table<number, any>[]>
Damagelog.ChatLogs = {}

function Damagelog:LogChatMessage(ply, sText, msgType)
	if sText == nil or sText == "" then return end
	if !IsValid(ply) then return end
	if msgType ~= "last_words" and !ply:Alive() then return end
	if msgType ~= "last_words" and ply:IsSpec() then return end

	if !self.ChatLogs[self.CurrentRound] or self.ChatLogs[self.CurrentRound] == nil then
		self.ChatLogs[self.CurrentRound] = {}
	end

	-- Override bIsTeam if the player was innocent
	if ply:GetRole() == ROLE_INNOCENT and msgType == "team" then
		msgType = ""
	end

	self.ChatLogs[self.CurrentRound][#self.ChatLogs[self.CurrentRound] + 1] = {ply:Nick(), ply:SteamID(), ply:GetRole(), self.Time, msgType, sText}
end

function Damagelog:FetchChatLogs(ply, iRound)
	if !self.ChatLogs[iRound] then return end
	if !IsValid(ply) then return end
	if !ply:CanUseRDMManager() then return end

	net.Start("DL_SendChatLogs")
	net.WriteTable(self.ChatLogs[iRound])
	net.Send(ply)
end

hook.Add("PlayerSay", "gmcore.Damagelogs.ChatMessageLog", function(ply, sText, bIsTeam)
	if GAMEMODE.round_state ~= ROUND_ACTIVE then return end

	Damagelog:LogChatMessage(ply, sText, bIsTeam and "team" or "")
end)

hook.Add("TTTLastWordsMsg", "gmcore.Damagelogs.ChatMessageLogLastWords", function(ply, lastWords)
	if GAMEMODE.round_state ~= ROUND_ACTIVE then return end

	Damagelog:LogChatMessage(ply, lastWords, "last_words")
end)

net.Receive("DL_AskChatLogs", function(_, ply)
	Damagelog:FetchChatLogs(ply, net.ReadInt(8))
end)
