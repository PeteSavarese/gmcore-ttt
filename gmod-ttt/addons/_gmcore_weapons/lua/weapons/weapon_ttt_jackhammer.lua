AddCSLuaFile()
DEFINE_BASECLASS"weapon_tttbase"
SWEP.HoldType = "shotgun"

if CLIENT then
	SWEP.PrintName = "Jack Hammer"
	SWEP.Slot = 6
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 70
	SWEP.Icon = "vgui/ttt/icon_gl_jackhammer"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[Run and gun, the Jack Hammer is
the best way to kill Traitors in a second!
		]]
	}
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_SHOTGUN
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 10
SWEP.Primary.Cone = 0.045
SWEP.Primary.Delay = 0.3
SWEP.Primary.ClipSize = 10
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 6
SWEP.Primary.Sound = Sound("Weapon_Jackhammer.Single")
SWEP.Primary.Recoil = 1.6
SWEP.AutoSpawnable = true
SWEP.Spawnable = true
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/jackhammer/v_jackhammer2.mdl"
SWEP.WorldModel = "models/weapons/jackhammer/w_pancor_jackhammer.mdl"
SWEP.IronSightsPos = Vector(4.026, -2.296, 0.917)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_DETECTIVE}
