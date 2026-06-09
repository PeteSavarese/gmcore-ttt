AddCSLuaFile()

SWEP.HoldType        = "ar2"

if CLIENT then
	SWEP.PrintName       = "AAC Honey Badger"
	SWEP.Slot            = 2

	SWEP.Icon = "vgui/ttt/icon_gl_honey_badger"
	SWEP.ViewModelFlip      = false
	SWEP.ViewModelFOV    = 70
end


SWEP.Base            = "weapon_tttbase"

SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Delay         = 0.075
SWEP.Primary.Recoil        = 0.5
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "smg1"
SWEP.Primary.Damage        = 16
SWEP.Primary.Cone          = 0.023
SWEP.Primary.ClipSize      = 30
SWEP.Primary.ClipMax         = 60
SWEP.Primary.DefaultClip   = 30
SWEP.AutoSpawnable         = true
SWEP.AmmoEnt               = "item_ammo_smg1_ttt"

SWEP.UseHands        = true
SWEP.ViewModel       = "models/weapons/honey_badger/v_aacbadger.mdl"
SWEP.WorldModel         = "models/weapons/honey_badger/w_aac_honeybadger.mdl"

SWEP.Primary.Sound = Sound("Weapon_HoneyB.single")

SWEP.IronSightsPos = Vector(-3.096, -3.695, 0.815)
SWEP.IronSightsAng = Vector(0.039, 0, 0)
