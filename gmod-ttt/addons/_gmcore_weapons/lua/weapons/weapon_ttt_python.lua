
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Colt Python"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_python"
end
SWEP.Primary.Recoil				= 7
SWEP.Primary.Damage				= 40
SWEP.Primary.Delay				= 0.7
SWEP.Primary.Cone				= 0.02
SWEP.Primary.ClipSize				= 6
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/python/v_pist_python.mdl"
SWEP.WorldModel				= "models/weapons/python/w_colt_python.mdl"
SWEP.Primary.Ammo					= "AlyxGun"
SWEP.AmmoEnt					= "item_ammo_revolver_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("Weapon_ColtPython.Single")
SWEP.IronSightsPos					= Vector(-2.743, -1.676, 1.796)
SWEP.IronSightsAng					= Vector(0.611, 0.185, 0)
SWEP.Primary.ClipMax					= 12
SWEP.Primary.DefaultClip					= 6
SWEP.HeadshotMultiplier					= 4
SWEP.AutoSpawnable				= true
