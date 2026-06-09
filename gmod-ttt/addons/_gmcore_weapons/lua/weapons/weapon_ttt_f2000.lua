AddCSLuaFile()

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName = "F2000"
	SWEP.Slot = 2
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 70
	SWEP.Icon = "vgui/ttt/icon_gl_f2000"
end

SWEP.Primary.Recoil = 2.7
SWEP.Primary.Damage = 14
SWEP.Primary.Delay = 0.09
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 30
SWEP.Primary.Automatic = true
SWEP.ViewModel = "models/weapons/f2000/v_tct_f2000.mdl"
SWEP.WorldModel = "models/weapons/f2000/w_fn_f2000.mdl"
SWEP.Primary.Ammo = "Pistol"
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.Kind = WEAPON_HEAVY
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("Weapon_F2000.Single")
SWEP.IronSightsPos = Vector(2.0378, -3.8941, 0.8809)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.HeadshotMultiplier = 1.9
SWEP.AutoSpawnable = true
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
