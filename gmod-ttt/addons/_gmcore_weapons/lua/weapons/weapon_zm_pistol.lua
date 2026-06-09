AddCSLuaFile()

SWEP.HoldType              = "pistol"
SWEP.Base                  = "weapon_tttbase"

SWEP.Kind                  = WEAPON_PISTOL
SWEP.WeaponID              = AMMO_PISTOL

if CLIENT then
	SWEP.PrintName					= "Five Seven"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_pistol"
end
		
SWEP.Primary.Recoil				= 1.5
SWEP.Primary.Damage				= 20
SWEP.Primary.Delay				= 0.10
SWEP.Primary.Cone				= 0.025
SWEP.Primary.ClipSize				= 20
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/five_seven/v_pist_fiveseven.mdl"
SWEP.WorldModel				= "models/weapons/five_seven/3_pist_fiveseven.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("weapons/fiveseven/fiveseven-1.mp3")
SWEP.IronSightsPos					= Vector(-2.08, 0, 0.239)
SWEP.IronSightsAng					= Vector(0.3, 0.009, 0)
SWEP.Primary.ClipMax					= 40
SWEP.Primary.DefaultClip					= 20
SWEP.AutoSpawnable				= true
