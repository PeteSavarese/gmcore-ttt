local sDividerEquals = "======"

hook.Add("TTTBeginRound", "gmcore.Modules.Chat.ChatRoundAlert", function()
	local iRoundNum =  math.Clamp(GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) + 1, 1, GetConVar("ttt_round_limit"):GetInt())

	chat.AddText(CHAT_PRINT_BLUE, sDividerEquals, color_white, " Begin Round " .. iRoundNum .. " ", CHAT_PRINT_BLUE, sDividerEquals)
end)
