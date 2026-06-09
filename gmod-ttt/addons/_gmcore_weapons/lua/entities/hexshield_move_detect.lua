
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_OTHER

ENT.Hexshield_NoTarget = true

if ( SERVER ) then

	function ENT:Initialize()

		self:SetModel( "models/error.mdl" )
		self:DrawShadow( false )
		self:SetNotSolid( true )

		self:SetMoveType( MOVETYPE_NONE )

	end

end

function ENT:CalcAbsolutePosition( pos, ang )

	local ent = self:GetParent()

	if ( IsValid( ent ) ) then return ent:On_CalcAbsolutePosition( pos, ang ) end

end
