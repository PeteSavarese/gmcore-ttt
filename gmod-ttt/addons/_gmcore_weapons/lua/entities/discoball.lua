AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"

ENT.Author = "RedBull"
ENT.PrintName = "Disco Ball"
ENT.Category = "Fun + Games"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Model = Model("models/props/gl/disco.mdl")

ENT.RenderGroup = RENDERGROUP_BOTH

local matLight = Material("sprites/light_ignorez")
local matBeam = Material("effects/lamp_beam")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	--self:SetColor(Color(0, 0, 0))

	if CLIENT then
		self.PixVis = util.GetPixelVisibleHandle()
	end

	if SERVER then
		self.flashlight = ents.Create("env_projectedtexture")
		self.flashlight:SetParent(self)
		self.flashlight:SetLocalPos(Vector(0, 0, 0))
		self.flashlight:SetLocalAngles(Angle(90, 0, 0))
		self.flashlight:SetKeyValue("enableshadows", 0)
		self.flashlight:SetKeyValue("farz", 1000)
		self.flashlight:SetKeyValue("nearz", 12)
		self.flashlight:SetKeyValue("lightfov", 100)
		self.flashlight:Spawn()
		self.flashlight:Input("SpotlightTexture", NULL, NULL, "effects/flashlight/caustics")
	end
end

if CLIENT then
	function ENT:DrawTranslucent()
		BaseClass.DrawTranslucent(self)

		local LightNrm = self:GetAngles():Up()
		local ViewNormal = self:GetPos() - EyePos()
		local Distance = ViewNormal:Length()

		ViewNormal:Normalize()

		local ViewDot = ViewNormal:Dot(LightNrm * -1)
		local LightPos = self:GetPos() + LightNrm * 5

		-- glow sprite
		render.SetMaterial(matBeam)

		local BeamDot = 0.25
		local r, g, b = 255 * math.abs(math.sin(CurTime())), 255 * math.abs(math.sin(CurTime() + 1.8)), 255 * math.abs(math.sin(CurTime() + 2.6))

		render.StartBeam(3)
			render.AddBeam(LightPos + LightNrm * 1, 128, 0.0, Color(r, g, b, 255 * BeamDot))
			render.AddBeam(LightPos - LightNrm * 50, 128, 0.5, Color(r, g, b, 64 * BeamDot))
			render.AddBeam(LightPos - LightNrm * 150, 128, 1, Color(r, g, b, 0))
		render.EndBeam()
	end
end

if SERVER then
	function ENT:Think()
		local r, g, b = 255 * math.abs(math.sin(CurTime())), 255 * math.abs(math.sin(CurTime() + 1.8)), 255 * math.abs(math.sin(CurTime() + 2.6))
		self.flashlight:SetKeyValue("lightcolor", r .. " " .. g .. " " .. b .. " 2000")
	end
end
