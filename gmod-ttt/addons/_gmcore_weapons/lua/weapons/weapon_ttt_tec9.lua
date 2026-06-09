
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "TEC 9"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_tec9"
end

SWEP.Primary.Recoil				= 0.6
SWEP.Primary.Damage				= 14
SWEP.Primary.Delay				= 0.2
SWEP.Primary.Cone				= 0.026
SWEP.Primary.ClipSize				= 32
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/tec9/v_tec_9_smg.mdl"
SWEP.WorldModel				= "models/weapons/tec9/w_intratec_tec9.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("Weapon_Tec9.Single")
SWEP.IronSightsPos					= Vector(2.2042, 0, 1.7661)
SWEP.IronSightsAng					= Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 64
SWEP.Primary.DefaultClip					= 32
SWEP.HeadshotMultiplier					= 1.7
SWEP.AutoSpawnable				= true
