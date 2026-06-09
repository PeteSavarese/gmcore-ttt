include("shared.lua")

function ENT:Initialize()
	ParticleEffectAttach("presentstars", 1, self, 1)
end

function ENT:Draw()
	self:DrawModel()
end