
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"
SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Plogi AA" 
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_ahg_m249"
end

SWEP.Primary.Recoil				= 0
SWEP.Primary.Damage				= 12
SWEP.Primary.Delay				= 0.005
SWEP.Primary.Cone				= 0.001
SWEP.Primary.ClipSize				= 1500
SWEP.Primary.Automatic				= true
SWEP.ViewModel             = "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.WorldModel            = "models/weapons/w_mach_m249para.mdl"
SWEP.Primary.Ammo					= "smg1"
SWEP.AmmoEnt					= "item_ammo_smg1_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_m249.Single")
SWEP.IronSightsPos					= Vector(-4.015, 0, 1.764)
SWEP.IronSightsAng					= Vector(0, -0.014, 0)
SWEP.Primary.ClipMax					= 3000
SWEP.Primary.DefaultClip					= 1500
SWEP.HeadshotMultiplier					= 1.8
SWEP.AutoSpawnable				= false