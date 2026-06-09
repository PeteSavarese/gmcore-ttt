
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_OTHER

ENT.Hexshield_NoTarget = true

function ENT:SetupDataTables()

	self:NetworkVar( "Entity",	0,	"TargetEntity" )

end

if ( SERVER ) then

	function ENT:Initialize()

		self:SetModel( "models/error.mdl" )
		self:DrawShadow( false )
		self:SetNotSolid( true )

		self:SetMoveType( MOVETYPE_NONE )

	end

end

function ENT:CalcAbsolutePosition( pos, ang )

	local ent = self:GetTargetEntity()

	if ( not IsValid( ent ) ) then return end

	ent:SetNetworkOrigin( pos )
	ent:SetAngles( ang )
	ent:SetAbsVelocity( self:GetVelocity() )

	if ( SERVER ) then

		local physobj = ent:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:EnableMotion( true )
			physobj:SetPos( pos )
			physobj:SetAngles( ang )
			physobj:Wake()
			physobj:EnableMotion( false )

		end

	end

end
