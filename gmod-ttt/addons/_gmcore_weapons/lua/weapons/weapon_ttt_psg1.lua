
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "PSG-1"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_psg1"
end

SWEP.Primary.Recoil				= 1
SWEP.Primary.Damage				= 35
SWEP.Primary.Delay				= 0.15
SWEP.Primary.Cone				= 0.012
SWEP.Primary.ClipSize				= 10
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/psg1/v_psg1_snipe.mdl"
SWEP.WorldModel				= "models/weapons/psg1/w_hk_psg1.mdl"
SWEP.Primary.Ammo					= "357"
SWEP.AmmoEnt					= "item_ammo_357_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound					= Sound("Weapon_psg_1.Single")
SWEP.IronSightsPos = Vector(5.2, 0, 1.16)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 30
SWEP.Primary.DefaultClip					= 10
SWEP.HeadshotMultiplier					= 8
SWEP.AutoSpawnable				= true
SWEP.Secondary.Sound       = Sound("Default.Zoom")

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}
