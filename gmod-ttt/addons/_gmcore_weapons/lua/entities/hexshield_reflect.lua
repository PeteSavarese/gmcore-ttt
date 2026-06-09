
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_OTHER

util.PrecacheModel( "models/effects/hexshield_b.mdl" )

ENT.Hexshield_NoTarget = true

if ( SERVER ) then

	function ENT:Initialize()

		self:SetModel( "models/effects/hexshield_b.mdl" )
		self:DrawShadow( false )
		self:SetNotSolid( true )

	end

end
