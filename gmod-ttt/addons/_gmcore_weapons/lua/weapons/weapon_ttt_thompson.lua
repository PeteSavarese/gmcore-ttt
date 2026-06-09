
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Tommy Gun"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_tommy"
end
SWEP.Primary.Recoil				= 1
SWEP.Primary.Damage				= 20
SWEP.Primary.Delay				= 0.1
SWEP.Primary.Cone				= 0.04
SWEP.Primary.ClipSize				= 75
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/thompson/v_tommy_g.mdl"
SWEP.WorldModel				= "models/weapons/thompson/w_tommy_gun.mdl"
SWEP.Primary.Ammo					= "smg1"
SWEP.AmmoEnt					= "item_ammo_smg1_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_tmg.Single")
SWEP.IronSightsPos					= Vector(3.359, 0, 1.84)
SWEP.IronSightsAng					= Vector(-2.166, -4.039, 0)
SWEP.Primary.ClipMax					= 150
SWEP.Primary.DefaultClip					= 75
SWEP.HeadshotMultiplier					= 1.4
SWEP.AutoSpawnable				= true
