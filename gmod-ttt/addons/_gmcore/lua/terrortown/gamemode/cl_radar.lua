---Extends RADAR table for entity warnings of tripwires, bumpmines,
---deathstations, and whatever we add in the future. Don't forget to add them here!!

CreateClientConVar("ttt_radar_blip_opacity", "240", true, false, "Opacity of radar blips. Must be between 15 - 255", 15, 255)

local surface = surface
local math = math

---@class RADAR
---@field targets table[] Array of {role: number, pos: Vector}
---@field enable boolean Whether a scan is currently active
---@field duration number Seconds a scan lasts (default 30)
---@field endtime number CurTime() when the current scan expires
---@field bombs table<number, {pos: Vector, t: number, ent?: Entity}> C4 warnings keyed by entity index
---@field bombs_count number Number of active C4 bomb warnings
---@field tripwires table<number, {pos: Vector, ent?: Entity}> GL tripwire warnings keyed by entity index
---@field tripwires_count number Number of active tripwire warnings
---@field bumpmines table<number, {pos: Vector, ent?: Entity}> GL bumpmine warnings keyed by entity index
---@field bumpmines_count number Number of active bumpmine warnings
---@field deathstations table<number, {pos: Vector, ent?: Entity}> GL deathstation warnings keyed by entity index
---@field deathstations_count number Number of active deathstation warnings
---@field samples table DNA scanner samples
---@field samples_count number Number of DNA scanner samples collected
---@field repeating boolean Whether radar auto-repeats after timeout
---@field called_corpses table[] Corpse call positions
RADAR = {}
RADAR.targets = {}
RADAR.enable = false
RADAR.duration = 30
RADAR.endtime = 0
RADAR.bombs = {}
RADAR.bombs_count = 0
RADAR.repeating = true
RADAR.samples = {}
RADAR.samples_count = 0

-- GL Custom
RADAR.tripwires = {}
RADAR.tripwires_count = 0
RADAR.bumpmines = {}
RADAR.bumpmines_count = 0
RADAR.deathstations = {}
RADAR.deathstations_count = 0

RADAR.called_corpses = {}

---Ends the current radar scan.
function RADAR:EndScan()
	self.enable = false
	self.endtime = CurTime()
end

---Clears all radar state including bombs, samples and GL custom entities.
function RADAR:Clear()
	self:EndScan()
	self.bombs = {}
	self.samples = {}
	self.tripwires = {}
	self.bumpmines = {}

	self.bombs_count = 0
	self.samples_count = 0
	self.tripwires_count = 0
	self.bumpmines_count = 0
end

---Called when the radar scan duration expires; optionally re-scans if repeating.
function RADAR:Timeout()
	self:EndScan()

	-- Check if radar upgrade was bought or upgraded level during ownership
	if LocalPlayer():PS_HasItemEquipped("upgrade_radar") then
		RADAR.duration = 30 - (4 * LocalPlayer():PS_GetUpgradeLevel("upgrade_radar")) -- Decrease by 4 seconds per level
	end

	if self.repeating and LocalPlayer() and LocalPlayer():IsActiveSpecial() and LocalPlayer():HasEquipmentItem(EQUIP_RADAR) then
			RunConsoleCommand("ttt_radar_scan")
	end
end

---Cache entity positions for bombs, deathstations, and clean up expired corpse calls.
function RADAR.CacheEnts()
	-- also do some corpse cleanup here
	for k, corpse in pairs(RADAR.called_corpses) do
			if (corpse.called + 45) < CurTime() then
				RADAR.called_corpses[k] = nil -- will make # inaccurate, no big deal
			end
	end

	-- Update bomb positions for those we know about
	if RADAR.bombs_count > 0 then
		for idx, b in pairs(RADAR.bombs) do
			local ent = Entity(idx)

			if IsValid(ent) then
				b.pos = ent:GetPos()
			end
		end
	end

	-- Keep updating deathstation positions since they can be moved around
	if RADAR.deathstations_count > 0 then
		for idx, b in pairs(RADAR.deathstations) do
			local ent = Entity(idx)

			if IsValid(ent) then
				b.pos = ent:GetPos()
			end
		end
	end
end

---@param is_item boolean Whether the purchase was an item (not a weapon)
---@param id number Equipment ID constant
function RADAR.Bought(is_item, id)
	if is_item and id == EQUIP_RADAR then
			RunConsoleCommand("ttt_radar_scan")
	end

	if LocalPlayer():PS_HasItemEquipped("upgrade_radar") then
		RADAR.duration = 30 - (4 * LocalPlayer():PS_GetUpgradeLevel("upgrade_radar")) -- Decrease by 4 seconds per level
	end
end
hook.Add("TTTBoughtItem", "RadarBoughtItem", RADAR.Bought)

---@param tgt {pos: Vector, t?: number, nick?: string} Radar target data
---@param size number Icon half-size in pixels
---@param offset number Vertical text offset multiplier
---@param no_shrink? boolean If true, do not halve size when off-screen
local function DrawTarget(tgt, size, offset, no_shrink)
	local scrpos = tgt.pos:ToScreen() -- sweet
	local sz = (IsOffScreen(scrpos) and (not no_shrink)) and size / 2 or size

	scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
	scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)

	if IsOffScreen(scrpos) then return end

	surface.DrawTexturedRect(scrpos.x - sz, scrpos.y - sz, sz * 2, sz * 2)

	-- Drawing full size?
	if sz == size then
			local text = math.ceil(LocalPlayer():GetPos():Distance(tgt.pos))
			local w, h = surface.GetTextSize(text)

			-- Show range to target
			surface.SetTextPos(scrpos.x - w/2, scrpos.y + (offset * sz) - h/2)
			surface.DrawText(text)

			if tgt.t and tgt.t >= 0 then
				-- Show time
				text = util.SimpleTime(tgt.t - CurTime(), "%02i:%02i")
				w, h = surface.GetTextSize(text)

				surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
				surface.DrawText(text)
			elseif tgt.nick then
				-- Show nickname
				text = tgt.nick
				w, h = surface.GetTextSize(text)

				surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
				surface.DrawText(text)
			end
	end
end

---@type number
local indicator   = surface.GetTextureID("effects/select_ring")
---@type number
local c4warn      = surface.GetTextureID("vgui/ttt/icon_c4warn")
---@type number
local sample_scan = surface.GetTextureID("vgui/ttt/sample_scan")
---@type number
local det_beacon  = surface.GetTextureID("vgui/ttt/det_beacon")
---@type number
local tripwirewarn = surface.GetTextureID("vgui/ttt/icon_gl_tripwire")
---@type number
local bumpminewarn = surface.GetTextureID("vgui/ttt/icon_gl_bumpmine")
---@type number
local deathstationwarn = surface.GetTextureID("vgui/ttt/icon_gl_deathstation")

local GetPTranslation = LANG.GetParamTranslation
local FormatTime = util.SimpleTime

local opacityRadarBlipConvar = GetConVar("ttt_radar_blip_opacity")

---@param client Player The local player
function RADAR:Draw(client)
	if not client then return end

	surface.SetFont("HudSelectionText")

	-- C4 warnings
	if self.bombs_count != 0 and client:IsActiveTraitor() then
			surface.SetTexture(c4warn)
			surface.SetTextColor(200, 55, 55, 220)
			surface.SetDrawColor(255, 255, 255, 200)

			for k, bomb in pairs(self.bombs) do
				bomb.ent = ents.GetByIndex(k) -- Send ent index
				DrawTarget(bomb, 24, 0, true)
			end
	end

	if self.tripwires_count != 0 and client:IsActiveTraitor() then
			surface.SetTexture(tripwirewarn)
			surface.SetTextColor(200, 55, 55, 220)
			surface.SetDrawColor(255, 255, 255, 200)

			for k, tripwire in pairs(self.tripwires) do
				tripwire.ent = ents.GetByIndex(k) -- Send ent index
				DrawTarget(tripwire, 24, 0, true)
			end
	end

	if self.bumpmines_count != 0 and client:IsActiveTraitor() then
			surface.SetTexture(bumpminewarn)
			surface.SetTextColor(200, 55, 55, 220)
			surface.SetDrawColor(255, 255, 255, 200)

			for k, bumpmine in pairs(self.bumpmines) do
				bumpmine.ent = ents.GetByIndex(k) -- Send ent index
				DrawTarget(bumpmine, 24, 0, true)
			end
	end

	if self.deathstations_count != 0 and client:IsActiveTraitor() then
			surface.SetTexture(deathstationwarn)
			surface.SetTextColor(200, 55, 55, 220)
			surface.SetDrawColor(255, 255, 255, 200)

			for k, deathstation in pairs(self.deathstations) do
				deathstation.ent = ents.GetByIndex(k) -- Send ent index
				DrawTarget(deathstation, 24, 0, true)
			end
	end

	-- Corpse calls
	if client:IsActiveDetective() and #self.called_corpses then
			surface.SetTexture(det_beacon)
			surface.SetTextColor(255, 255, 255, 240)
			surface.SetDrawColor(255, 255, 255, 230)

			for k, corpse in pairs(self.called_corpses) do
				DrawTarget(corpse, 16, 0.5)
			end
	end

	-- Samples
	if self.samples_count != 0 then
			surface.SetTexture(sample_scan)
			surface.SetTextColor(200, 50, 50, 255)
			surface.SetDrawColor(255, 255, 255, 240)

			for k, sample in pairs(self.samples) do
				DrawTarget(sample, 16, 0.5, true)
			end
	end

	-- Player radar
	if (not self.enable) or (not client:IsActiveSpecial()) then return end

	surface.SetTexture(indicator)

	local remaining = math.max(0, RADAR.endtime - CurTime())
	local alpha = opacityRadarBlipConvar:GetInt()

	local role, scrpos
	for k, tgt in pairs(RADAR.targets) do
			scrpos = tgt.pos:ToScreen()
			if not scrpos.visible then
				continue
			end

			role = tgt.role or ROLE_INNOCENT
			if role == ROLE_TRAITOR then
				surface.SetDrawColor(255, 0, 0, alpha)
				surface.SetTextColor(255, 0, 0, alpha)

			elseif role == ROLE_DETECTIVE then
				surface.SetDrawColor(0, 0, 255, alpha)
				surface.SetTextColor(0, 0, 255, alpha)

			elseif role == 3 then -- decoys
				surface.SetDrawColor(150, 150, 150, alpha)
				surface.SetTextColor(150, 150, 150, alpha)

			else
				surface.SetDrawColor(0, 255, 0, alpha)
				surface.SetTextColor(0, 255, 0, alpha)
			end

			DrawTarget(tgt, 24, 0)
	end

	-- Time until next scan
	surface.SetFont("TabLarge")
	surface.SetTextColor(255, 0, 0, 230)

	local text = GetPTranslation("radar_hud", {time = FormatTime(remaining, "%02i:%02i")})
	local w, h = surface.GetTextSize(text)

	surface.SetTextPos(36, ScrH() - 180 - h)
	surface.DrawText(text)
end

local function ReceiveC4Warn()
	local idx = net.ReadUInt(16)
	local armed = net.ReadBit() == 1

	if armed then
			local pos = net.ReadVector()
			local etime = net.ReadFloat()

			RADAR.bombs[idx] = {pos=pos, t=etime}
	else
			RADAR.bombs[idx] = nil
	end

	RADAR.bombs_count = table.Count(RADAR.bombs)
end
net.Receive("TTT_C4Warn", ReceiveC4Warn)

local function ReceiveTripwireWarn()
	local idx = net.ReadUInt(16)
	local armed = net.ReadBit() == 1

	if armed then
			local pos = net.ReadVector()

			RADAR.tripwires[idx] = {pos=pos}
	else
			RADAR.tripwires[idx] = nil
	end

	RADAR.tripwires_count = table.Count(RADAR.tripwires)
end
net.Receive("TTT_gl_TripwireWarn", ReceiveTripwireWarn)

local function ReceiveBumpmineWarn()
	local idx = net.ReadUInt(16)
	local armed = net.ReadBit() == 1

	if armed then
			local pos = net.ReadVector()

			RADAR.bumpmines[idx] = {pos=pos}
	else
			RADAR.bumpmines[idx] = nil
	end

	RADAR.bumpmines_count = table.Count(RADAR.bumpmines)
end
net.Receive("TTT_gl_BumpmineWarn", ReceiveBumpmineWarn)

local function DeathstationWarn()
	local idx = net.ReadUInt(16)
	local armed = net.ReadBit() == 1

	if armed then
			local pos = net.ReadVector()

			RADAR.deathstations[idx] = {pos=pos}
	else
			RADAR.deathstations[idx] = nil
	end

	RADAR.deathstations_count = table.Count(RADAR.deathstations)
end
net.Receive("TTT_gl_DeathstationWarn", DeathstationWarn)

local function ReceiveCorpseCall()
	local pos = net.ReadVector()
	table.insert(RADAR.called_corpses, {pos = pos, called = CurTime()})
end
net.Receive("TTT_CorpseCall", ReceiveCorpseCall)

local function ReceiveRadarScan()
	local num_targets = net.ReadUInt(8)

	RADAR.targets = {}
	for i=1, num_targets do
			local r = net.ReadUInt(2)

			local pos = Vector()
			pos.x = net.ReadInt(15)
			pos.y = net.ReadInt(15)
			pos.z = net.ReadInt(15)

			table.insert(RADAR.targets, {role=r, pos=pos})
	end

	RADAR.enable = true
	RADAR.endtime = CurTime() + RADAR.duration

	timer.Create("radartimeout", RADAR.duration + 1, 1,
								function() RADAR:Timeout() end)
end
net.Receive("TTT_Radar", ReceiveRadarScan)

local GetTranslation = LANG.GetTranslation
---@param parent Panel Parent VGUI panel for the radar menu
---@param frame DFrame The equipment frame (closed on scan)
---@return DForm dform The created form panel
function RADAR.CreateMenu(parent, frame)
	local w, h = parent:GetSize()

	local dform = vgui.Create("DForm", parent)
	dform:SetName(GetTranslation("radar_menutitle"))
	dform:StretchToParent(0,0,0,0)
	dform:SetAutoSize(false)

	local owned = LocalPlayer():HasEquipmentItem(EQUIP_RADAR)

	if not owned then
			dform:Help(GetTranslation("radar_not_owned"))

			return dform
	end

	local bw, bh = 100, 25
	local dscan = vgui.Create("DButton", dform)
	dscan:SetSize(bw, bh)
	dscan:SetText(GetTranslation("radar_scan"))
	dscan.DoClick = function(s)
											s:SetEnabled(false)
											RunConsoleCommand("ttt_radar_scan")
											frame:Close()
									end
	dform:AddItem(dscan)

	local dlabel = vgui.Create("DLabel", dform)
	dlabel:SetText(GetPTranslation("radar_help", {num = RADAR.duration}))
	dlabel:SetWrap(true)
	dlabel:SetTall(50)
	dform:AddItem(dlabel)

	local dcheck = vgui.Create("DCheckBoxLabel", dform)
	dcheck:SetText(GetTranslation("radar_auto"))
	dcheck:SetIndent(5)
	dcheck:SetValue(RADAR.repeating)
	dcheck.OnChange = function(s, val)
												RADAR.repeating = val
										end
	dform:AddItem(dcheck)

	dform:NumSlider("Opacity of radar blips", "ttt_radar_blip_opacity", 15, 255, 0)

	dform.Think = function(s)
										if RADAR.enable or not owned then
											dscan:SetEnabled(false)
										else
											dscan:SetEnabled(true)
										end
								end

	dform:SetVisible(true)

	return dform
end
