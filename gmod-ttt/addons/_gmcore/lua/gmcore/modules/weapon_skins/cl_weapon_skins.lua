if not CLIENT then return end

---Material proxy for tinting knife self-illum based on player's store rank color.
matproxy.Add({
	name = "KnifeRankColor",
	init = function(self, mat, values)
		self.ResultTo = values.resultvar or "$selfillumtint"
		self.Scale = tonumber(values.scale) or 1
		self.Fallback = Vector(1, 1, 1)
	end,
	bind = function(self, mat, ent)
		local ply

		if IsValid(ent) and ent.GetOwner then
			ply = ent:GetOwner()
		end

		if not IsValid(ply) then
			ply = LocalPlayer()
		end

		local v = self.Fallback

		if IsValid(ply) and ply.GetStoreRank and gmcore and gmcore.StoreRank and gmcore.StoreRank.Ranks then
			local rank = ply:GetStoreRank()
			local rankData = gmcore.StoreRank.Ranks[rank]

			if rankData and rank >= 2 and rankData.color then
				local c = rankData.color
				v = Vector((c.r / 255) * self.Scale, (c.g / 255) * self.Scale, (c.b / 255) * self.Scale)
			end
		end

		mat:SetVector(self.ResultTo, v)
	end
})
