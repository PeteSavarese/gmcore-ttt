AddCSLuaFile()

SWEP.Base = "weapon_tttbase"

SWEP.UseHands = true

if CLIENT then
	SWEP.PrintName = "AUG"
	SWEP.Slot = 2
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV	= 70
	SWEP.Icon = "vgui/ttt/icon_gl_aug"
end

SWEP.Primary.Recoil = 1
SWEP.Primary.Damage = 25
SWEP.Primary.Delay = 0.15
SWEP.Primary.Cone = 0.005
SWEP.Primary.ClipSize = 30
SWEP.Primary.Automatic = true
SWEP.ViewModel = "models/weapons/aug/v_auga3sa.mdl"
SWEP.WorldModel = "models/weapons/aug/w_auga3.mdl"
SWEP.Primary.Ammo = "Pistol"
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.Kind = WEAPON_HEAVY
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("aug_a3.Single")
SWEP.IronSightsPos = Vector(2.0378, -3.8941, 0.8809)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.HeadshotMultiplier = 1.8
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
