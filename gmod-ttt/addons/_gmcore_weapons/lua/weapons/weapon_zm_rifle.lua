AddCSLuaFile()

SWEP.HoldType = "ar2"

if CLIENT then
	SWEP.PrintName = "rifle_name"
	SWEP.Slot = 2
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 75
	SWEP.Icon = "vgui/ttt/icon_scout"
	SWEP.IconLetter = "n"
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_RIFLE

SWEP.Primary.Delay = 1.5
SWEP.Primary.Recoil = 7
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "357"
SWEP.Primary.Damage = 50
SWEP.Primary.Cone = 0.005
SWEP.Primary.ClipSize = 10
SWEP.Primary.ClipMax = 20 -- keep mirrored to ammo
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Sound = Sound("Weapon_Scout.Single")

SWEP.Secondary.Sound = Sound("Default.Zoom")

SWEP.HeadshotMultiplier = 4

SWEP.AutoSpawnable = true
SWEP.Spawnable = true
SWEP.AmmoEnt = "item_ammo_357_ttt"

SWEP.UseHands = true
SWEP.ViewModel = Model("models/weapons/cstrike/c_snip_scout.mdl")
SWEP.WorldModel = Model("models/weapons/w_snip_scout.mdl")


SWEP.IronSightsPos = Vector(3.319, 0, 1.559)
SWEP.IronSightsAng = Vector(0, 0, 0)

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}
