gmcore = gmcore or {}
gmcore.Icon = gmcore.Icon or {}

local PNG_DIMENSIONS = 1024
local ICON_RT_NAME = "ps_icon_render_target"
local MATERIAL_RT_NAME = "ps_material_render_target"
gmcore.Icon.PNG_DIMENSIONS = PNG_DIMENSIONS

---@class gmcoreIconCaptureQueueEntry
---@field modelPath string
---@field itemId string
---@field skinPath number|nil
---@field subMaterials table<number, string>|nil
---@field fCallback function|nil

---@class gmcoreIconMetadataHashEntry

---@type GLIconCaptureQueueEntry[]
local captureQueue = {}
local isCapturing = false

---@class gmcoreMaterialCaptureQueueEntry
---@field materialPath string
---@field itemId string
---@field fCallback function|nil

---@type GLMaterialCaptureQueueEntry[]
local materialQueue = {}
local isMaterialCapturing = false

local function normalizeMaterialPath(path)
	if not path or path == "" then return "" end

	if string.StartWith(path, "materials/") then
		path = path:sub(11)
	end

	local lower = string.lower(path)
	if string.EndsWith(lower, ".vmt") or string.EndsWith(lower, ".vtf") then
		path = path:sub(1, #path - 4)
	end

	return path
end

---Reads json file containing all model and material hashes for
---given icon and updates the internal hash table for that icon.
---@param iconId string Item ID of the icon to update
function gmcore.Icon:UpdateIconHash(iconId)
	if not file.IsDir("gmcore/materials/pointshop/hashes", "DATA") then
		file.CreateDir("gmcore/materials/pointshop/hashes")
	end

	---@type GLIconMetadataHashEntry[]
	local hashFilePath = util.TableToJSON("gmcore/materials/pointshop/hashes/" .. iconId .. ".json")
end

---Queues a model icon PNG generation request, deduplicating and serializing captures.
---@param modelPath string Model path to render
---@param itemId string Item ID used for the filename
---@param isSkin? boolean Whether the icon is for a weapon skin
---@param fCallback? function Called when the PNG is saved
function gmcore.Icon:QueueIconPNG(modelPath, itemId, isSkin, fCallback)
	for _, queued in ipairs(captureQueue) do
		if queued.itemId == itemId then return end
	end

	local skinPath
	local subMaterials

	if isSkin then
		local psItem = PS and PS.Items and PS.Items[itemId] or nil

		if psItem then
			modelPath = psItem.WorldModel or psItem.ViewModel or psItem.Model or modelPath
			if psItem.WorldModel and psItem.WorldMaterials then
				subMaterials = psItem.WorldMaterials
			elseif psItem.ViewModel and psItem.ViewMaterials then
				subMaterials = psItem.ViewMaterials
			end
			if psItem.Skin then
				skinPath = psItem.Skin
			end
		end
	end

	if not modelPath or modelPath == "" then
		return
	end

	table.insert(captureQueue, {
		modelPath = modelPath,
		itemId = itemId,
		skinPath = skinPath,
		subMaterials = subMaterials,
		fCallback = fCallback
	})

	if not isCapturing then
		gmcore.Icon:ProcessNextCapture()
	end
end

---Processes the next item in capture queue. Called automatically after each capture completes.
function gmcore.Icon:ProcessNextCapture()
	if LeyWorkshopDls and not LeyWorkshopDls.alldownloadsdone then
		gmcore.chatprint("Waiting for addons to finish mounting before processing Pointshop icon captures...")

		return
	end

	if #captureQueue == 0 then
		isCapturing = false

		return
	end

	isCapturing = true

	local entry = table.remove(captureQueue, 1)
	gmcore.Icon:GenerateIconPNG(entry.modelPath, entry.itemId, entry.fCallback, entry.skinPath, entry.subMaterials)
end

hook.Add("gmcore.WorkshopDl.AllMounted", "gmcore.IconGenerator.ProcessPostAddonMountQueue", function()
	gmcore.print("All addons mounted. Processing Pointshop icon capture queue...")
	gmcore.Icon:ProcessNextCapture()
	gmcore.Icon:ProcessNextMaterialCapture()
end)

---Renders a model to a PNG file via an off-screen render target.
---@param modelPath string Model path to render
---@param itemId string Item ID used for the filename
---@param fCallback? function Called when the PNG is saved
---@param skinIndex? number Optional model skin index
---@param subMaterials? table<number, string> Optional submaterial overrides
function gmcore.Icon:GenerateIconPNG(modelPath, itemId, fCallback, skinIndex, subMaterials)
	file.CreateDir("gmcore/materials/pointshop/models")

	local container = vgui.Create("DPanel")
	container:SetPos(-PNG_DIMENSIONS, -PNG_DIMENSIONS)
	container:SetSize(PNG_DIMENSIONS, PNG_DIMENSIONS)
	container:SetVisible(false)
	container:SetPaintedManually(true)
	container.Paint = function() end

	local modelPanel = vgui.Create("DModelPanel", container)
	modelPanel:SetSize(PNG_DIMENSIONS, PNG_DIMENSIONS)
	modelPanel:SetModel(modelPath)
	modelPanel:SetPaintedManually(true)

	if not IsValid(modelPanel.Entity) then
		ErrorNoHalt("[Pointshop] Failed to create model entity for: " .. modelPath .. " (" .. itemId .. ")\n")
		container:Remove()

		timer.Simple(0, function() gmcore.Icon:ProcessNextCapture() end)
		if fCallback then fCallback() end

		return
	end

	local mins, maxs = modelPanel.Entity:GetRenderBounds()
	local center = (maxs + mins) / 2
	local distance = mins:Distance(maxs)
	modelPanel:SetCamPos(distance * Vector(0.5, 0.5, 0.5))
	modelPanel:SetLookAt(center)
	modelPanel.LayoutEntity = function() end

	if skinIndex then
		modelPanel.Entity:SetSkin(skinIndex)
	end

	if subMaterials then
		for index, material in pairs(subMaterials) do
			if material and material != "" then
				modelPanel.Entity:SetSubMaterial(index - 1, material)
			end
		end
	end

	hook.Add("PostRender", "PS_IconCapture_" .. itemId, function()
		hook.Remove("PostRender", "PS_IconCapture_" .. itemId)

		if not IsValid(modelPanel) or not IsValid(modelPanel.Entity) then
			ErrorNoHalt("[Pointshop] Model panel became invalid before capture: " .. itemId .. "\n")

			if IsValid(container) then container:Remove() end
			timer.Simple(0, function() gmcore.Icon:ProcessNextCapture() end)

			if fCallback then fCallback() end

			return
		end

		local entity = modelPanel.Entity
		local camPos = modelPanel.vCamPos
		local lookAt = modelPanel.vLookatPos
		local fov = modelPanel.fFOV
		local farZ = modelPanel.FarZ
		local ambientLight = modelPanel.colAmbientLight
		local colColor = modelPanel.colColor
		local alpha = modelPanel:GetAlpha()

		local ang = modelPanel.aLookAngle
		if not ang then
			ang = (lookAt - camPos):Angle()
		end

		local prevClipping = DisableClipping(true)
		local rt = GetRenderTarget(ICON_RT_NAME, PNG_DIMENSIONS, PNG_DIMENSIONS)

		render.PushRenderTarget(rt)
		render.SetWriteDepthToDestAlpha(false)
		render.ClearDepth()
		render.Clear(0, 0, 0, 0)
		render.ClearStencil()

		-- Stencil: mark every pixel the model draws so we can stamp
		-- alpha=255 afterwards. Without this, VertexLitGeneric shaders
		-- write internal data (AO masks, specular, etc.) to the alpha
		-- channel, making parts of the model transparent in the PNG.
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		-- Pass 1: Draw model color and suppress alpha writes.
		render.OverrideAlphaWriteEnable(true, false)

		cam.Start3D(camPos, ang, fov, 0, 0, PNG_DIMENSIONS, PNG_DIMENSIONS, 5, farZ)
			render.SuppressEngineLighting(true)
			render.SetLightingOrigin(entity:GetPos())
			render.ResetModelLighting(ambientLight.r / 255, ambientLight.g / 255, ambientLight.b / 255)
			render.SetColorModulation(colColor.r / 255, colColor.g / 255, colColor.b / 255)
			render.SetBlend((alpha / 255) * (colColor.a / 255))

			for i = 0, 6 do
				local col = modelPanel.DirectionalLight[i]
				if col then
					render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
				end
			end

			entity:DrawModel()
			render.SuppressEngineLighting(false)
		cam.End3D()

		render.OverrideAlphaWriteEnable(false)

		-- Pass 2: Stamp alpha=255 on model pixels via stencil
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.OverrideColorWriteEnable(true, false)
		render.OverrideAlphaWriteEnable(true, true)

		cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(0, 0, PNG_DIMENSIONS, PNG_DIMENSIONS)
		cam.End2D()

		render.OverrideColorWriteEnable(false)
		render.OverrideAlphaWriteEnable(false)
		render.SetStencilEnable(false)

		local data = render.Capture({
			format = "png",
			x = 0,
			y = 0,
			w = PNG_DIMENSIONS,
			h = PNG_DIMENSIONS,
		})

		render.PopRenderTarget()
		DisableClipping(prevClipping)
		container:Remove()

		if data and #data > 0 then
			file.Write("gmcore/materials/pointshop/models/" .. itemId .. ".png", data)
		else
			ErrorNoHalt("[Pointshop] render.Capture returned empty data for: " .. itemId .. "\n")
		end

		if fCallback then fCallback() end
		timer.Simple(0, function() gmcore.Icon:ProcessNextCapture() end)
	end)
end

---Queues a material icon PNG generation request.
---@param materialPath string Material path to render
---@param itemId string Item ID used for the filename
---@param fCallback? function Called when the PNG is saved
function gmcore.Icon:QueueMaterialPNG(materialPath, itemId, fCallback)
	for _, queued in ipairs(materialQueue) do
		if queued.itemId == itemId then return end
	end

	materialPath = normalizeMaterialPath(materialPath)
	if not materialPath or materialPath == "" then return end

	table.insert(materialQueue, {
		materialPath = materialPath,
		itemId = itemId,
		fCallback = fCallback
	})

	if not isMaterialCapturing then
		gmcore.Icon:ProcessNextMaterialCapture()
	end
end

---Processes next material capture in queue.
function gmcore.Icon:ProcessNextMaterialCapture()
	if LeyWorkshopDls and not LeyWorkshopDls.alldownloadsdone then
		gmcore.chatprint("Waiting for addons to finish mounting before processing Pointshop material captures...")

		return
	end

	if #materialQueue == 0 then
		isMaterialCapturing = false

		return
	end

	isMaterialCapturing = true

	local entry = table.remove(materialQueue, 1)
	gmcore.Icon:GenerateMaterialPNG(entry.materialPath, entry.itemId, entry.fCallback)
end

---Renders a material to a PNG file via off-screen render target.
---@param materialPath string Material path to render
---@param itemId string Item ID used for the filename
---@param fCallback? function Called when the PNG is saved
function gmcore.Icon:GenerateMaterialPNG(materialPath, itemId, fCallback)
	file.CreateDir("gmcore/materials/pointshop/materials")

	materialPath = normalizeMaterialPath(materialPath)
	if not materialPath or materialPath == "" then
		timer.Simple(0, function() gmcore.Icon:ProcessNextMaterialCapture() end)
		if fCallback then fCallback() end

		return
	end

	local mat = Material(materialPath, "smooth")
	if not mat or mat:IsError() then
		ErrorNoHalt("[Pointshop] Failed to load material for: " .. materialPath .. " (" .. itemId .. ")\n")

		timer.Simple(0, function() gmcore.Icon:ProcessNextMaterialCapture() end)
		if fCallback then fCallback() end

		return
	end

	hook.Add("PostRender", "PS_MaterialIconCapture_" .. itemId, function()
		hook.Remove("PostRender", "PS_MaterialIconCapture_" .. itemId)

		local rt = GetRenderTarget(MATERIAL_RT_NAME, PNG_DIMENSIONS, PNG_DIMENSIONS)

		render.PushRenderTarget(rt)
		render.SetWriteDepthToDestAlpha(false)
		render.OverrideAlphaWriteEnable(true, true)
		render.Clear(0, 0, 0, 0, true, true)

		cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(mat)
			surface.DrawTexturedRect(0, 0, PNG_DIMENSIONS, PNG_DIMENSIONS)
		cam.End2D()

		local data = render.Capture({
			format = "png",
			x = 0,
			y = 0,
			w = PNG_DIMENSIONS,
			h = PNG_DIMENSIONS,
		})

		render.OverrideAlphaWriteEnable(false)
		render.PopRenderTarget()

		if data and #data > 0 then
			file.Write("gmcore/materials/pointshop/materials/" .. itemId .. ".png", data)
		else
			ErrorNoHalt("[Pointshop] render.Capture returned empty data for material: " .. itemId .. "\n")
		end

		if fCallback then fCallback() end
		timer.Simple(0, function() gmcore.Icon:ProcessNextMaterialCapture() end)
	end)
end

concommand.Add("gmcore_generate_ps_item_png", function(_, _, args)
	local model = args[1]
	local itemId = args[2]

	if not model then
		gmcore.print("No model path was specified to render")

		return
	end

	if not itemId then
		gmcore.print("No item ID was specified to render")

		return
	end

	if not util.IsValidModel(model) then
		gmcore.print(string.format("Model %s does not exist!", model))

		return
	end

	gmcore.Icon:QueueIconPNG(model, itemId)
end)

concommand.Add("gmcore_delete_ps_icons", function()
	local deletedAny = false

	if file.IsDir("gmcore/materials/pointshop/models", "DATA") then
		for _, icon in pairs(file.Find("gmcore/materials/pointshop/models/*", "DATA")) do
			file.Delete("gmcore/materials/pointshop/models/" .. icon)
			gmcore.print(string.format("Deleted PS model icon %s", icon))
			deletedAny = true
		end
	end

	if file.IsDir("gmcore/materials/pointshop/materials", "DATA") then
		for _, icon in pairs(file.Find("gmcore/materials/pointshop/materials/*", "DATA")) do
			file.Delete("gmcore/materials/pointshop/materials/" .. icon)
			gmcore.print(string.format("Deleted PS material icon %s", icon))
			deletedAny = true
		end
	end

	if deletedAny then
		gmcore.print("All PS icons deleted. PS will regenerate icons when reopened")
	end
end, _,
"Deletes all PS icons generated and will regenerate when PS is opened again. Use if model icons are errors or incorrect.")

include("gmcore/modules/icon_generator/cl_icon_generator_menu.lua")
