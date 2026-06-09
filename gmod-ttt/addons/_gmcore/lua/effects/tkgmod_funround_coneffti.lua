function EFFECT:Init(data)
	local vOffset = data:GetOrigin()

	local emitter = ParticleEmitter(vOffset, true)

	local particles = 150
	for i = 0, particles do

		local pos = Vector(math.Rand(-5, 5), math.Rand(-5, 5), math.Rand(-5, 5))

		local particle = emitter:Add("particles/balloon_bit", vOffset + pos * 8)
		if particle then
			particle:SetVelocity(pos * 5)

			particle:SetLifeTime(0)
			particle:SetDieTime(5)

			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)

			local size = math.Rand(1, 4)
			particle:SetStartSize(size)
			particle:SetEndSize(0)

			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(math.Rand(-2, 2))

			particle:SetAirResistance(10)
			particle:SetGravity(Vector(0, 0, -300))

			particle:SetColor(math.random(255), math.random(255), math.random(255))

			particle:SetColor(67, 15, 15)

			particle:SetCollide(true)

			particle:SetBounce(0.1)
			particle:SetLighting(false)
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
