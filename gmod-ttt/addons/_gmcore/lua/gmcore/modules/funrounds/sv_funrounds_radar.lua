util.AddNetworkString("gmcore.FunRounds.SendRadarTargets")

---@type number
local chargetime = 3
local math = math

---Handles the fun round radar scan command for a player.
---@param ply Player Player who executed the radar scan
---@param cmd string Console command name
---@param args string[] Additional command arguments
local function DoFrRadar(ply, cmd, args)
	if IsValid(ply) and ply:IsTerror() and gmcore.FunRounds.ActiveRound then
		local tFunRound = gmcore.FunRounds.RegisteredFunRounds and gmcore.FunRounds.RegisteredFunRounds[gmcore.FunRounds.ChosenFunRound] or nil

		ply.radar_charge = CurTime() + chargetime
		local scan_ents = player.GetAll()
		table.Add(scan_ents, ents.FindByClass("ttt_decoy"))
		local targets = {}

		for k, p in pairs(scan_ents) do
			if ply == p or (!IsValid(p)) then continue end
			if gmcore.FunRounds.ChosenFunRound == "Infected" and p:IsPlayer() and p:IsTerror() and p:IsTraitor() then continue end
			if tFunRound and isfunction(tFunRound.RadarShouldIncludeTarget) and !tFunRound:RadarShouldIncludeTarget(ply, p) then continue end

			if p:IsPlayer() then
				if !p:IsTerror() then continue end
				if p:GetNWBool("disguised", false) and (!ply:IsTraitor()) then continue end
			end

			local pos = p:LocalToWorld(p:OBBCenter())
			-- Round off, easier to send and inaccuracy does not matter
			pos.x = math.Round(pos.x)
			pos.y = math.Round(pos.y)
			pos.z = math.Round(pos.z)
			local role = p:IsPlayer() and p:GetRole() or -1

			if !p:IsPlayer() then
				-- Decoys appear as innocents for non-traitors
				if !ply:IsTraitor() then
					role = ROLE_INNOCENT
				end
			elseif role ~= ROLE_INNOCENT and role ~= ply:GetRole() then
				-- Detectives/Traitors can see who has their role, but not who
				-- has the opposite role.
				role = ROLE_INNOCENT
			end

			table.insert(targets, {
				role = role,
				pos = pos
			})
		end

		net.Start("gmcore.FunRounds.SendRadarTargets")
		net.WriteUInt(#targets, 8)

		for k, tgt in pairs(targets) do
			net.WriteInt(tgt.pos.x, 32)
			net.WriteInt(tgt.pos.y, 32)
			net.WriteInt(tgt.pos.z, 32)
		end

		net.Send(ply)
	end
end

concommand.Add("gmcore_funrounds_radar_scan", DoFrRadar)
