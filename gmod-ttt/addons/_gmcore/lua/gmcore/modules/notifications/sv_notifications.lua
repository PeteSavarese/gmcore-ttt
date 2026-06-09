util.AddNetworkString("gmcore.Notifications.SendNotification")

---Send a notification to a player.
---@param ply Player Player to send notification to
---@param msg string Notification message text
---@param notifyType GLNotifyKind Notification kind (see `gmcore.NotifyType`)
---@param length number Display duration in seconds
---@param sound? string Optional sound path to play on the client (e.g. `"buttons/button15.wav"`).
function gmcore.NotifyPly(ply, msg, notifyType, length, sound)
	if not IsValid(ply) then return end

	net.Start("gmcore.Notifications.SendNotification")
	net.WriteString(msg or "")
	net.WriteString(tostring(notifyType))
	net.WriteFloat(tonumber(length) or 5)
	net.WriteString(sound or "")
	net.Send(ply)
end

---Broadcast a notification to all players.
---@param msg string Notification message text
---@param notifyType GLNotifyKind Notification kind (see `gmcore.NotifyType`)
---@param length number Display duration in seconds
---@param sound? string Optional sound path to play on the client.
function gmcore.NotifyAll(msg, notifyType, length, sound)
	net.Start("gmcore.Notifications.SendNotification")
	net.WriteString(msg or "")
	net.WriteString(tostring(notifyType))
	net.WriteFloat(tonumber(length) or 5)
	net.WriteString(sound or "")
	net.Broadcast()
end
