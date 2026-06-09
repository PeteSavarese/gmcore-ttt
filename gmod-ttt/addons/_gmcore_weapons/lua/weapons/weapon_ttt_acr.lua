AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "ACR"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_acr"
end

SWEP.Primary.Recoil				= 1
SWEP.Primary.Damage				= 20
SWEP.Primary.Delay				= 0.08
SWEP.Primary.Cone				= 0.022
SWEP.Primary.ClipSize				= 30
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/acr/v_rif_msda.mdl"
SWEP.WorldModel				= "models/weapons/acr/w_masada_acr.mdl"
SWEP.Primary.Ammo					= "smg1"
SWEP.AmmoEnt					= "item_ammo_smg1_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Masada.Single")
SWEP.IronSightsPos = Vector(2.668, 0, 0.675)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 60
SWEP.Primary.DefaultClip					= 30
SWEP.HeadshotMultiplier					= 2
SWEP.AutoSpawnable				= true
