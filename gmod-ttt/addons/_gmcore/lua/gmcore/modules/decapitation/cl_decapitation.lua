---Client-side blood sprite materials for headshot decapitation effects.
-- These can be accessed without pointing to the IMaterial by using ! before the material string.
function CreateSpriteMaterials()
	local params = {
		["$translucent"] = "1",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1"
	}

	for i = 1, 8 do
		params["$basetexture"] = "Decals/blood" .. i
		CreateMaterial("sprite_bloodspray" .. i, "UnlitGeneric", params)
	end
end

hook.Add("Initialize", "CreateBlood.TTT", function()
	CreateSpriteMaterials()
end)
