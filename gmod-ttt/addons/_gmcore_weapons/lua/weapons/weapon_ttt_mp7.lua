
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "MP7"
	SWEP.Slot					= 6
	SWEP.ViewModelFlip					= true
	SWEP.ViewModelFOV					= 70
	SWEP.Icon = "vgui/ttt/icon_gl_mp7"

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[
		With a high fire rate and silent, and equipped
		with a scope, innocents won't even see you coming.]]
	}
end

SWEP.Primary.Recoil = 0.8
SWEP.Primary.Damage = 22
SWEP.Primary.Delay = 0.077
SWEP.Primary.Cone = 0.05
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.ViewModel = "models/weapons/mp7/v_mp7_silenced.mdl"
SWEP.WorldModel = "models/weapons/mp7/w_mp7_silenced.mdl"
SWEP.Primary.Ammo = "smg1"
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.Kind = WEAPON_EQUIP1
SWEP.HoldType = "ar2"
SWEP.Primary.Sound = Sound("weapons/mp7/usp1.mp3")
SWEP.Secondary.Sound = Sound("Default.Zoom")
SWEP.IronSightsPos = Vector(2.62, -1.385, 2.05)
SWEP.IronSightsAng = Vector(-0.3, 0, 0.291)
SWEP.HeadshotMultiplier = 2
SWEP.AutoSpawnable = false
SWEP.CanBuy = {ROLE_TRAITOR}

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
