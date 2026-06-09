---Food item pickup entity for the fun round. Displays a floating, rotating food model with a name label that players can pick up.
-- Coppied from base_ammo_ttt
AddCSLuaFile()

if CLIENT then
	surface.CreateFont("gmcore.FunRounds.Ents.FoodItemName", {
		font = "Biko",
		size = 55,
		weight = 1000 -- Bold
	})
end

-- Items and their scaling to make models bigger
local tItemModelScaling = {
	["gmcore_funround_wine"] = 2,
	["gmcore_funround_pie"] = 2,
	["gmcore_funround_turkeyleg"] = 2.5,
	["gmcore_funround_turkey"] = 2,
}

ENT.Type = "anim"

-- Used to share item type to the client
function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ItemClass")
end

function ENT:Initialize()
	self.tWeaponInfo = weapons.Get(self:GetItemClass())

	self:SetModel(self.tWeaponInfo.WorldModel)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)

	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	local b = 26
	self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

	if tItemModelScaling[self:GetItemClass()] then
		self:SetModelScale(tItemModelScaling[self:GetItemClass()])
	end

	if SERVER then
			self:SetTrigger(true)
	end

	self.tickRemoval = false
end

function ENT:CanPickupFoodItem(ply)
	for _, ent in pairs(ply:GetWeapons()) do
		if (ent.Base && ent.Base != nil && ent.Base != "") && ent.Base == "weapon_tttbase" then return false end
	end

	return true
end

function ENT:Touch(ent)
	if (SERVER and self.tickRemoval ~= true) and ent:IsValid() and ent:IsPlayer() and self:CanPickupFoodItem(ent) then
		ent:Give(self:GetItemClass())
		self:Remove()
	end
end
