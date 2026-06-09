
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "M1918 BAR"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_m1918"
end
SWEP.Primary.Recoil				= 2
SWEP.Primary.Damage				= 30
SWEP.Primary.Delay				= 0.18
SWEP.Primary.Cone				= 0.01
SWEP.Primary.ClipSize				= 20
SWEP.Primary.Automatic				= true
SWEP.ViewModel				= "models/weapons/m1918_bar/v_m1918bar.mdl"
SWEP.WorldModel				= "models/weapons/m1918_bar/w_m1918_bar.mdl"
SWEP.Primary.Ammo					= "smg1"
SWEP.AmmoEnt					= "item_ammo_smg1_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_bar1.Single")
SWEP.IronSightsPos					= Vector(3.313, 0, 1.399)
SWEP.IronSightsAng					= Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 40
SWEP.Primary.DefaultClip					= 20
SWEP.HeadshotMultiplier					= 2.8
SWEP.AutoSpawnable				= true
