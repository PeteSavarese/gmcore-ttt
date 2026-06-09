AddCSLuaFile()

SWEP.HoldType              = "pistol"

if CLIENT then
	SWEP.PrintName          = "Manhack Gun"
	SWEP.Slot               = 6
	SWEP.ViewModelFlip      = false
	SWEP.ViewModelFOV       = 72
	SWEP.Icon               = "vgui/ttt/icon_gl_manhack"

		SWEP.EquipMenuData = {
			type = "Weapon",
			desc = [[Launch manhacks to attack your enemies.]]
		}
end


SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Delay         = 0.2
SWEP.Primary.Recoil        = 0
SWEP.Primary.Automatic     = true
SWEP.Primary.Damage        = 0
SWEP.Primary.Cone          = 0.005
SWEP.Primary.ClipSize      = 5
SWEP.Primary.ClipMax       = 5 -- keep mirrored to ammo
SWEP.Primary.DefaultClip   = 5
SWEP.Primary.Sound         = Sound("Weapon_Crossbow.Single")

SWEP.HeadshotMultiplier    = 0

SWEP.AutoSpawnable         = false

SWEP.UseHands              = true
SWEP.ViewModel = Model("models/weapons/c_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pistol.mdl")

SWEP.IronSightsPos = Vector(5, -15, -2)
SWEP.IronSightsAng = Vector(2.6, 1.37, 3.5)

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.LimitedStock           = true

function SWEP:PrimaryAttack(worldsnd)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if !self:CanPrimaryAttack() then return end

	if !worldsnd then
		self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
	elseif SERVER then
		sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
	end

	self:ShootProp()
	self:TakePrimaryAmmo(1)
	local owner = self:GetOwner()

	if !IsValid(owner) or owner:IsNPC() or (!owner.ViewPunch) then return end

	owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
end
function SWEP:ShootProp(model_file)
	self:EmitSound(self.Primary.Sound)

	if CLIENT then return end

	local ent = ents.Create("npc_manhack")
	local trace = self:GetOwner():GetEyeTrace()
	local pos = trace.HitPos
	pos.z = pos.z + 20
	ent:SetPos(pos)
	ent.OriginalSpawner = self:GetOwner() -- This will never change. Always remains as original spawner
	ent.CurrentAttacker = self:GetOwner() -- This will be changed whenever someone picks the manhack up. Changed back to ent.OriginalSpawner when released from magneto
	ent:Spawn()

	if self:GetOwner():PS_HasItemEquipped("balloon_gun") then
			ent:SetModel("models/jojobull/hab.mdl")
			ent:SetModelScale(0.05)
	end
end

-- Hook to attribute damage to the current attacker since by default there is no attacker attributed to the dmg
hook.Add("EntityTakeDamage", "gmcore.ManhackGun.AttributeAttacker", function(victim, dmginfo)
	if !victim:IsPlayer() then return end

	local attacker = dmginfo:GetInflictor() -- Entity that is inflicting damage. Not necessarily the player

	if attacker:GetClass() != "npc_manhack" then return end
	if not IsValid(attacker.CurrentAttacker) then return end
	if attacker.CurrentAttacker:GetRole() == ROLE_TRAITOR and victim:GetRole() == ROLE_TRAITOR then return end -- Don't attribute damage for T on T damage to prevent karma loss

	dmginfo:SetAttacker(attacker.CurrentAttacker)
end)

-- Change CurrentAttacker of manhack to whoever is actively holding it with their magneto
hook.Add("TTTMagnetoPickup", "gmcore.Manhack.ChangeAttacker", function(ply, ent, ghostEnt)
	if !IsValid(ent) then return end
	if ent:GetClass() != "npc_manhack" then return end

	ent.CurrentAttacker = ply
end)

-- Change CurrentAttacker of manhack to the original spawner since it is no longer being carried
hook.Add("TTTMagnetoDrop", "gmcore.Manhack.ChangeAttacker", function(ply, ent)
	if !IsValid(ent) then return end
	if ent:GetClass() != "npc_manhack" then return end

	ent.CurrentAttacker = ent.OriginalSpawner
end)
