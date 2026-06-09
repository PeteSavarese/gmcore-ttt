
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable =		false
ENT.DisableDuplicator =	true

ENT.RenderGroup =	RENDERGROUP_TRANSLUCENT

util.PrecacheSound( "npc/dog/dog_playfull4.wav" )
util.PrecacheSound( "npc/dog/dog_idle4.wav" )

util.PrecacheSound( "weapons/crossbow/hit1.wav" )

util.PrecacheModel( "models/effects/hexshield.mdl" )

ENT.Hexshield_NoTarget = true

-- Inner radius is about	66.571289	(66)
-- Outer radius is about	67.218887	(68)
-- Width is about		 0.647598	 (2)

function HEXSHIELD_MYCLASS( ent )

	return ent:GetClass() == "hexshield"

end

function HEXSHIELD_NOTMYCLASS( ent )

	return ent:GetClass() ~= "hexshield"

end

function ENT:SetupDataTables()

	self:NetworkVar( "Entity",	0,	"Generator" )
	self:NetworkVar( "Bool",	0,	"LocalMode" )
	self:NetworkVar( "Entity",	1,	"TargetActivePlayer" )

	self:NetworkVar( "Vector",	0,	"ShieldColor" )

	self:NetworkVar( "Entity",	2,	"ReflectModel" )

	self:NetworkVar( "Float",	0,	"LightIntensity" )
	self:NetworkVar( "Float",	1,	"LightLerp" )

end

if ( SERVER ) then

	function ENT:Initialize()

		self.Events = {}

		self:SetModel( "models/effects/hexshield.mdl" )
		self:DrawShadow( false )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
		self:SetMoveType( MOVETYPE_NONE )

		self:AddEFlags( EFL_NO_DISSOLVE )

		local physobj = self:GetPhysicsObject()

		if ( IsValid( physobj ) ) then

			physobj:SetMaterial( "glass" )
			physobj:EnableMotion( false )
			physobj:Sleep()

		end

		local reflect = ents.Create( "hexshield_reflect" )
		reflect:SetPos( self:GetPos() )
		reflect:SetAngles( self:GetAngles() )
		reflect:SetParent( self )
		reflect:SetTransmitWithParent( true )
		reflect:Spawn()
		self:SetReflectModel( reflect )

		self:SetCustomCollisionCheck( true )
		self:CollisionRulesChanged()

		self.InitializeTime = CurTime()
		self.Events[ 2 ] = self.StartCollisions

		self.Events[ 4 ] = self.CheckFire

	end

	function ENT:CheckGenerator()

		if ( not IsValid( self:GetGenerator() ) ) then

			self:Expire()

			self.Events[ 1 ] = nil

		end

	end

	function ENT:CheckGenerator_Local()

		if ( not IsValid( self:GetTargetActivePlayer() ) ) or ( not IsValid( self:GetGenerator() ) ) then

			self:ExpireLocal()

			self.Events[ 1 ] = nil

		end

	end

	function ENT:StartCollisions()

		if ( CurTime() <= self.InitializeTime ) then return end

		self.Events[ 2 ] = nil

		self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

	end

	function ENT:DoFlex( reflect, i, f )

		reflect:SetFlexWeight( i, f )

		self:SetFlexWeight( i, f )

	end

	function ENT:Deploy()

		self.DeployTime = CurTime()

		self:EmitSound( "npc/dog/dog_playfull4.wav", 75, 50, 1.0, CHAN_STATIC )
		self:EmitSound( "npc/dog/dog_idle4.wav", 75, 50, 1.0, CHAN_STATIC )

		local reflect = self:GetReflectModel()
		if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 ) end end

		self:SetLightIntensity( 0 )
		self:SetLightLerp( 0 )

		self.Events[ 3 ] = self.Event_Deploy

		self.Events[ 1 ] = self.CheckGenerator

	end

--	0.75
--	0.75 / 20 = 0.0375
--	1 - 0.75 = 0.25

	function ENT:Event_Deploy()

		local f = ( CurTime() - self.DeployTime ) / 1.25

		if ( f < 1 ) then

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 - math.Clamp( ( f - ( i * 0.0375 ) ) / 0.25, 0, 1 ) ) end end

			f = f ^ 0.5
			self:SetLightIntensity( f )
			self:SetLightLerp( f )

		else

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 0 ) end end

			self:SetLightIntensity( 1 )
			self:SetLightLerp( 1 )

			self.Events[ 3 ] = nil

		end

	end

	function ENT:Expire()

		self.ExpireTime = CurTime()

		self.Events[ 3 ] = self.Event_Expire

		self.Events[ 1 ] = nil

	end

	function ENT:Event_Expire()

		local f = ( CurTime() - self.ExpireTime ) / 0.5

		if ( f < 1 ) then

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, f ) end end

			f = ( 1 - f ) ^ 0.5
			self:SetLightIntensity( f )

		else

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 ) end end

			self:SetLightIntensity( 0 )

			self.Events[ 3 ] = nil

			self:Remove()

		end

	end

	function ENT:StartDeployLocal()

		self.DeployTime = CurTime()

		self.LocalEffectCompletion = 0

		self:EmitSound( "npc/dog/dog_playfull4.wav", 75, 50, 1.0, CHAN_STATIC )
		self:EmitSound( "npc/dog/dog_idle4.wav", 75, 50, 1.0, CHAN_STATIC )

		local reflect = self:GetReflectModel()
		if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 ) end end

		self:SetLightIntensity( 0 )
		self:SetLightLerp( 0 )

		self.Events[ 3 ] = self.Event_DeployLocal

		self.Events[ 1 ] = self.CheckGenerator_Local

	end

	function ENT:DeployLocal()

		self.DeployTime = CurTime()

		self.LocalEffectCompletion = math.Clamp( self.LocalEffectCompletion, 0, 1 )

		self.Events[ 3 ] = self.Event_DeployLocal

		self.Events[ 1 ] = self.CheckGenerator_Local

	end

--	0.75
--	0.75 / 20 = 0.0375
--	1 - 0.75 = 0.25

	function ENT:Event_DeployLocal()

		local t = CurTime()
		local f = self.LocalEffectCompletion + ( ( t - self.DeployTime ) / 1.25 )
		self.LocalEffectCompletion = f
		self.DeployTime = t

		if ( f < 1 ) then

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 - math.Clamp( ( f - ( i * 0.0375 ) ) / 0.25, 0, 1 ) ) end end

			f = f ^ 0.5
			self:SetLightIntensity( f )
			self:SetLightLerp( f )

		else

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 0 ) end end

			self:SetLightIntensity( 1 )
			self:SetLightLerp( 1 )

			self.Events[ 3 ] = nil

		end

	end

	function ENT:ExpireLocal()

		self.ExpireTime = CurTime()

		self.LocalEffectCompletion = math.Clamp( self.LocalEffectCompletion, 0, 1 )

		self.Events[ 3 ] = self.Event_ExpireLocal

		self.Events[ 1 ] = nil

	end

	function ENT:Event_ExpireLocal()

		local t = CurTime()
		local f = self.LocalEffectCompletion - ( ( t - self.ExpireTime ) / 1.25 )
		self.LocalEffectCompletion = f
		self.ExpireTime = t

		if ( f > 0 ) then

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 - math.Clamp( ( f - ( i * 0.0375 ) ) / 0.25, 0, 1 ) ) end end

			f = f ^ 0.5
			self:SetLightIntensity( f )
			self:SetLightLerp( f )

		else

			local reflect = self:GetReflectModel()
			if ( IsValid( reflect ) ) then for i = 0, 20 do self:DoFlex( reflect, i, 1 ) end end

			self:SetLightIntensity( 0 )
			self:SetLightLerp( 0 )

			self.Events[ 3 ] = nil

			self:Remove()

		end

	end

	function ENT:CheckFire()

		if ( self:IsOnFire() ) then self:Extinguish() end

	end

	function ENT:OnTick()

		for k, Event in pairs( self.Events ) do Event( self ) end

	end

	hook.Add( "Tick", "hexshield", function()

		for k, ent in pairs( ents.FindByClass( "hexshield" ) ) do ent:OnTick() end

	end )

	local dmg_trace = {}

	util.AddNetworkString( "hexshield_hit" )

	local function IsProjectile( ent )

		if ( not IsValid( ent ) ) then return false end
		if ( ent:IsPlayer() or ent:IsWeapon() ) then return false end

		return ( ent:GetSolid() == SOLID_BBOX ) and ( ent:GetMoveType() == MOVETYPE_FLYGRAVITY )

	end

	function ENT:OnDamaged( info )

		local ent = info:GetInflictor()

		if ( IsProjectile( ent ) ) then

			local hitpos = info:GetDamagePosition()
			local hitforce = info:GetDamageForce()
			local hitnormal = hitforce:GetNormalized()

			local dif = hitpos - self:GetPos()
			dif:Normalize()

			util.TraceLine( { output = dmg_trace, start = hitpos + ( dif * 66.571289 ), endpos = hitpos + ( dif * -66.571289 ), ignoreworld = true, filter = HEXSHIELD_MYCLASS } )
			if ( dmg_trace.Hit ) then hitnormal = dmg_trace.HitNormal end

			net.Start( "hexshield_hit" )
			net.WriteString( ent:GetClass() )
			net.WriteString( tostring( ent:GetPos() ) )
			net.WriteString( tostring( ent:GetAngles() ) )
			net.WriteString( tostring( hitpos ) )
			net.WriteString( tostring( hitforce ) )
			net.WriteString( tostring( hitnormal ) )
			net.Broadcast()

		end

		return true

	end

	local function IsExplosive( ent )

		if ( not IsValid( ent ) ) then return false end
		if ( ent:IsPlayer() or ent:IsWeapon() ) then return false end

		local collision_group = ent:GetCollisionGroup()
		return ( collision_group == COLLISION_GROUP_PROJECTILE ) or ( collision_group == COLLISION_GROUP_WEAPON )

	end

	local function FindDamagePosition( info )

		local ent = info:GetInflictor()

		if ( IsExplosive( ent ) ) then

			local min, max = ent:GetCollisionBounds()

			if ( min ~= max ) then

				min:Add( max )
				min:Mul( 0.5 )

				return ent:LocalToWorld( min )

			end

		end

		return info:GetDamagePosition()

	end

	local function h_EntityTakeDamage( GMMD, ent, info )

		if ( #ents.FindByClass( "hexshield" ) < 1 ) then return end

		if ( HEXSHIELD_MYCLASS( ent ) ) then return ent:OnDamaged( info ) end

		if ( info:GetDamageType() == DMG_FALL ) then return end

		local min, max = ent:GetCollisionBounds()
		min:Add( max )
		min:Mul( 0.5 )

		util.TraceLine( { output = dmg_trace, start = FindDamagePosition( info ), endpos = ent:LocalToWorld( min ), ignoreworld = true, filter = HEXSHIELD_MYCLASS } )

		if ( dmg_trace.Hit ) then return true end

	end

	local o_EntityTakeDamage = NULL

	hook.Add( "Initialize", "hexshield_EntityTakeDamage", function()

		o_EntityTakeDamage = GAMEMODE.EntityTakeDamage

		if ( not isfunction( o_EntityTakeDamage ) ) then GAMEMODE.EntityTakeDamage = h_EntityTakeDamage return end

		GAMEMODE.EntityTakeDamage = function( GMMD, ent, info )

			local h = h_EntityTakeDamage( GMMD, ent, info )
			local o = o_EntityTakeDamage( GMMD, ent, info )

			if ( h or o ) then return true end

		end

	end )

end

if ( CLIENT ) then

	CreateConVar( "cl_hexshieldcolor", "31 0 255", FCVAR_ARCHIVE + FCVAR_USERINFO )

	function ENT:Initialize()

		self:AddEFlags( EFL_NO_DISSOLVE )

		self:SetCustomCollisionCheck( true )
		self:CollisionRulesChanged()

	end

	local Apex = Vector( 30.026077, -60.051880, 0.000006 )

	function ENT:Think()

		local dlight = DynamicLight( self:EntIndex() )

		if ( not dlight ) then return end

		local shield_color = self:GetShieldColor()

		dlight.pos = LerpVector( self:GetLightLerp(), self:LocalToWorld( Apex ), self:GetPos() )
		dlight.r = shield_color.x
		dlight.g = shield_color.y
		dlight.b = shield_color.z
		dlight.brightness = 1
		dlight.decay = 640
		dlight.size = math.Round( self:GetLightIntensity() * 128 )
		dlight.dietime = CurTime() + 1
		dlight.nomodel = false
		dlight.noworld = false
		dlight.style = 0

	end

	local mat_color = Material( "models/effects/hexshield_color" )
	local mat_reflect = Material( "models/effects/hexshield_reflect" )

	function ENT:Draw()

		if ( halo.RenderedEntity() == self ) then return end

		render.UpdateRefractTexture()

		self:DrawModel()

		local shield_color = self:GetShieldColor()

		shield_color.x = shield_color.x / 255
		shield_color.y = shield_color.y / 255
		shield_color.z = shield_color.z / 255
		mat_color:SetVector( "$color2", shield_color )

		local blend = render.GetBlend()
		render.SetBlend( 0.0275 )

			render.MaterialOverride( mat_color )
			self:DrawModel()
			render.MaterialOverride( nil )

		render.SetBlend( blend )

		local reflect = self:GetReflectModel()

		if ( IsValid( reflect ) ) then

			shield_color.x = ( shield_color.x + 1 ) / 2
			shield_color.y = ( shield_color.y + 1 ) / 2
			shield_color.z = ( shield_color.z + 1 ) / 2
			mat_reflect:SetVector( "$envmaptint", shield_color )

			reflect:DrawModel()

		end

	end

	local sparkeffect = EffectData()
	sparkeffect:SetMagnitude( 1 )
	sparkeffect:SetScale( 1 )
	sparkeffect:SetRadius( 1 )

	local projectiles = {}

	net.Receive( "hexshield_hit", function( l )

		local class = net.ReadString()
		local pos = Vector( net.ReadString() )
		local ang = Angle( net.ReadString() )
		local hitpos = Vector( net.ReadString() )
		local hitforce = Vector( net.ReadString() )
		local hitnormal = Vector( net.ReadString() )

		if ( class == "crossbow_bolt" ) then

			local min, max = Vector( -0.161628, -0.671804, -0.668841 ), Vector( 22.008184, 0.667681, 0.670734 )

			local hitstrength = hitforce:Length()
			if ( hitstrength > 0 ) then

				pos:Add( hitforce * ( -21.169812 / hitstrength ) )

			end

			local fake = ents.CreateClientProp( "models/crossbow_bolt.mdl" )
			fake:SetPos( pos )
			fake:SetAngles( ang )
			fake:PhysicsInitBox( min, max )
			fake:SetCollisionBounds( min, max )
			fake:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			fake:SetMoveType( MOVETYPE_VPHYSICS )
			fake:Spawn()

			local physobj = fake:GetPhysicsObject()

			if ( IsValid( physobj ) ) then

				physobj:Wake()
				physobj:SetMaterial( "metal" )
				local r = hitforce - ( hitnormal * ( 2 * hitforce:Dot( hitnormal ) ) )
				r:Mul( 0.0078125 )
				r:Add( Vector( math.Rand( -8, 8 ), math.Rand( -8, 8 ), math.Rand( -8, 8 ) ) )
				physobj:ApplyForceOffset( r, hitpos )

			end

			local n = #projectiles
			if ( n > 31 ) then
				local data = table.remove( projectiles, 1 )
				n = n - 1
				if ( IsValid( data[ 1 ] ) ) then data[ 1 ]:Remove() end
			end
			projectiles[ n + 1 ] = { fake, CurTime() }

			sound.Play( "weapons/crossbow/hit1.wav", hitpos, 75, 100, 1.0 )

		elseif ( class == "hunter_flechette" ) then

			local min, max = Vector( -10.234355, -1.889777, -3.071084 ), Vector( 9.826031, 1.591557, 4.202987 )

			local fake = ents.CreateClientProp( "models/weapons/hunter_flechette.mdl" )
			fake:SetPos( pos )
			fake:SetAngles( ang )
			fake:PhysicsInitBox( min, max )
			fake:SetCollisionBounds( min, max )
			fake:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			fake:SetMoveType( MOVETYPE_VPHYSICS )
			fake:Spawn()

			local physobj = fake:GetPhysicsObject()

			if ( IsValid( physobj ) ) then

				physobj:Wake()
				local r = hitforce - ( hitnormal * ( 2 * hitforce:Dot( hitnormal ) ) )
				r:Mul( 1.5 )
				r:Add( Vector( math.Rand( -8, 8 ), math.Rand( -8, 8 ), math.Rand( -8, 8 ) ) )
				physobj:ApplyForceOffset( r, hitpos )

			end

			local n = #projectiles
			if ( n > 31 ) then
				local data = table.remove( projectiles, 1 )
				n = n - 1
				if ( IsValid( data[ 1 ] ) ) then data[ 1 ]:Remove() end
			end
			projectiles[ n + 1 ] = { fake, CurTime() }

		end

		sparkeffect:SetOrigin( hitpos )
		sparkeffect:SetNormal( hitnormal )
		util.Effect( "cball_bounce", sparkeffect )

	end )

	hook.Add( "Think", "hexshield_hit_projectiles", function()

		local n = #projectiles
		if ( n < 1 ) then return end

		local t = CurTime()

		local i = 1
		while ( i <= n ) do

			local data = projectiles[ i ]

			if ( not IsValid( data[ 1 ] ) ) then

				table.remove( projectiles, i )
				n = n - 1

			elseif ( ( t - data[ 2 ] ) >= 16 ) then

				data[ 1 ]:Remove()

				table.remove( projectiles, i )
				n = n - 1

			else

				i = i + 1

			end

		end

	end )

	function ENT:ImpactTrace( tr, damage, name )

		sparkeffect:SetOrigin( tr.HitPos )
		sparkeffect:SetNormal( tr.HitNormal )
		util.Effect( "cball_bounce", sparkeffect )

	end

end

function ENT:CanTool( ply, trace, name )

	return false

end

function ENT:CanProperty( ply, name )

	return false

end

local function h_PhysgunPickup( GMMD, ply, ent )

	return HEXSHIELD_NOTMYCLASS( ent )

end

local o_PhysgunPickup = NULL

hook.Add( "Initialize", "hexshield_PhysgunPickup", function()

	o_PhysgunPickup = GAMEMODE.PhysgunPickup

	if ( not isfunction( o_PhysgunPickup ) ) then GAMEMODE.PhysgunPickup = h_PhysgunPickup return end

	GAMEMODE.PhysgunPickup = function( GMMD, ply, ent )

		local h = h_PhysgunPickup( GMMD, ply, ent )
		local o = o_PhysgunPickup( GMMD, ply, ent )

		if ( h and o ) then return true end

	end

end )

local function h_CanPlayerUnfreeze( GMMD, ply, ent, physobj )

	return HEXSHIELD_NOTMYCLASS( ent )

end

local o_CanPlayerUnfreeze = NULL

hook.Add( "Initialize", "hexshield_CanPlayerUnfreeze", function()

	o_CanPlayerUnfreeze = GAMEMODE.CanPlayerUnfreeze

	if ( not isfunction( o_CanPlayerUnfreeze ) ) then GAMEMODE.CanPlayerUnfreeze = h_CanPlayerUnfreeze return end

	GAMEMODE.CanPlayerUnfreeze = function( GMMD, ply, ent )

		local h = h_CanPlayerUnfreeze( GMMD, ply, ent )
		local o = o_CanPlayerUnfreeze( GMMD, ply, ent )

		if ( h and o ) then return true end

	end

end )

local function h_EntityFireBullets( GMMD, ent, data )

	local func = data.Callback
	if ( not isfunction( func ) ) then return end
	if ( not ent:IsPlayer() ) and ( not ent:IsNPC() ) then return end
	local wep = ent:GetActiveWeapon()
	if ( not IsValid( wep ) ) or ( not wep.Penetration ) then return end

	data.Callback = function( attacker, tr, info )

		if ( IsValid( wep ) ) and ( wep.Penetration ) then

			if ( HEXSHIELD_MYCLASS( tr.Entity ) ) then

				wep.Penetration = false

					func( attacker, tr, info )

				wep.Penetration = true

				return

			end

		end

		func( attacker, tr, info )

	end

	return true

end

local o_EntityFireBullets = NULL

hook.Add( "Initialize", "hexshield_EntityFireBullets", function()

	o_EntityFireBullets = GAMEMODE.EntityFireBullets

	if ( not isfunction( o_EntityFireBullets ) ) then GAMEMODE.EntityFireBullets = h_EntityFireBullets return end

	GAMEMODE.EntityFireBullets = function( GMMD, ent, data )

		local h = h_EntityFireBullets( GMMD, ent, data )
		local o = o_EntityFireBullets( GMMD, ent, data )

		if ( h == nil ) then return o end
		if ( o == nil ) then return h end

		return ( h and o )

	end

end )

function ENT:ShouldCollide( ent )

	if ( ent:IsWorld() ) then return false end

	if ( HEXSHIELD_MYCLASS( ent ) ) then return false end

	local generator = self:GetGenerator()

	if ( IsValid( generator ) ) and ( not self:GetLocalMode() ) then

		local surfaceentity = generator:GetSurfaceEntity()

		if ( IsValid( surfaceentity ) ) then

			if ( ent == surfaceentity ) then return false end

		elseif ( surfaceentity:IsWorld() and generator:GetIsAttached() ) then

			return true

		end

	end

	if ( ent:IsNPC() or ent:IsPlayer() ) then return true end
	local owner = ent:GetOwner()
	if ( IsValid( owner ) ) and ( owner:IsNPC() or owner:IsPlayer() ) then return true end
	for k, child in pairs( ent:GetChildren() ) do if ( child:IsNPC() or child:IsPlayer() ) then return true end end

	if ( ent:GetSolid() == SOLID_VPHYSICS ) and ( ent:GetMoveType() == MOVETYPE_VPHYSICS ) then return ( ent:GetVelocity():Length() > 120 ) end

	return ( ent:GetVelocity():Length() > 0 )

end

local function h_ShouldCollide( GMMD, enta, entb )

	return ( ( not isfunction( enta.ShouldCollide ) ) or enta:ShouldCollide( entb ) ) and ( ( not isfunction( entb.ShouldCollide ) ) or entb:ShouldCollide( enta ) )

end

local o_ShouldCollide = NULL

hook.Add( "Initialize", "hexshield_ShouldCollide", function()

	o_ShouldCollide = GAMEMODE.ShouldCollide

	if ( not isfunction( o_ShouldCollide ) ) then GAMEMODE.ShouldCollide = h_ShouldCollide return end

	GAMEMODE.ShouldCollide = function( GMMD, enta, entb )

		local h = h_ShouldCollide( GMMD, enta, entb )
		local o = o_ShouldCollide( GMMD, enta, entb )

		return ( h and o )

	end

end )
