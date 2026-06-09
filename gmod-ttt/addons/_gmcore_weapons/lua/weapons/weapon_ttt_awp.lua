
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "AWP"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 64
	SWEP.Icon					= "vgui/ttt/icon_gl_awp"
end

SWEP.Primary.Recoil				= 7
SWEP.Primary.Damage				= 50
SWEP.Primary.Delay				= 1.5
SWEP.Primary.Cone				= 0.005
SWEP.Primary.ClipSize				= 10
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/cstrike/c_snip_awp.mdl"
SWEP.WorldModel				= "models/weapons/w_snip_awp.mdl"
SWEP.Primary.Ammo					= "357"
SWEP.AmmoEnt					= "item_ammo_357_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_awp.Single")
SWEP.IronSightsPos					= Vector(5, -15, -2)
SWEP.IronSightsAng					= Vector(2.6, 1.37, 3.5)
SWEP.Primary.ClipMax					= 20
SWEP.Primary.DefaultClip					= 10
SWEP.HeadshotMultiplier					= 4
SWEP.AutoSpawnable				= true
SWEP.Secondary.Sound       = Sound("Default.Zoom")

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}
