
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "USP"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_usp"
end
SWEP.Primary.Recoil				= 1
SWEP.Primary.Damage				= 18
SWEP.Primary.Delay				= 0.2
SWEP.Primary.Cone				= 0.05
SWEP.Primary.ClipSize				= 12
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/usp/2_pist_usp.mdl"
SWEP.WorldModel				= "models/weapons/usp/3_pist_usp.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("Alt_Weapon_USP.1")
SWEP.IronSightsPos					= Vector(1.976, -0.042, 1.34)
SWEP.IronSightsAng					= Vector(0.425, 0, 0)
SWEP.Primary.ClipMax					= 24
SWEP.Primary.DefaultClip					= 12
SWEP.HeadshotMultiplier					= 4.5
SWEP.AutoSpawnable				= true
