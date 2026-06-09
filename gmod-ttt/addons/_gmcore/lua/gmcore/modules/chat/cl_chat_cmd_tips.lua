---Display ULX cmds as suggestions based on current text in chat.

---@type boolean
local inChat = false

hook.Add("StartChat", "gmcore.Chat.AutoCompleteCmds", function()
	inChat = true
end)

hook.Add("FinishChat", "gmcore.Chat.AutoCompleteCmds", function()
	inChat = false
end)

---@type ConVar
local shouldDraw = CreateClientConVar("gmcore_chat_cmd_tips", "1", true, false)
---@type {ChatCommand: string, Usage: string, Help: string}[]
local ulxSuggestions = {}

hook.Add("HUDPaint", "gmcore.Chat.DrawChatCmdTips", function()
	if shouldDraw:GetBool() and inChat then
		local x, y = chat.GetChatBoxPos()
		x = x + ScrW() * 0.037
		y = y + ScrH() / 4 + 5

		local font = "ChatFont"
		surface.SetFont(font)

		for _, v in ipairs(ulxSuggestions) do
			local x1, y1 = surface.GetTextSize(v.ChatCommand)
			local x2, _ = surface.GetTextSize(v.Usage)
			draw.SimpleTextOutlined(v.ChatCommand, font, x, y, Color(255, 255, 100, 255), _, _, 0.5, Color(0, 0, 0, 255))
			draw.SimpleTextOutlined(" " .. v.Usage .. " ", font, x + x1, y, Color(255, 255, 255, 255), _, _, 0.5, Color(0, 0, 0, 255))
			draw.SimpleTextOutlined(" - " .. v.Help .. " ", font, x + x1 + x2, y, Color(255, 255, 255, 255), _, _, 0.5, Color(0, 0, 0, 255))
			y = y + y1
		end
	end
end)

---@type ConVar
local suggestionLimit = CreateClientConVar("gmcore_chat_cmd_tips_limit", "4", true, false, "Maximum amount of tips that will be shown below chat", 1, 4)

hook.Add("ChatTextChanged", "gmcore.Chat.AutoCompleteCmds", function(str)
	ulxSuggestions = {}
	local com = string.sub(str, 1, (string.find(str, " ") or (#str + 1)) - 1)

	if #com >= 1 and (string.sub(com, 0, 1) ~= "!" or #com >= 2) then
		local ply = LocalPlayer()

		for category, cmds in pairs(ulx.cmdsByCategory) do
			for _, cmd in ipairs(cmds) do
				local tag = cmd.cmd

				if cmd.manual then
					tag = cmd.access_tag
				end

				local str = cmd:superClass().getUsage(cmd, ply)

				if ULib.ucl.query(ply, tag) and istable(cmd.say_cmd) then
					for k, ccmd in pairs(cmd.say_cmd) do
						if string.sub(ccmd, 0, #com) == string.lower(com) and #ulxSuggestions < suggestionLimit:GetInt() then
							local suggestion = {}
							suggestion.ChatCommand = ccmd
							suggestion.Usage = str:Trim() or ""
							suggestion.Help = cmd.helpStr or ""

							table.insert(ulxSuggestions, suggestion)
						end
					end
				end
			end
		end

		table.SortByMember(ulxSuggestions, "ChatCommand", function(a, b) return a < b end)
	end
end)
