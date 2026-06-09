local blur = Material("pp/blurscreen")
local MAT_GRADIENT_L = Material("vgui/gradient-l")

---Draws a blur effect behind a panel.
---@param panel Panel Panel to draw the blur effect behind
---@param amount number? Blur amount (default 6)
function surface.DrawBlur(panel, amount)
	local x, y = panel:LocalToScreen(0, 0)
	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(blur)

	for i = 1, 3 do
		blur:SetFloat("$blur", (i / 3) * (amount or 6))
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
	end
end

--- Draws a horizontal left→right gradient clipped to a rounded rectangle.
---@param x number
---@param y number
---@param w number
---@param h number
---@param radius number Corner radius
---@param colLeft Color Left edge color
---@param colRight Color Right edge color
function surface.DrawRoundedGradient(x, y, w, h, radius, colLeft, colRight)
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_NEVER)
		render.SetStencilFailOperation(STENCIL_REPLACE)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.ClearStencil()

		draw.RoundedBox(radius, x, y, w, h, color_white)

		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilPassOperation(STENCIL_KEEP)

		surface.SetDrawColor(colRight)
		surface.DrawRect(x, y, w, h)
		surface.SetMaterial(MAT_GRADIENT_L)
		surface.SetDrawColor(colLeft)
		surface.DrawTexturedRect(x, y, w, h)
	render.SetStencilEnable(false)
end
