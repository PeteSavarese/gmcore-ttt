AddCSLuaFile()

SWEP.HoldType = "grenade"

if CLIENT then
	SWEP.PrintName     = "Frag Grenade"
	SWEP.Slot          = 3

	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV  = 70

	SWEP.Icon          = "vgui/ttt/icon_nades"
	SWEP.IconLetter    = "h"
end

SWEP.Base          = "weapon_tttbasegrenade"

SWEP.Kind          = WEAPON_NADE

SWEP.Spawnable     = true
SWEP.AutoSpawnable = true

SWEP.UseHands      = true
SWEP.ViewModel      = "models/weapons/frag_grenade/v_eq_fraggrenade.mdl"
SWEP.WorldModel     = "models/weapons/frag_grenade/w_eq_fraggrenade.mdl"

SWEP.Weight        = 5

function SWEP:GetGrenadeName()
	return "ttt_fraggrenade_proj"
end
