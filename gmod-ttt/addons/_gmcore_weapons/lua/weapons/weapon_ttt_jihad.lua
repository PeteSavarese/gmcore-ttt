if CLIENT then
	SWEP.PrintName = "Jihad"
	SWEP.Slot = 7

	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "Jihad Bomb",
		desc = "Suicide bomb!"
	}

	SWEP.Icon = "vgui/ttt/icon_gl_jihad"
end

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel  = Model("models/weapons/zaratusa/jihad_bomb/v_jb.mdl")
SWEP.WorldModel = Model("models/weapons/zaratusa/jihad_bomb/w_jb.mdl")

SWEP.Base = "weapon_tttbase"
SWEP.ViewModelFlip = false
SWEP.Kind = WEAPON_EQUIP2
SWEP.Slot = 7
SWEP.CanBuy = {ROLE_TRAITOR}

SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.AutoSpawnable = false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Delay			= 3

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.LastPickupTime = 0
SWEP.LastOwner = nil
SWEP.WasDropped = false

---Checks whether the jihad bomb owner can detonate.
---@param owner Player The player holding the jihad bomb
---@param swep SWEP The jihad bomb weapon instance
---@return boolean canExplode True if all conditions for detonation are met
local function canExplode(owner, swep)
	if not IsValid(owner) then return false end
	if not owner:Alive() then return false end
	if owner:GetActiveWeapon() ~= swep then return false end
	if swep.WasDropped then return false end

	return true
end

function SWEP:Deploy()
	self.LastPickupTime = CurTime()
	self.LastOwner = self:GetOwner()

	return true
end

function SWEP:OnDrop(bThrown)
	self.WasDropped = true
end

function SWEP:Reload()
end

function SWEP:Think()
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self.WasDropped = false

	-- if self:GetOwner():PS_HasItemEquipped("warthog") then
	--   self:WarthogAttack()
	--   return
	-- end

	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetOwner():GetPos())
	effectdata:SetNormal(self:GetOwner():GetPos())
	effectdata:SetMagnitude(8)
	effectdata:SetScale(1)
	effectdata:SetRadius(16)
	util.Effect("Sparks", effectdata)

	self.BaseClass.ShootEffects(self)

	if SERVER then
		timer.Simple(2, function()
			if not IsValid(self) then return end
			self:Explode()
		end)

		local tPlyItems = self:GetOwner().PS_Items
		local sSelectedSound = "gmcore/jihad/default.mp3" -- Default sound unless another is found

		for itemId, item in pairs(tPlyItems) do
			local itemTbl = PS.Items[itemId]
			if not itemTbl or not itemTbl.Sound then continue end

			if string.find(itemTbl.Sound, "gmcore/jihad/") and self:GetOwner():PS_HasItemEquipped(itemId) then
				sSelectedSound = itemTbl.Sound
				break
			end
		end

		self:GetOwner():EmitSound(sSelectedSound, 75, 100, 0.5)
	end
end


function SWEP:WarthogAttack()
	local owner = self:GetOwner()
	---@cast owner Player

	if not canExplode(owner, self) then return end

	self:SetNextPrimaryFire(CurTime() + 3)

	owner:EmitSound("gmcore/jihad/warthog_attack.mp3", 75, 100, 1)

	timer.Create(owner:SteamID() .. "jihad_attack", 0.1, 19, function()
		if not self:GetOwner() or not IsValid(self:GetOwner()) or not self:GetOwner():Alive() then
			timer.Remove(owner:SteamID() .. "jihad_attack")
			return
		end

		local explodePos = owner:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(explodePos)
		effectdata:SetNormal(explodePos)
		effectdata:SetMagnitude(8)
		effectdata:SetScale(1)
		effectdata:SetRadius(16)
		util.Effect("Sparks", effectdata)
		self.BaseClass.ShootEffects(self)
	end)

	if SERVER then
		timer.Create(owner:SteamID() .. "jihad_explode" .. CurTime(), 2, 1, function()
			if not self:GetOwner() or not self:GetOwner():Alive() then return end

			local explodePos = owner:GetPos()
			local ent = ents.Create("env_explosion")
			ent:SetPos(explodePos)
			ent:SetOwner(owner)
			ent:Spawn()
			ent:SetKeyValue("iMagnitude", "250")
			ent:Fire("Explode", 0, 0)
			ent:EmitSound("gmcore/jihad/warthog_brrrt.mp3", 500)

			owner:Kill()

			self:Remove()
		end)
	end
end

function SWEP:Explode()
	local soundPath = "siege/big_explosion.wav"
	local plyPsItems = self:GetOwner().PS_Items
	local owner = self:GetOwner()
	---@cast owner Player

	if not canExplode(owner, self) then return end

	for itemId, item in pairs(plyPsItems) do
		local itemTbl = PS.Items[itemId]
		if not itemTbl or not itemTbl.Sound then continue end

		if itemTbl.SoundExplode and owner:PS_HasItemEquipped(itemId) then
			soundPath = itemTbl.SoundExplode
			break
		end
	end

	local ent = ents.Create("env_explosion")
	ent:SetPos(self:GetOwner():GetPos())
	ent:SetOwner(self:GetOwner())
	ent:Spawn()
	ent:SetKeyValue("iMagnitude", "250")
	ent:Fire("Explode", 0, 0)
	ent:EmitSound(soundPath, 500)

	self:Remove()
	self:GetOwner():Kill()
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 1)

	local plyPsItems = self:GetOwner().PS_Items
	local tauntSound = Sound("vo/npc/male01/overhere01.wav")

	for itemId, item in pairs(plyPsItems) do
		local itemTbl = PS.Items[itemId]
		if not itemTbl or not itemTbl.Sound then continue end

		if itemTbl.SoundTaunts and self:GetOwner():PS_HasItemEquipped(itemId) then
			tauntSound = table.Random(itemTbl.SoundTaunts)
			break
		end
	end

	self:EmitSound(tauntSound)

	-- The rest is only done on the server
	if not SERVER then return end
end
