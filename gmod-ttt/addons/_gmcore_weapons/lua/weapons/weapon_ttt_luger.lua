
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Luger"
	SWEP.Slot					= 1
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_luger"
end
SWEP.Primary.Recoil				= 2
SWEP.Primary.Damage				= 35
SWEP.Primary.Delay				= 0.25
SWEP.Primary.Cone				= 0.04
SWEP.Primary.ClipSize				= 8
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/luger/v_p08_luger.mdl"
SWEP.WorldModel				= "models/weapons/luger/w_luger_p08.mdl"
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
SWEP.Kind					= WEAPON_PISTOL
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("weapon_luger.single")
SWEP.IronSightsPos					= Vector(2.71, -2.122, 2.27)
SWEP.IronSightsAng					= Vector(0.563, -0.013, 0)
SWEP.Primary.ClipMax					= 32
SWEP.Primary.DefaultClip					= 8
SWEP.HeadshotMultiplier					= 4
SWEP.AutoSpawnable				= true
