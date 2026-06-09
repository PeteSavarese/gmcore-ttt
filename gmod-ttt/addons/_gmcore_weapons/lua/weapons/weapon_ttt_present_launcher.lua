game.AddParticles("particles/present_particles.pcf")
PrecacheParticleSystem("presentstars")

SWEP.ViewModelFOV = 56
SWEP.ViewModel = "models/weapons/v_presentlauncher.mdl"
SWEP.WorldModel = "models/weapons/w_presentlauncher.mdl"
SWEP.UseHands = true
SWEP.Slot = 4
SWEP.HoldType = "rpg"
SWEP.PrintName = "Present Launcher"
SWEP.Spawnable = true
SWEP.Weight = 5
SWEP.DrawCrosshair = true
SWEP.Category = "Present Launcher"
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false
SWEP.Secondary.Ammo = "none"

-------- TTT --------
SWEP.EquipMenuData = {
	type = "item_weapon",
	desc = [[Shoot one of each present that explodes or heals!
Left click to explode, right to heal.
	]]
}

SWEP.Base = "weapon_tttbase"
SWEP.Icon = "vgui/ttt/icon_presentlauncher"
SWEP.Kind = WEAPON_EQUIP1
-- SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
SWEP.CanBuy = {} -- NOT CHRISTMAS
SWEP.LimitedStock = true
SWEP.Primary.ClipSize = 2
SWEP.Primary.DefaultClip = 2
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Slot = 6
SWEP.ViewModelFlip = false

function SWEP:IsEquipment()
	return false
end

-------------------
function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:TakePrimaryAmmo(1)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:EmitSound("NPC_Combine.GrenadeLaunch")

	if SERVER then
		local grenade = ents.Create("ent_present_explosive")
		grenade:SetOwner(self:GetOwner())
		grenade:SetPos(self:GetOwner():EyePos() + self:GetOwner():GetAimVector())
		grenade:SetAngles(self:GetOwner():GetAngles())
		grenade:Spawn()
		grenade:Activate()

		local phys = grenade:GetPhysicsObject()
		local velocity = self:GetOwner():GetAimVector()
		velocity = velocity * 12500

		phys:ApplyForceCenter(velocity)
		self:SetNextPrimaryFire(CurTime() + 1)
	end
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	self:TakeSecondaryAmmo(1)
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:EmitSound("NPC_Combine.GrenadeLaunch")

	if SERVER then
		local grenade = ents.Create("ent_present_healing")
		grenade:SetOwner(self:GetOwner())
		grenade:SetPos(self:GetOwner():EyePos() + self:GetOwner():GetAimVector())
		grenade:SetAngles(self:GetOwner():GetAngles())
		grenade:Spawn()
		grenade:Activate()

		local phys = grenade:GetPhysicsObject()
		local velocity = self:GetOwner():GetAimVector()
		velocity = velocity * 3500

		phys:ApplyForceCenter(velocity)
		self:SetNextSecondaryFire(CurTime() + 1)
	end
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end