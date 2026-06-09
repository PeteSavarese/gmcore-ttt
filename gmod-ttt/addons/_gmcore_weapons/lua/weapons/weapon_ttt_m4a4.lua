
AddCSLuaFile()


SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "M4A4"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_m16"
end
SWEP.Primary.Recoil				= 1.9
SWEP.Primary.Damage				= 22
SWEP.Primary.Delay				= 0.085
SWEP.Primary.Cone				= 0.008
SWEP.Primary.ClipSize				= 30
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/m4a4/v_rif_m4a1.mdl"
SWEP.WorldModel				= "models/weapons/m4a4/w_rif_m4a1.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_CSGO_M4A1.Single")
SWEP.IronSightsPos					= Vector(2.4537, 1.0923, 0.2696)
SWEP.IronSightsAng					= Vector(-0.0105, -0.0061, 0)
SWEP.Primary.ClipMax					= 60
SWEP.Primary.DefaultClip					= 30
SWEP.HeadshotMultiplier					= 1.7
SWEP.AutoSpawnable				= true
