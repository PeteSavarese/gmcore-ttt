
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_BOTH

local snd = false

if ( IsMounted( "ep2" ) ) then

	snd = true

	util.PrecacheSound( "npc/ministrider/flechette_impact_stick1.wav" )
	util.PrecacheSound( "npc/ministrider/flechette_impact_stick2.wav" )
	util.PrecacheSound( "npc/ministrider/flechette_impact_stick3.wav" )
	util.PrecacheSound( "npc/ministrider/flechette_impact_stick4.wav" )
	util.PrecacheSound( "npc/ministrider/flechette_impact_stick5.wav" )

else

	util.PrecacheSound( "physics/metal/sawblade_stick1.wav" )
	util.PrecacheSound( "physics/metal/sawblade_stick2.wav" )
	util.PrecacheSound( "physics/metal/sawblade_stick3.wav" )

end

util.PrecacheSound( "ambient/machines/zap1.wav" )
util.PrecacheSound( "ambient/machines/zap2.wav" )
util.PrecacheSound( "ambient/machines/zap3.wav" )

util.PrecacheModel( "models/weapons/w_hexshield_grenade.mdl" )

ENT.Hexshield_NoTarget = true

function ENT:SetupDataTables()

	self:NetworkVar( "Entity",	0,	"Shield" )
	self:NetworkVar( "Entity",	1,	"SurfaceEntity" )
	self:NetworkVar( "Bool",	0,	"IsAttached" )

	self:NetworkVar( "Vector",	0,	"ShieldPos" )
	self:NetworkVar( "Angle",	0,	"ShieldAng" )

	self:NetworkVar( "Vector",	1,	"ShieldColor" )

end

if ( SERVER ) then

	function ENT:Initialize()

		self.Events = {}

		self:SetModel( "models/weapons/w_hexshield_grenade.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

		local physobj = self:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:SetDamping( 0, 0 )

		end

		local shield_color = self:GetShieldColor()
		shield_color = Color( shield_color.x, shield_color.y, shield_color.z )

		self.Trail_top = util.SpriteTrail( self, self:LookupAttachment( "top" ), shield_color, true, 2, 0, 0.25, 0.5, "effects/beam_generic01.vmt" )
		self.Trail_bottom = util.SpriteTrail( self, self:LookupAttachment( "bottom" ), shield_color, true, 2, 0, 0.25, 0.5, "effects/beam_generic01.vmt" )

		self.TestCollisions = true

	end

	local target_ent = NULL
	local target_rank = 1
	local target_dist = 64
	local target_pos = vector_origin

	function ENT:GetEntityPos_Static( ent, selfpos, HitPos, HitNormal )

		if ( not IsValid( ent ) ) or ( ent.Hexshield_NoTarget ) or ( ent:IsWeapon() ) or ( ( ent:GetSolid() == SOLID_NONE ) and ( ent:GetMoveType() == MOVETYPE_NONE ) ) then return end

		local min, max = ent:GetCollisionBounds()

		if ( min == max ) then return end

		local width = min:Distance( max )

		if ( width > 128 ) then return end

		min:Add( max )
		min:Mul( 0.5 )

		local center = ent:LocalToWorld( min )
		local dist = center:Distance( selfpos )

		if ( dist > 64 ) then return end

		local normal = center - HitPos
		normal:Normalize()

		if ( HitNormal:Dot( normal ) <= 0 ) then return end

		local rank = 1

		if ( ent:IsPlayer() ) then
			rank = 3
		elseif ( ent:IsNPC() ) then
			rank = 2
		elseif ( width < 16 ) then
			return
		end

		if ( rank > target_rank ) or ( ( rank == target_rank ) and ( dist < target_dist ) ) then

			target_ent = ent
			target_rank = rank
			target_dist = dist
			target_pos = center

		end

	end

	function ENT:GetEntityPos_Dynamic( ent, selfpos )

		if ( not IsValid( ent ) ) or ( ent.Hexshield_NoTarget ) or ( ent:IsWeapon() ) or ( ( ent:GetSolid() == SOLID_NONE ) and ( ent:GetMoveType() == MOVETYPE_NONE ) ) then return end

		local min, max = ent:GetCollisionBounds()

		if ( min == max ) then return end

		local width = min:Distance( max )

		if ( width > 128 ) then return end

		min:Add( max )
		min:Mul( 0.5 )

		local center = ent:LocalToWorld( min )
		local dist = center:Distance( selfpos )

		if ( dist > 64 ) then return end

		local rank = 1

		if ( ent:IsPlayer() ) then
			rank = 3
		elseif ( ent:IsNPC() ) then
			rank = 2
		elseif ( width < 16 ) then
			return
		end

		if ( rank > target_rank ) or ( ( rank == target_rank ) and ( dist < target_dist ) ) then

			target_ent = ent
			target_rank = rank
			target_dist = dist
			target_pos = center

		end

	end

	function ENT:FindEntityAndGetPos_Static( selfpos, selfang )

		local HitPos, HitAng = LocalToWorld( self.HitPos, self.HitAng, selfpos, selfang )
		local HitNormal = HitAng:Forward()

		target_ent = self
		target_rank = 1
		target_dist = 64
		target_pos = selfpos

		for k, ent in pairs( ents.GetAll() ) do

			self:GetEntityPos_Static( ent, selfpos, HitPos, HitNormal )

		end

		if ( target_ent == self ) then

			HitNormal:Mul( 36.410477 )
			HitPos:Add( HitNormal )

			return HitPos

		end

		return target_pos

	end

	function ENT:FindEntityAndGetPos_Dynamic( selfpos, selfang )

		target_ent = self
		target_rank = 1
		target_dist = 64
		target_pos = selfpos

		for k, ent in pairs( ents.GetAll() ) do

			self:GetEntityPos_Dynamic( ent, selfpos )

		end

		if ( target_ent == self ) then

			local HitPos, HitAng = LocalToWorld( self.HitPos, self.HitAng, selfpos, selfang )
			local HitNormal = HitAng:Forward()

			HitNormal:Mul( 36.410477 )
			HitPos:Add( HitNormal )

			return HitPos

		end

		return target_pos

	end

	function ENT:FindEntityAndGetPos( selfpos, selfang )

		local ent = self:GetSurfaceEntity()

		if ( IsValid( ent ) ) then

			local min, max = ent:GetCollisionBounds()

			if ( min ~= max ) and ( min:Distance( max ) <= 128 ) then

				return self:FindEntityAndGetPos_Dynamic( selfpos, selfang )

			end

		end

		return self:FindEntityAndGetPos_Static( selfpos, selfang )

	end

	local function GetPhysicsObjectIndex( self ) -- WHY DOES THIS FUNCTION NOT EXIST????

		local ent = self:GetEntity()

		if ( IsValid( ent ) ) then

			for i = 0, ent:GetPhysicsObjectCount() - 1 do

				if ( ent:GetPhysicsObjectNum( i ) == self ) then return i end

			end

		end

		return 0

	end

	function ENT:PhysicsCollide( data, physobj )

		if ( not self.TestCollisions ) then return end

		if ( data.Speed < 64 ) then return end

		if ( HEXSHIELD_MYCLASS( data.HitEntity ) ) then return end

		if ( data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() ) and ( data.HitEntity:GetSolid() ~= SOLID_VPHYSICS ) and ( data.HitEntity:GetMoveType() ~= MOVETYPE_VPHYSICS ) then return end

		self.TestCollisions = false

		data.HitBone = GetPhysicsObjectIndex( data.HitObject )
		self.CollisionData = data
		self.Events[ 1 ] = self.Collided

	end

	function ENT:Weld( ent, bone )

		return constraint.Weld( self, ent, 0, bone, 4095, true, false )

	end

	local function hexshield_weld( self )

		local ent = self.HexshieldGrenade

		if ( IsValid( ent ) ) then ent:WeldRemoved() end

	end

	function ENT:WeldCreated( Constraint )

		self:SetIsAttached( true )

		Constraint.HexshieldGrenade = self

		Constraint:CallOnRemove( "hexshield_weld", hexshield_weld )

	end

	local removeeffect = EffectData()
	removeeffect:SetMagnitude( 1 )
	removeeffect:SetScale( 1 )
	removeeffect:SetRadius( 1 )

	function ENT:WeldRemoved()

		self:SetIsAttached( false )

		if ( self.DisableWeld ) then return end

		local HitPos, HitAng = LocalToWorld( self.HitPos, self.HitAng, self:GetPos(), self:GetAngles() )

		sound.Play( "ambient/machines/zap"..math.random( 1, 3 )..".wav", HitPos, 75, 125, 0.25 )

		removeeffect:SetOrigin( HitPos )
		removeeffect:SetNormal( HitAng:Forward() )
		util.Effect( "ManhackSparks", removeeffect )

	end

	function ENT:AttachEntity( selfpos, selfang, data )

		local ent = data.HitEntity

		if ( IsValid( ent ) ) then

			self:SetSurfaceEntity( ent )

			if ( ent:GetMoveType() == MOVETYPE_VPHYSICS ) then

				local Constraint = self:Weld( ent, data.HitBone )

				if ( Constraint ) and ( Constraint:IsValid() ) then

					self:WeldCreated( Constraint )

					return

				end

			end

			local follow = ents.Create( "hexshield_move_attach" ) -- I need to figure out a way to make an entity follow a specific physics object.
			follow:SetMoveType( MOVETYPE_NONE )
			follow:SetPos( selfpos )
			follow:SetAngles( selfang )
			follow:SetParent( ent )
			follow:Spawn()

			local anchor = ents.Create( "hexshield_move_anchor" )
			anchor:SetPos( selfpos )
			anchor:SetAngles( selfang )
			anchor:Spawn()

			follow:DeleteOnRemove( anchor )
			anchor:DeleteOnRemove( follow )

			follow:SetTargetEntity( anchor )

			local Constraint = self:Weld( anchor, 0 )

			if ( Constraint ) and ( Constraint:IsValid() ) then

				Constraint:DeleteOnRemove( anchor )

				self:WeldCreated( Constraint )

			else

				anchor:Remove()

			end

		elseif ( ent:IsWorld() ) then

			self:SetSurfaceEntity( ent )

			local anchor = ents.Create( "hexshield_move_anchor" )
			anchor:SetPos( selfpos )
			anchor:SetAngles( selfang )
			anchor:Spawn()

			local Constraint = self:Weld( anchor, 0 )

			if ( Constraint ) and ( Constraint:IsValid() ) then

				Constraint:DeleteOnRemove( anchor )

				self:WeldCreated( Constraint )

			else

				anchor:Remove()

			end

		end

	end

	function ENT:Collided()

		local data = self.CollisionData

		self:SetCollisionGroup( COLLISION_GROUP_WORLD )

		local physobj = self:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:SetDamping( 15, 15 )

		end

		local selfpos = self:GetPos()
		local selfang = self:GetAngles()

		local detect = ents.Create( "hexshield_move_detect" )
		detect:SetMoveType( MOVETYPE_NONE )
		detect:SetPos( selfpos )
		detect:SetAngles( selfang )
		detect:SetParent( self )
		detect:Spawn()
		detect:DeleteOnRemove( self )

		self:AttachEntity( selfpos, selfang, data )

		self.DeployTime = CurTime() + 0.8

		self.Events[ 1 ] = self.Event_Deploy

		data.HitNormal:Mul( -1 )

		self.HitPos, self.HitAng = WorldToLocal( data.HitPos, data.HitNormal:Angle(), selfpos, selfang )

		if ( snd ) then
			sound.Play( "npc/ministrider/flechette_impact_stick"..math.random( 1, 5 )..".wav", data.HitPos, 75, 100, 1.0 )
		else
			sound.Play( "physics/metal/sawblade_stick"..math.random( 1, 3 )..".wav", data.HitPos, 75, 100, 1.0 )
		end
		sound.Play( "ambient/machines/zap"..math.random( 1, 3 )..".wav", data.HitPos, 75, 125, 0.25 )

	end

	util.AddNetworkString( "hexshield_grenade_drawfunc" )

	function ENT:Event_Deploy()
		if (CurTime() < self.DeployTime) then return end
		self.ExpireTime = CurTime() + 32
		self.Events[1] = self.Event_Expire

		net.Start("hexshield_grenade_drawfunc")
		net.WriteEntity(self)
		net.WriteInt(2, 3)
		net.Broadcast()

		local selfpos = self:GetPos()
		local selfang = self:GetAngles()

		local pos = self:FindEntityAndGetPos(selfpos, selfang)
		local lpos, lang = WorldToLocal(pos, angle_zero, selfpos, selfang)

		self:SetShieldPos(lpos)
		self:SetShieldAng(lang)

		local ent = ents.Create("hexshield")
		ent:SetPos(pos)
		ent:SetAngles(angle_zero)
		ent:SetShieldColor(self:GetShieldColor())
		ent:Spawn()
		ent:SetGenerator(self)

		self:SetShield(ent)

		ent:Deploy()

		self.ShieldActive = true
	end

	function ENT:Expire()
		self.PickupTime = CurTime() + 0.5
		local physobj = self:GetPhysicsObject()

		if (IsValid(physobj)) then
			physobj:SetDamping(0, 0)
		end

		if (IsValid(self.Trail_top)) then
			self.Trail_top:Remove()
		end

		if (IsValid(self.Trail_bottom)) then
			self.Trail_bottom:Remove()
		end

		net.Start("hexshield_grenade_drawfunc")
		net.WriteEntity(self)
		net.WriteInt(3, 3)
		net.Broadcast()

		self:Remove()
	end

	function ENT:Event_Expire()
		local ent = self:GetShield()

		if (IsValid(ent)) then
			if (CurTime() < self.ExpireTime) then return end
			self:Expire()
			ent:Expire()
			self.ShieldActive = false
		else
			self:Expire()
			self.ShieldActive = false
		end
	end

	function ENT:Event_Pickup()

		if ( CurTime() < self.PickupTime ) then return end

		self.Events[ 1 ] = nil

		self.DisableWeld = true

		local wep = ents.Create( "weapon_hexshield" )
		wep:SetPos( self:GetPos() )
		wep:SetAngles( self:GetAngles() )
		wep:Spawn()
		wep:Activate()

		self:Remove()

	end

	function ENT:OnTick()

		for k, Event in pairs( self.Events ) do Event( self ) end

	end

	hook.Add( "Tick", "hexshield_grenade", function()

		for k, ent in pairs( ents.FindByClass( "hexshield_grenade" ) ) do ent:OnTick() end

	end )

end

if ( CLIENT ) then

	function ENT:Initialize()

		self.DrawFuncs =	{
						self.DrawNormal,
						self.DrawDeployed,
						self.DrawExpired
					}

		self.DrawTranslucent = self.DrawNormal

	end

	net.Receive( "hexshield_grenade_drawfunc", function( l )

		local ent = net.ReadEntity()
		local i = net.ReadInt( 3 )

		if ( not IsValid( ent ) ) then return end

		ent.DrawTranslucent = ent.DrawFuncs[ i ] or ent.DrawTranslucent

	end )

	local refract = Material( "effects/hexshield/hexshield_r1" )
	local spritemat = Material( "sprites/light_ignorez" )

	function ENT:Draw()

		self:DrawModel()

	end

	function ENT:DrawNormal()

		local shield_color = self:GetShieldColor()
		shield_color = Color( shield_color.x, shield_color.y, shield_color.z )

		self:Draw()

		local posang = self:GetAttachment( self:LookupAttachment( "top" ) )

		if ( not istable( posang ) ) then return end

		local t_pos = posang.Pos

		posang = self:GetAttachment( self:LookupAttachment( "bottom" ) )

		if ( not istable( posang ) ) then return end

		local b_pos = posang.Pos

		render.SetMaterial( spritemat )
		render.DrawSprite( t_pos, 4, 4, shield_color )

		render.SetMaterial( spritemat )
		render.DrawSprite( b_pos, 4, 4, shield_color )

	end

	function ENT:DrawDeployed()

		local shield_color = self:GetShieldColor()
		shield_color = Color( shield_color.x, shield_color.y, shield_color.z )

		self:Draw()

		local posang = self:GetAttachment( self:LookupAttachment( "top" ) )

		if ( not istable( posang ) ) then return end

		local t_pos = posang.Pos

		posang = self:GetAttachment( self:LookupAttachment( "bottom" ) )

		if ( not istable( posang ) ) then return end

		local b_pos = posang.Pos

		local t = CurTime()

		local i = ( math.sin( t * 8 ) + 1 ) + ( ( math.sin( t * 4 ) + 1 ) * 2 )

		refract:SetFloat( "$refractamount", i * 0.003 )

		local size = ( i + 32 ) * 0.25

		render.UpdateRefractTexture()

		render.SetMaterial( refract )
		render.DrawSprite( t_pos, size, size, color_white )
		render.DrawSprite( b_pos, size, size, color_white )

		render.SetMaterial( spritemat )
		render.DrawSprite( t_pos, size, size, shield_color )
		render.DrawSprite( b_pos, size, size, shield_color )

	end

	function ENT:DrawExpired()

		self:Draw()

	end

end

function ENT:On_CalcAbsolutePosition( selfpos, selfang )

	local ent = self:GetShield()

	if ( not IsValid( ent ) ) then return end

	local pos, ang = LocalToWorld( self:GetShieldPos(), self:GetShieldAng(), selfpos, selfang )
	ang.p, ang.r = 0, 0

	ent:SetNetworkOrigin( pos )
	ent:SetAngles( ang )
	ent:SetAbsVelocity( self:GetVelocity() )

	if ( SERVER ) then

		local physobj = ent:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:SetPos( pos )
			physobj:SetAngles( ang )
			physobj:Wake()

		end

	end

end
