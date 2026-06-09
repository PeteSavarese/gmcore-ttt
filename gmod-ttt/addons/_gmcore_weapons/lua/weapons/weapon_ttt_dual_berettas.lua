
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Dual Berettas"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
end
SWEP.Primary.Recoil				= 1.5
SWEP.Primary.Damage				= 25
SWEP.Primary.Delay				= 0.12
SWEP.Primary.Cone				= 0.05
SWEP.Primary.ClipSize				= 30
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/v_pist_elite.mdl"
SWEP.WorldModel				= "models/weapons/w_pist_elite.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "duel"
SWEP.Primary.Sound					= Sound("Weapon_ELITE.Single")
SWEP.IronSightsPos = Vector(0, -2.5, 1.25)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 60
SWEP.Primary.DefaultClip					= 30
SWEP.HeadshotMultiplier					= 1.7
SWEP.AutoSpawnable				= true

// Sticky Bandit patch for alternating left and right
SWEP.lastShotHand = 0

function SWEP:PrimaryAttack()
	self.BaseClass.PrimaryAttack(self, true)

	local vm = self:GetOwner():GetViewModel()

	if self.lastShotHand == 0 then
		vm:SetSequence(vm:LookupSequence("shoot_left1"))
		self.lastShotHand = 1
	elseif self.lastShotHand == 1 then
		vm:SetSequence(vm:LookupSequence("shoot_right1"))
		self.lastShotHand = 0
	end
end
