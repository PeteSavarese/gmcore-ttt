---@type table[]
local radar_targets = {}
---@type number
local indicator = surface.GetTextureID("effects/select_ring")

---Draws a single radar target on screen.
---@param tgt table Radar target with position data
---@param size number Base size of the radar indicator in pixels
---@param offset number Vertical offset multiplier for the distance text
---@param no_shrink? boolean
local function DrawTarget(tgt, size, offset, no_shrink)
	local scrpos = tgt.pos:ToScreen() -- sweet
	local sz = (IsOffScreen(scrpos) and (not no_shrink)) and size / 2 or size
	scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
	scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)
	surface.DrawTexturedRect(scrpos.x - sz, scrpos.y - sz, sz * 2, sz * 2)

	-- Drawing full size?
	if sz == size then
		local text = math.ceil(LocalPlayer():GetPos():Distance(tgt.pos))
		local w, h = surface.GetTextSize(text)
		-- Show range to target
		surface.SetTextPos(scrpos.x - w / 2, scrpos.y + (offset * sz) - h / 2)
		surface.DrawText(text)
	end
end

---Draws all current radar targets.
function gmcore.FunRounds:DrawRadarTargets()
	local ply = LocalPlayer()
	if ply:IsActive() and #radar_targets > 0 then
		local alpha = 200
		local near_cursor_dist = 180
		local mpos = Vector(ScrW() / 2, ScrH() / 2, 0)
		surface.SetTexture(indicator)
		surface.SetFont("HudSelectionText")

		for k, tgt in pairs(radar_targets) do
			scrpos = tgt.pos:ToScreen()
			md = mpos:Distance(Vector(scrpos.x, scrpos.y, 0))

			if md < near_cursor_dist then
				alpha = math.Clamp(alpha * (md / near_cursor_dist), 40, 230)
			end

			surface.SetDrawColor(0, 153, 255, alpha)
			surface.SetTextColor(0, 153, 255, alpha)
			DrawTarget(tgt, 24, 0)
		end
	end
end

net.Receive("gmcore.FunRounds.SendRadarTargets", function(len)
	local ply = LocalPlayer()

	if IsValid(ply) and ply:IsActive() then
		local num_targets = net.ReadInt(8)
		local targets = {}

		for i = 1, num_targets do
			local pos = Vector()
			pos.x = net.ReadInt(32)
			pos.y = net.ReadInt(32)
			pos.z = net.ReadInt(32)

			table.insert(targets, {
				pos = pos
			})
		end

		radar_targets = targets
	end
end)
