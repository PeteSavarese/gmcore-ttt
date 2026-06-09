---Overrides TTT SelectRoles to exclude players with pending autoslays from role selection.
---Keeps the roles balanced if a player is slain, T or D isn't down a player
hook.Add("Initialize", "gmcore.PointshopRoles.OverrideGamemodeSelectRoles", function()
	---@param ply_count number Total number of eligible players
	---@return number count Number of traitors for the given player count
	local function GetTraitorCount(ply_count)
		local traitor_count = math.floor(ply_count * GetConVar("ttt_traitor_pct"):GetFloat())
		traitor_count = math.Clamp(traitor_count, 1, GetConVar("ttt_traitor_max"):GetInt())

		return traitor_count
	end

	---@param ply_count number Total number of eligible players for detective for given round.
	---@return number count Number of detectives for the given player count
	local function GetDetectiveCount(ply_count)
		if ply_count < GetConVar("ttt_detective_min_players"):GetInt() then return 0 end
		local det_count = math.floor(ply_count * GetConVar("ttt_detective_pct"):GetFloat())
		det_count = math.Clamp(det_count, 1, GetConVar("ttt_detective_max"):GetInt())

		return det_count
	end

	function SelectRoles()
		local choices = {}

		local prev_roles = {
			[ROLE_INNOCENT] = {},
			[ROLE_TRAITOR] = {},
			[ROLE_DETECTIVE] = {}
		}

		if not GAMEMODE.LastRole then
			GAMEMODE.LastRole = {}
		end

		local plys = player.GetAll()

		for k, v in ipairs(plys) do
			if IsValid(v) and (not v:IsSpec()) and not (v.AutoslaysLeft and tonumber(v.AutoslaysLeft) > 0) and not hook.Run("SelectRolesExclude", v) then
				-- TODO: Replace UniqueID with SteamID64 when TTT is updated to use SteamID64
				local r = GAMEMODE.LastRole[v:UniqueID()] or v:GetRole() or ROLE_INNOCENT
				table.insert(prev_roles[r], v)
				table.insert(choices, v)
			end

			v:SetRole(ROLE_INNOCENT)
		end

		local choice_count = #choices
		local traitor_count = GetTraitorCount(choice_count)
		local det_count = GetDetectiveCount(choice_count)
		if choice_count == 0 then return end
		local ts = 0
		local runs = 0 -- safety net just incase loop doesnt end

		while ts < traitor_count and #choices >= 1 and runs < 99 do
			local pick = math.random(1, #choices)
			local pply = choices[pick]

			if IsValid(pply) and hook.Run("SelectRolesSelected", v, ROLE_TRAITOR) ~= false and ((not table.HasValue(prev_roles[ROLE_TRAITOR], pply)) or (math.random(1, 3) == 2)) then
				pply:SetRole(ROLE_TRAITOR)
				table.remove(choices, pick)
				ts = ts + 1
			end

			runs = runs + 1
		end

		local ds = 0
		local min_karma = GetConVar("ttt_detective_karma_min"):GetInt() or 0
		local runs = 0

		while (ds < det_count) and (#choices >= 1) and runs < 99 do
			if #choices <= (det_count - ds) then
				for k, pply in ipairs(choices) do
					if IsValid(pply) and hook.Run("SelectRolesSelected", v, ROLE_DETECTIVE) ~= false then
						pply:SetRole(ROLE_DETECTIVE)
					end
				end

				break
			end

			local pick = math.random(1, #choices)
			local pply = choices[pick]

			if (IsValid(pply) and ((pply:GetBaseKarma() > min_karma and table.HasValue(prev_roles[ROLE_INNOCENT], pply)) or math.random(1, 3) == 2)) then
				if not pply:GetAvoidDetective() and hook.Run("SelectRolesSelected", v, ROLE_DETECTIVE) ~= false then
					pply:SetRole(ROLE_DETECTIVE)
					ds = ds + 1
				end

				table.remove(choices, pick)
			end

			runs = runs + 1
		end

		hook.Run("SelectRoles")
		GAMEMODE.LastRole = {}

		for _, ply in ipairs(plys) do
			ply:SetDefaultCredits()
			GAMEMODE.LastRole[ply:UniqueID()] = ply:GetRole()
		end
	end
end)
