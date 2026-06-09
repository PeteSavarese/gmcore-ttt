local Player = FindMetaTable("Player")
DAMAGELOG_NOTIFY_ALERT = 1
DAMAGELOG_NOTIFY_INFO = 2

if SERVER then
	util.AddNetworkString("DL_Notify")

	---@param msg_type number DAMAGELOG_NOTIFY_ALERT or DAMAGELOG_NOTIFY_INFO
	---@param msg string Notification message text to display
	---@param _time number Duration in seconds
	---@param sound? string Sound file to play
	function Player:Damagelog_Notify(msg_type, msg, _time, sound)
		net.Start("DL_Notify")
		net.WriteUInt(msg_type, 4)
		net.WriteString(msg)
		net.WriteUInt(_time, 4)
		net.WriteUInt(sound and 1 or 0, 1)

		if sound then
			net.WriteString(sound)
		end

		net.Send(self)
	end
else
	Damagelog.Notifications = Damagelog.Notifications or {}

	local THEME_BG = CARD_BACKGROUND_COLOR or FRAME_BACKGROUND_COLOR or Color(41, 43, 51)
	local THEME_BORDER = FRAME_HEADER_COLOR or Color(33, 33, 33)
	local THEME_ICON = FRAME_HEADER_BLUE_COLOR or primaryAccentColor or Color(0, 103, 196)
	local THEME_TEXT = Color(255, 255, 255, 255)
	local THEME_INNER = CARD_BACKGROUND_COLOR and Color(math.max(THEME_BG.r - 10, 0), math.max(THEME_BG.g - 10, 0), math.max(THEME_BG.b - 10, 0), 255) or Color(150, 150, 150, 255)

	local icons = {
		[DAMAGELOG_NOTIFY_ALERT] = Material("icon16/exclamation.png"),
		[DAMAGELOG_NOTIFY_INFO] = Material("icon16/information.png")
	}

	---@param msg_type number DAMAGELOG_NOTIFY_ALERT or DAMAGELOG_NOTIFY_INFO
	---@param msg string Notification message text to display
	---@param _time number Duration in seconds
	---@param soundFile? string
	function Damagelog:Notify(msg_type, msg, _time, soundFile)
		if soundFile ~= '' and GetConVar("ttt_dmglogs_enablesound"):GetBool() then
			if GetConVar("ttt_dmglogs_enablesoundoutside"):GetBool() then
				sound.PlayFile("sound/" .. soundFile, "", function() end)
			else
				surface.PlaySound(soundFile)
			end
		end

		table.insert(Damagelog.Notifications, {
			text = msg,
			icon = icons[msg_type] or icons[DAMAGELOG_NOTIFY_ALERT],
			_time = _time,
			start = UnPredictedCurTime()
		})
	end

	net.Receive("DL_Notify", function()
		Damagelog:Notify(net.ReadUInt(4), net.ReadString(), net.ReadUInt(4), (net.ReadUInt(1) == 1) and net.ReadString() or false)
	end)

	local function DrawNotif(x, y, w, h, text, icon)
	local b = 2

	draw.RoundedBox(0, x, y, w, h, THEME_BORDER)
	draw.RoundedBox(0, x + b, y + b, w - b * 2, h - b * 2, THEME_INNER)

	-- flashing red border
	local red = 75 + (175 * math.abs(math.sin(UnPredictedCurTime() * 2)))
	surface.SetDrawColor(math.min(math.floor(red), 255), 75, 75, 255)
	surface.DrawOutlinedRect(x, y, w, h)

	x = x + 10
	y = y + h / 2 - 8

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(icon)
	surface.DrawTexturedRect(x, y, 16, 16)
	x = x + 26
	surface.SetTextColor(THEME_TEXT)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
	end

	hook.Add("HUDPaint", "RDM_Manager", function()
		local notifications = Damagelog.Notifications

		if #notifications > 0 then
			local curtime = UnPredictedCurTime()
			surface.SetFont("CenterPrintText")

			for k, v in pairs(notifications) do
				local w, h = surface.GetTextSize(v.text)
				w = w + 50
				h = h + 8
				local tx = ScrW() - w
				local ty = ScrH() * 0.2 + (h + 5) * k

				if v.rollBack then
					tx = tx + (((1 - math.max(v.start + 1 - curtime, 0)) ^ 2) * tx)
					DrawNotif(tx, ty, w, h, v.text, v.icon)

					if v.start + 1 <= curtime then
						table.remove(notifications, k)
					end
				else
					tx = tx + ((math.max(v.start + 1 - curtime, 0) ^ 2) * tx)
					DrawNotif(tx, ty, w, h, v.text, v.icon)

					if v.start + v._time <= curtime then
						v.rollBack = true
						v.start = curtime
					end
				end
			end
		end
	end)
end
