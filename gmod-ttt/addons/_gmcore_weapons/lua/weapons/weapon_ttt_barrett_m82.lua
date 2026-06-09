
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Barrett M82A1"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_barret_m82"
end
SWEP.Primary.Recoil				= 7
SWEP.Primary.Damage				= 75
SWEP.Primary.Delay				= 1.5
SWEP.Primary.Cone				= 0.005
SWEP.Primary.ClipSize				= 10
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/barrett_m82/v_50calm82.mdl"
SWEP.WorldModel				= "models/weapons/barrett_m82/w_barret_m82.mdl"
SWEP.Primary.Ammo					= "357"
SWEP.AmmoEnt					= "item_ammo_357_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("BarretM82.Single")
SWEP.IronSightsPos					= Vector(2.894, 0, 1.7624)
SWEP.IronSightsAng					= Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 20
SWEP.Primary.DefaultClip					= 10
SWEP.HeadshotMultiplier					= 8
SWEP.AutoSpawnable				= true
SWEP.Secondary.Sound       = Sound("Default.Zoom")

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}
