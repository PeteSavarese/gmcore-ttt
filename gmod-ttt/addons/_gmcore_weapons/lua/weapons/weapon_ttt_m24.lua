AddCSLuaFile()

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName = "M24"
	SWEP.Slot = 2
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 70
	SWEP.Icon = "vgui/ttt/icon_gl_m24"
end

SWEP.Primary.Recoil = 3
SWEP.Primary.Damage = 50
SWEP.Primary.Delay = 0.7
SWEP.Primary.Cone = 0.001
SWEP.Primary.ClipSize = 5
SWEP.Primary.Automatic = false
SWEP.ViewModel = "models/weapons/m24/v_dmg_m24s.mdl"
SWEP.WorldModel = "models/weapons/m24/w_snip_m24_6.mdl"
SWEP.Primary.Ammo = "357"
SWEP.AmmoEnt = "item_ammo_357_ttt"
SWEP.Kind = WEAPON_HEAVY
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("Dmgfok_M24SN.Single")
SWEP.IronSightsPos = Vector(2.894, 0, 1.7624)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax = 10
SWEP.Primary.DefaultClip = 5
SWEP.HeadshotMultiplier = 3
SWEP.AutoSpawnable = true
SWEP.Secondary.Sound = Sound("Default.Zoom")

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}
