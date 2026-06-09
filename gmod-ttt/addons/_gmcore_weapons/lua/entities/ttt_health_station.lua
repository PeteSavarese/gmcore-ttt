AddCSLuaFile()

-- This is trash
local rankToModel = {
	["admin"] = "models/weapons/gl/weapon_skins/christmas_present/present_admin/Present_Admin.mdl",
	["advisor"] = "models/weapons/gl/weapon_skins/christmas_present/present_adv/Present_Adv.mdl",
	["owner"] = "models/weapons/gl/weapon_skins/christmas_present/present_owner/Present_Owner.mdl",
	["developer"] = "models/weapons/gl/weapon_skins/christmas_present/present_dev/Present_Dev.mdl",
	["communitymanager"] = "models/weapons/gl/weapon_skins/christmas_present/present_comm/Present_Comm.mdl",
	["leadadmin"] = "models/weapons/gl/weapon_skins/christmas_present/present_lead/Present_Lead.mdl",
	["mod"] = "models/weapons/gl/weapon_skins/christmas_present/present_mod/Present_Mod.mdl",
	["trialmod"] = "models/weapons/gl/weapon_skins/christmas_present/present_tmod/Present_Tmod.mdl"
}

local storeRankToModel = {
	[1] = "models/weapons/gl/weapon_skins/christmas_present/present_sup/Present_Sup.mdl",
	[2] = "models/weapons/gl/weapon_skins/christmas_present/present_vip/Present_Vip.mdl",
	[3] = "models/weapons/gl/weapon_skins/christmas_present/present_vipp/Present_Vipp.mdl",
	[4] = "models/weapons/gl/weapon_skins/christmas_present/present_elite/Present_Elite.mdl",
	[5] = "models/weapons/gl/weapon_skins/christmas_present/present_leg/Present_Leg.mdl",
}

if CLIENT then
	-- this entity can be DNA-sampled so we need some display info
	ENT.Icon = "vgui/ttt/icon_health"
	ENT.PrintName = "hstation_name"
	local GetPTranslation = LANG.GetParamTranslation
	ENT.TargetIDHint = {
		name = "hstation_name",
		hint = "hstation_hint",
		fmt = function(ent, txt)
			return GetPTranslation(txt, {
				usekey = Key("+use", "USE"),
				num = ent:GetStoredHealth() or 0
			})
		end
	}
end

ENT.Type = "anim"
ENT.DefaultModel = Model("models/props/cs_office/microwave.mdl")

--ENT.CanUseKey = true
ENT.CanHavePrints = true
ENT.MaxHeal = 25
ENT.MaxStored = 200
ENT.RechargeRate = 1
ENT.RechargeFreq = 2 -- in seconds

ENT.NextHeal = 0
ENT.HealRate = 1
ENT.HealFreq = 0.2

AccessorFuncDT(ENT, "StoredHealth", "StoredHealth")
AccessorFunc(ENT, "Placer", "Placer")

function ENT:InitPhysicsAfterModel()
	-- Always init physics even before checking for a skin
	self.CanPickup = false
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(200)
	end
end

function ENT:SetupDataTables()
	self:DTVar("Int", 0, "StoredHealth")
end

function ENT:SetPlacer(ply)
	if ply == nil then return end

	self.Placer = ply

	if IsValid(ply) and SERVER then
		self:CheckActiveSkin()
		self:ApplyUpgrades()
	end
end

function ENT:CheckActiveSkin(iteration)
	if not SERVER then return end

	local owner = self:GetPlacer()
	if not IsValid(owner) then
		self:SetModel(self.DefaultModel)
		self:InitPhysicsAfterModel()

		return
	end

	local tPlyItems = owner.PS_Items
	local desiredModel = self.DefaultModel
	iteration = not iteration and 1 or iteration

	if not tPlyItems then
		-- Retry since we may have joined too early before our PS items were sent to client
		timer.Simple(0.5, function()
			if iteration >= 5 then return end
			if IsValid(self) then self:CheckActiveSkin(iteration + 1) end
		end)

		self:SetModel(desiredModel)
		self:InitPhysicsAfterModel()

		return
	end

	for itemId, item in pairs(tPlyItems) do
		local itemTbl = PS.Items[itemId]
		if not itemTbl then continue end
		if itemTbl.Category != "Skins" then continue end
		if not itemTbl.Class then continue end
		if not owner:PS_HasItemEquipped(itemId) then continue end

		if itemTbl.Class == "weapon_ttt_health_station" then
			if owner:IsStaffRank() then
				local rank = owner:GetUserGroup()
				desiredModel = rankToModel[rank] or desiredModel
			elseif owner:IsStoreRank() then
				local rank = owner:GetStoreRank()
				desiredModel = storeRankToModel[rank] or desiredModel
			else
				desiredModel = itemTbl.WorldModel or desiredModel
			end

			break
		end
	end

	self:SetModel(desiredModel)
	self:InitPhysicsAfterModel()
end

function ENT:ApplyUpgrades()
	if not SERVER then return end
	if not IsValid(self:GetPlacer()) then return end

	if self:GetPlacer():PS_HasItemEquipped("upgrade_hpstation_maxhp") then
		local level = self:GetPlacer():PS_GetUpgradeLevel("upgrade_hpstation_maxhp")

		if level > 0 then
			local m = 200 + (20 * level)
			self.MaxStored = m
			self:SetStoredHealth(m)
		end
	end

	if self:GetPlacer():PS_HasItemEquipped("upgrade_hpstation_heal_rate") then
		local level = self:GetPlacer():PS_GetUpgradeLevel("upgrade_hpstation_heal_rate")
		if level > 0 then self.HealRate = 1 + level end
	end
end

function ENT:Initialize()
	local b = 32

	self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b, b, b))
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
		self:SetModel(self.DefaultModel)
		self:InitPhysicsAfterModel()
		self:SetMaxHealth(200)
		self:SetUseType(CONTINUOUS_USE)
	end

	self:SetHealth(200)
	self:SetColor(Color(180, 180, 250, 255))
	self:SetStoredHealth(200)

	self.Placer = nil
	self.NextHeal = 0
	self.fingerprints = {}
end


function ENT:AddToStorage(amount)
	self:SetStoredHealth(math.min(self.MaxStored, self:GetStoredHealth() + amount))
end

function ENT:TakeFromStorage(amount)
	-- if we only have 5 healthpts in store, that is the amount we heal
	amount = math.min(amount, self:GetStoredHealth())
	self:SetStoredHealth(math.max(0, self:GetStoredHealth() - amount))
	return amount
end

local healsound = Sound("items/medshot4.wav")
local failsound = Sound("items/medshotno1.wav")
local last_sound_time = 0

function ENT:GiveHealth(ply, max_heal)
	if self:GetStoredHealth() > 0 then
		max_heal = max_heal or self.MaxHeal

		local dmg = ply:GetMaxHealth() - ply:Health()

		if dmg > 0 then
			-- constant clamping, no risks
			local healed = self:TakeFromStorage(math.min(max_heal, dmg))
			local new = math.min(ply:GetMaxHealth(), ply:Health() + healed)

			ply:SetHealth(new)

			hook.Run("TTTPlayerUsedHealthStation", ply, self, healed)

			if last_sound_time + 2 < CurTime() then
				self:EmitSound(healsound)
				last_sound_time = CurTime()
			end

			if not table.HasValue(self.fingerprints, ply) then table.insert(self.fingerprints, ply) end

			return true
		else
			self:EmitSound(failsound)
		end
	else
		self:EmitSound(failsound)
	end

	return false
end

function ENT:Use(ply)
	if IsValid(ply) and ply:IsPlayer() and ply:IsActive() then
		local t = CurTime()

		if t > self.NextHeal then
			local healed = self:GiveHealth(ply, self.HealRate)
			self.NextHeal = t + (self.HealFreq * (healed and 1 or 2))
		end
	end
end

if SERVER then
	-- recharge
	local nextcharge = 0

	function ENT:Think()
		if nextcharge < CurTime() then
			self:AddToStorage(self.RechargeRate)
			nextcharge = CurTime() + self.RechargeFreq
		end
	end

	local ttt_damage_own_healthstation = CreateConVar("ttt_damage_own_healthstation", "0") -- 0 as detective cannot damage their own health station
	-- traditional equipment destruction effects
	function ENT:OnTakeDamage(dmginfo)
		if dmginfo:GetAttacker() == self:GetPlacer() and not ttt_damage_own_healthstation:GetBool() then return end

		self:TakePhysicsDamage(dmginfo)
		self:SetHealth(self:Health() - dmginfo:GetDamage())

		local att = dmginfo:GetAttacker()
		local placer = self:GetPlacer()

		if IsPlayer(att) then
			DamageLog(Format("DMG: \t %s [%s] damaged health station [%s] for %d dmg", att:Nick(), att:GetRoleString(), IsPlayer(placer) and placer:Nick() or "<disconnected>", dmginfo:GetDamage()))
			hook.Run("TTTHealthStationDamaged", dmginfo, self)
		end

		if self:Health() < 0 then
			self:Remove()
			util.EquipmentDestroyed(self:GetPos())
			if IsValid(self:GetPlacer()) then LANG.Msg(self:GetPlacer(), "hstation_broken") end
		end
	end
end
