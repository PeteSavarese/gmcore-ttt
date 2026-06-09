-- I heard using an entity to sync variables with all players is good
-- this is what sandbox does (edit_sky, edit_sun, ..)
local ENT = {
	Type = "anim",
	base = "base_anim",
	SetupDataTables = function(self)
		self:NetworkVar("Int", 0, "PlayedRounds")
		self:NetworkVar("Bool", 0, "LastRoundMapExists")
		self:NetworkVar("Int", 1, "PendingReports")
	end,
	UpdateTransmitState = function()
		return TRANSMIT_ALWAYS
	end,
	CalculatePendingReports = function(self)
		local cnt = 0

		for _, reports in pairs({Damagelog.Reports.Current, Damagelog.Reports.Previous}) do
			for _, r in pairs(reports) do
				if r and r.status == RDM_MANAGER_WAITING and not r.adminReport then
					cnt = cnt + 1
				end
			end
		end

		self:SetPendingReports(cnt)
	end,
	Draw = function() end,
	Initialize = function(self)
		self:DrawShadow(false)
		self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
	end
}

scripted_ents.Register(ENT, "dmglog_sync_ent")

-- Getting the entity serverside or clientside
-- Then all we'll have to do is using Get* and Set* functions we create using NetworkVar()
---@return Entity|nil entity The damage log sync entity, or nil if not found
function Damagelog:GetSyncEnt()
	if SERVER then
		return self.sync_ent
	else
		return ents.FindByClass("dmglog_sync_ent")[1]
	end
end

if SERVER then
	-- Creating the entity on InitPostEntity
	hook.Add("InitPostEntity", "InitPostEntity_Damagelog", function()
		Damagelog.sync_ent = ents.Create("dmglog_sync_ent")
		Damagelog.sync_ent:Spawn()
		Damagelog.sync_ent:Activate()
		Damagelog.sync_ent:SetLastRoundMapExists(Damagelog.last_round_map and true or false)
		Damagelog.sync_ent:CalculatePendingReports()
	end)
end
