
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "Smith & Wesson 500"
	SWEP.Slot					= 6
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_sw550"
	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = [[A powerful revolver that can take down
most targets with a single shot. Has a
high recoil and a slow rate of fire.]]
	};
end

SWEP.Primary.Recoil				= 7
SWEP.Primary.Damage				= 75
SWEP.Primary.Delay				= 0.7
SWEP.Primary.Cone				= 0.05
SWEP.Primary.ClipSize				= 6
SWEP.Primary.Automatic				= false
SWEP.ViewModel				= "models/weapons/sw500/v_pist_500.mdl"
SWEP.WorldModel				= "models/weapons/sw500/w_erect_re500.mdl"
SWEP.Primary.Ammo					= "AlyxGun"
SWEP.AmmoEnt					= "item_ammo_revolver_ttt"
SWEP.Kind					= WEAPON_EQUIP1
SWEP.HoldType					= "pistol"
SWEP.Primary.Sound					= Sound("fire.ballsack")
SWEP.IronSightsPos					= Vector(-2.018, 0, 0.1)
SWEP.IronSightsAng					= Vector(-0.4, -0.01, 4.5)
SWEP.Primary.ClipMax					= 12
SWEP.Primary.DefaultClip					= 6
SWEP.HeadshotMultiplier					= 5
SWEP.AutoSpawnable				= false
SWEP.CanBuy = {ROLE_DETECTIVE}
