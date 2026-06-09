---Clientside hit marker rendering.

local scrW, scrH = ScrW() / 2, ScrH() / 2
---@type number
local hitLineAlpha = 0

---Creates HUD paint hook for drawing hit marker
local function createHitMarkerHook()
	hook.Add("HUDPaint", "gmcore.Misc.HitMarkers", function()
		surface.SetDrawColor(255, 255, 255, hitLineAlpha)
		surface.DrawLine(scrW - 2, scrH - 2, scrW - 8, scrH - 8)
		surface.DrawLine(scrW + 2, scrH - 2, scrW + 8, scrH - 8)
		surface.DrawLine(scrW + 2, scrH + 2, scrW + 8, scrH + 8)
		surface.DrawLine(scrW - 2, scrH + 2, scrW - 8, scrH + 8)
	end)
end

net.Receive("gmcore.HitMarkers.SendHitConfirm", function()
	hitLineAlpha = 150
	createHitMarkerHook()

	timer.Simple(0.2, function()
		hook.Add("Think", "gmcore.Misc.HitMarkers.Fade", function()
			hitLineAlpha = hitLineAlpha - 5

			if hitLineAlpha <= 0 then
				hook.Remove("Think", "gmcore.Misc.HitMarkers.Fade")
				hook.Remove("HUDPaint", "gmcore.Misc.HitMarkers")
			end
		end)
	end)
end)
