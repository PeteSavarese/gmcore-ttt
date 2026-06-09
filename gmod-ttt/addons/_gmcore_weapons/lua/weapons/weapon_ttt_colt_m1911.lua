
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Colt M1911"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_colt_1911"
end

SWEP.Primary.Recoil				= 0.8
SWEP.Primary.Damage				= 26
SWEP.Primary.Delay				= 0.38
SWEP.Primary.Cone				= 0.018
SWEP.Primary.ClipSize				= 7
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/colt_m1911/f_dmgf_co1911.mdl"
SWEP.WorldModel				= "models/weapons/colt_m1911/s_dmgf_co1911.mdl"
SWEP.Primary.Ammo					= "AlyxGun"
SWEP.AmmoEnt					= "item_ammo_revolver_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("Dmgfok_co1911.Single")
SWEP.IronSightsPos					= Vector(-2.6004, -1.3877, 1.1892)
SWEP.IronSightsAng					= Vector(0.3756, -0.0032, 0.103)
SWEP.Primary.ClipMax					= 36
SWEP.Primary.DefaultClip					= 7
SWEP.HeadshotMultiplier					= 8
SWEP.AutoSpawnable				= true
