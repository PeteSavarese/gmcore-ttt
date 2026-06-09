AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType               = "physgun"

if CLIENT then
	SWEP.PrintName           = "Barrel Gun"
	SWEP.Slot                = 6

	SWEP.ViewModelFlip       = false
	SWEP.ViewModelFOV        = 54

	SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "Can fire two barrels or one explosive barrel."
	};
	SWEP.Icon					= "vgui/ttt/icon_gl_barrel_gun"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Primary.Ammo          = "none"
SWEP.Primary.ClipSize      = 2
SWEP.Primary.DefaultClip   = 2
SWEP.Primary.Automatic     = true
SWEP.Primary.Delay         = 3
SWEP.Primary.Cone          = 0.005
SWEP.Primary.Sound         = Sound( "weapons/grenade_launcher1.wav" )
SWEP.Primary.SoundLevel    = 54

SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Delay       = 0.5

SWEP.NoSights              = true

SWEP.Kind                  = WEAPON_EQUIP1
SWEP.CanBuy                = {ROLE_TRAITOR}
--SWEP.WeaponID              = AMMO_PUSH

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/c_physcannon.mdl"
SWEP.WorldModel            = "models/weapons/w_Physics.mdl"
SWEP.LimitedStock           = true

SWEP.IsCharging            = false

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then return end

	self:ShootBarrel("models/props_c17/oildrum001.mdl")
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack()
	if self.IsCharging or self:Clip1() < 2 then return end
	self.IsCharging = true
	self:EmitSound("weapons/cguard/charging.wav")

	timer.Simple(1, function()
		self:ShootBarrel("models/props_c17/oildrum001_explosive.mdl")
	end)

	self:TakePrimaryAmmo(2)

	self.IsCharging = false
end


function SWEP:ShootBarrel(prop_path)
	local owner = self:GetOwner()
	if !owner:IsValid() then return end

	self:EmitSound(self.Primary.Sound)

	if SERVER then
		local ent = ents.Create("prop_physics")
		ent:SetModel(prop_path)

		-- This is the same as owner:EyePos() + (self:GetOwner():GetAimVector() * 16)
		-- but the vector methods prevent duplicitous objects from being created
		-- which is faster and more memory efficient
		-- AimVector is not directly modified as it is used again later in the function
		local aimvec = owner:GetAimVector()
		local launch_position = aimvec * 16 -- This creates a new vector object
		launch_position:Add(owner:EyePos()) -- This translates the local aimvector to world coordinates

		ent:SetPos(launch_position)
		ent:SetAngles(owner:EyeAngles())
		ent:SetPhysicsAttacker(self:GetOwner())
		ent:Spawn()

		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)

		local phys = ent:GetPhysicsObject()

		if !phys:IsValid() then ent:Remove() return end

		-- Yeet the barrel and disregard any petulant air resistance
		phys:SetDragCoefficient(0.0)
		phys:SetVelocity(self:GetOwner():GetAimVector() * 100000)

		timer.Simple(3, function()
			if !IsValid(ent) then return end

			ent:Remove()
		end)
	end
end


function SWEP:OnRemove()
	self.IsCharging = false
end

function SWEP:Deploy()
	self.IsCharging = false
	self.BaseClass.Deploy(self)
	return true
end

function SWEP:Holster()
	return !self.IsCharging
end
