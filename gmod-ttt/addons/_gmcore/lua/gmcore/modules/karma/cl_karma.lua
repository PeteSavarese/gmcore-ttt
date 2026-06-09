net.Receive("gmcore.Karma.SendChatMessage", function()
	local msg_contents = net.ReadString()

	chat.AddText(msg_contents)
end)
