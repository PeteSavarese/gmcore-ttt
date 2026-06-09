if SERVER then
	AddCSLuaFile()
--	resource.AddFile( "materials/vgui/ttt/icon_spykr_teargas.vtf" )
--	resource.AddFile( "materials/vgui/ttt/icon_spykr_teargas.vmt" )
else
	SWEP.PrintName = "Tear gas"
	SWEP.Slot = 6
	SWEP.Icon = "VGUI/ttt/icon_spykr_teargas"
	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = [[Throw this grenade in to a crowd to
disorientate and damage your victims.]]
	};
end

SWEP.Base				= "weapon_tttbasegrenade"
SWEP.HoldType			= "grenade"
SWEP.Spawnable 			= true
SWEP.AdminSpawnable		= true
SWEP.Kind 				= WEAPON_EQUIP
SWEP.CanBuy 			= { ROLE_TRAITOR }
SWEP.LimitedStock		= TearGas_Config.LimitedStock
SWEP.detonate_timer 	= TearGas_Config.ExplodeTime

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= Model( "models/weapons/cstrike/c_eq_flashbang.mdl" )
SWEP.WorldModel			= Model( "models/weapons/w_eq_flashbang.mdl" )
SWEP.Weight				= 5
SWEP.AutoSpawnable      = false

function SWEP:Initialize()
	self:SetColor( Color( 0, 150, 0 ) )
	return self.BaseClass.Initialize( self )
end

function SWEP:PreDrawViewModel()
	Material( "models/weapons/v_models/eq_flashbang/flashbang" ):SetVector( "$color2", Vector( 0, 150 / 255, 0 ) )
end

function SWEP:ViewModelDrawn()
	Material( "models/weapons/v_models/eq_flashbang/flashbang" ):SetVector( "$color2", Vector( 1, 1, 1 ) )
end

function SWEP:GetGrenadeName()
	return "ttt_teargas_proj"
end

