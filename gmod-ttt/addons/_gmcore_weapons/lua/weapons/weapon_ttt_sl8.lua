AddCSLuaFile()

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName = "HK SL8"
	SWEP.Slot = 2
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 70
	SWEP.Icon = "vgui/ttt/icon_gl_sl8"
end

SWEP.Primary.Recoil = 3
SWEP.Primary.Damage = 30
SWEP.Primary.Delay = 0.4
SWEP.Primary.Cone = 0.002
SWEP.Primary.ClipSize = 10
SWEP.Primary.Automatic = false
SWEP.ViewModel = "models/weapons/hk_sl8/v_hk_sl8.mdl"
SWEP.WorldModel = "models/weapons/hk_sl8/w_hk_sl8.mdl"
SWEP.Primary.Ammo = "357"
SWEP.AmmoEnt = "item_ammo_357_ttt"
SWEP.Kind = WEAPON_HEAVY
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("Weapon_hksl8.Single")
SWEP.IronSightsPos = Vector(3.079, -1.333, 0.437)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 10
SWEP.HeadshotMultiplier = 6
SWEP.AutoSpawnable = false
SWEP.Secondary.Sound = Sound("Default.Zoom")

-- Sniper specifications
SWEP.IsSniper = true
SWEP.SniperSettings = {
	SetZoomFunc = function(wep)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_acogcross"))
		surface.DrawTexturedRect(wep.ReticleTable.x, wep.ReticleTable.y, wep.ReticleTable.w, wep.ReticleTable.h)

		-- Draw the CHEVRON
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_acogchevron"))
		surface.DrawTexturedRect(wep.ReticleTable.x, wep.ReticleTable.y, wep.ReticleTable.w, wep.ReticleTable.h)

		-- Draw the SCOPE
		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetTexture(surface.GetTextureID("scope/gdcw_closedsight"))
		surface.DrawTexturedRect(wep.LensTable.x, wep.LensTable.y, wep.LensTable.w, wep.LensTable.h)
	end
}
