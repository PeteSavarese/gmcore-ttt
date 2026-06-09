
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_OTHER

ENT.Hexshield_NoTarget = true

if ( SERVER ) then

	function ENT:Initialize()

		local min, max = Vector( -1, -1, -1 ), Vector( 1, 1, 1 )

		self:SetModel( "models/error.mdl" )
		self:DrawShadow( false )
		self:PhysicsInitBox( min, max )
		self:SetCollisionBounds( min, max )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

		local physobj = self:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:SetMass( 0.1 )
			physobj:EnableGravity( false )
			physobj:EnableMotion( false )

		end

	end

end
