if SERVER then return end

gmcore = gmcore or {}
gmcore.Icon = gmcore.Icon or {}

local ICON_SIZE = gmcore.Icon.PNG_DIMENSIONS or 1024
local CUSTOM_RT_NAME = "ps_custom_icon_render_target"

local BOX_TOP_IDX = BOX_TOP or 1
local BOX_FRONT_IDX = BOX_FRONT or 4
local BOX_RIGHT_IDX = BOX_RIGHT or 5

local DEFAULT_MODEL = "models/props_c17/oildrum001.mdl"

local function isValidModel(path)
	return path and path ~= "" and util.IsValidModel(path)
end

-- Fonts

local FONT_SECTION_HEADER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 22,
	weight = 600,
	antialias = true,
})

local FONT_SUBMAT_INDEX = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 16,
	weight = 600,
	antialias = true,
})

local FONT_SUBMAT_PATH = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 14,
	weight = 400,
	antialias = true,
})

-- UI Helpers

local function createHeader(parent, text)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont(FONT_SECTION_HEADER)
	label:SetTextColor(CARD_TITLE_TEXT_COLOR)
	label:SizeToContents()
	label:SetTall(label:GetTall() + 4)

	return label
end

local function createSpacer(parent, height)
	local spacer = vgui.Create("DPanel", parent)
	spacer:SetTall(height or 4)
	spacer.Paint = nil

	return spacer
end

local function createButton(parent, text, onClick)
	local btn = vgui.Create("GmcoreButton", parent)
	btn:SetTall(28)
	btn:SetText(text)

	if onClick then
		btn.DoClick = onClick
	end

	return btn
end

local function createTextRow(parent, labelText, initial)
	local row = vgui.Create("DPanel", parent)
	row:SetTall(26)
	row.Paint = nil

	local label = vgui.Create("DLabel", row)
	label:Dock(LEFT)
	label:SetWide(110)
	label:SetText(labelText)
	label:SizeToContentsX()
	label:SetContentAlignment(4)

	local entry = vgui.Create("GmcoreTextInput", row)
	entry:Dock(FILL)
	entry:SetValue(initial or "")

	return entry
end

local function createNumberRow(parent, labelText, initial, minVal, maxVal, onChange)
	local row = vgui.Create("DPanel", parent)
	row:SetTall(26)
	row.Paint = nil

	local label = vgui.Create("DLabel", row)
	label:Dock(LEFT)
	label:SetWide(110)
	label:SetText(labelText)
	label:SizeToContentsX()
	label:SetContentAlignment(4)

	local wang = vgui.Create("GmcoreNumberWang", row)
	wang:Dock(FILL)
	wang:SetDecimals(2)
	wang:SetMinMax(minVal or -10000, maxVal or 10000)
	wang:SetValue(initial or 0)

	if onChange then
		wang.OnValueChanged = function(_, val)
			onChange(tonumber(val) or 0)
		end
	end

	return wang
end

local function createVectorRow(parent, labelText, vector, minVal, maxVal, onChange)
	local row = vgui.Create("DPanel", parent)
	row:SetTall(26)
	row.Paint = nil

	local label = vgui.Create("DLabel", row)
	label:Dock(LEFT)
	label:SetWide(110)
	label:SetText(labelText)
	label:SetContentAlignment(4)

	local function makeWang()
		local w = vgui.Create("GmcoreNumberWang", row)
		w:SetWide(62)
		w:SetDecimals(2)
		w:SetMinMax(minVal or -10000, maxVal or 10000)

		return w
	end

	local wangX = makeWang()
	wangX:Dock(LEFT)
	wangX:DockMargin(0, 0, 4, 0)
	wangX:SetValue(vector.x or 0)

	local wangY = makeWang()
	wangY:Dock(LEFT)
	wangY:DockMargin(0, 0, 4, 0)
	wangY:SetValue(vector.y or 0)

	local wangZ = makeWang()
	wangZ:Dock(LEFT)
	wangZ:SetValue(vector.z or 0)

	local function handleChange()
		if onChange then
			onChange(Vector(wangX:GetValue(), wangY:GetValue(), wangZ:GetValue()))
		end
	end

	wangX.OnValueChanged = handleChange
	wangY.OnValueChanged = handleChange
	wangZ.OnValueChanged = handleChange

	return {
		x = wangX,
		y = wangY,
		z = wangZ,
	}
end

---Captures the current model panel state to a PNG file, including submaterial overrides.
---@param panel DModelPanel Model panel to capture from
---@param outputId string Filename (without extension) to save under
---@param subMaterials table<number, string>|nil Submaterial overrides (1-based index -> material path)
---@param bodyGroups table<number, number>|nil Bodygroup overrides (bodygroup id -> value)
---@param fCallback fun(success: boolean)|nil Called when capture completes
local function captureFromPanel(panel, outputId, subMaterials, bodyGroups, fCallback)
	if not IsValid(panel) or not IsValid(panel.Entity) then
		if fCallback then fCallback(false) end

		return
	end

	local entity = panel.Entity
	local camPos = panel.vCamPos or Vector(50, 50, 50)
	local lookAt = panel.vLookatPos or Vector(0, 0, 0)
	local fov = panel.fFOV or 45
	local farZ = panel.FarZ or 1024
	local ambientLight = panel.colAmbientLight or Color(255, 255, 255)
	local colColor = panel.colColor or Color(255, 255, 255)
	local alpha = panel:GetAlpha() or 255
	local dirLights = panel.DirectionalLight or {}

	local ang = panel.aLookAngle
	if not ang then
		ang = (lookAt - camPos):Angle()
	end

	local container = vgui.Create("DPanel")
	container:SetPos(-ICON_SIZE, -ICON_SIZE)
	container:SetSize(ICON_SIZE, ICON_SIZE)
	container:SetVisible(false)
	container:SetPaintedManually(true)
	container.Paint = function() end

	local capturePanel = vgui.Create("DModelPanel", container)
	capturePanel:SetSize(ICON_SIZE, ICON_SIZE)
	capturePanel:SetModel(entity:GetModel())
	capturePanel:SetPaintedManually(true)
	capturePanel.LayoutEntity = function() end

	if IsValid(capturePanel.Entity) then
		capturePanel.Entity:SetAngles(entity:GetAngles())
		capturePanel.Entity:SetModelScale(entity:GetModelScale(), 0)
		capturePanel.Entity:SetSkin(entity:GetSkin())

		if subMaterials then
			for index, matPath in pairs(subMaterials) do
				if matPath and matPath ~= "" then
					capturePanel.Entity:SetSubMaterial(index - 1, matPath)
				end
			end
		end

		if bodyGroups then
			for id, val in pairs(bodyGroups) do
				capturePanel.Entity:SetBodygroup(id, val)
			end
		end
	end

	capturePanel:SetCamPos(camPos)
	capturePanel:SetLookAt(lookAt)
	capturePanel:SetFOV(fov)
	capturePanel:SetAmbientLight(ambientLight)
	capturePanel:SetDirectionalLight(BOX_TOP_IDX, dirLights[BOX_TOP_IDX] or Color(255, 255, 255))
	capturePanel:SetDirectionalLight(BOX_FRONT_IDX, dirLights[BOX_FRONT_IDX] or Color(255, 255, 255))
	capturePanel:SetDirectionalLight(BOX_RIGHT_IDX, dirLights[BOX_RIGHT_IDX] or Color(255, 255, 255))

	hook.Add("PostRender", "PS_CustomIconCapture_" .. outputId, function()
		hook.Remove("PostRender", "PS_CustomIconCapture_" .. outputId)

		if not IsValid(capturePanel) or not IsValid(capturePanel.Entity) then
			if IsValid(container) then container:Remove() end
			if fCallback then fCallback(false) end

			return
		end

		local prevClipping = DisableClipping(true)
		local rt = GetRenderTarget(CUSTOM_RT_NAME, ICON_SIZE, ICON_SIZE)

		render.PushRenderTarget(rt)
		render.SetWriteDepthToDestAlpha(false)
		render.ClearDepth()
		render.Clear(0, 0, 0, 0)
		render.ClearStencil()

		-- Use stencil to mark every pixel the model draws. This lets us
		-- stamp alpha=255 on model pixels only, avoiding the Source Engine
		-- issue where VertexLitGeneric shaders write internal data (AO masks
		-- specular, etc.) to the framebuffer alpha channel instead
		-- of a solid 255 which causes parts of the model to render
		-- partially or fully transparent in the captured PNG.
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		-- Pass 1: Draw model color. Disable alpha writes so the shader's
		-- internal alpha values don't leak into the framebuffer.
		render.OverrideAlphaWriteEnable(true, false)

		cam.Start3D(camPos, ang, fov, 0, 0, ICON_SIZE, ICON_SIZE, 5, farZ)
			render.SuppressEngineLighting(true)
			render.SetLightingOrigin(capturePanel.Entity:GetPos())
			render.ResetModelLighting(ambientLight.r / 255, ambientLight.g / 255, ambientLight.b / 255)
			render.SetColorModulation(colColor.r / 255, colColor.g / 255, colColor.b / 255)
			render.SetBlend((alpha / 255) * (colColor.a / 255))

			for i = 0, 6 do
				local col = dirLights[i]

				if col then
					render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
				end
			end

			capturePanel.Entity:DrawModel()
			render.SuppressEngineLighting(false)
		cam.End3D()

		render.OverrideAlphaWriteEnable(false)

		-- Pass 2: Stamp alpha=255 on every pixel the model touched (stencil == 1).
		-- Only write alpha, leave colour untouched.
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.OverrideColorWriteEnable(true, false)
		render.OverrideAlphaWriteEnable(true, true)

		cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(0, 0, ICON_SIZE, ICON_SIZE)
		cam.End2D()

		render.OverrideColorWriteEnable(false)
		render.OverrideAlphaWriteEnable(false)
		render.SetStencilEnable(false)

		local data = render.Capture({
			format = "png",
			x = 0,
			y = 0,
			w = ICON_SIZE,
			h = ICON_SIZE,
		})
		render.PopRenderTarget()
		DisableClipping(prevClipping)
		container:Remove()

		if data and #data > 0 then
			file.CreateDir("gmcore/materials/pointshop/models")
			file.Write("gmcore/materials/pointshop/models/" .. outputId .. ".png", data)

			if fCallback then fCallback(true) end
		else
			ErrorNoHalt("[Pointshop] render.Capture returned empty data for custom icon: " .. outputId .. "\n")

			if fCallback then fCallback(false) end
		end
	end)
end

-- Menu

function gmcore.Icon:OpenGeneratorMenu()
	if IsValid(self._iconGeneratorMenu) then
		self._iconGeneratorMenu:Remove()
	end

	local frame = vgui.Create("GmcoreFrame")
	frame:SetSize(1200, 720)
	frame:SetTitle("Pointshop Icon Generator")
	frame:Center()
	frame:MakePopup()
	frame:SetSizable(true)
	frame:SetMinWidth(980)
	frame:SetMinHeight(620)
	self._iconGeneratorMenu = frame

	local body = vgui.Create("GmcorePanel", frame)
	body:Dock(FILL)
	body:DockPadding(10, 10, 10, 10)

	local controls = vgui.Create("GmcorePanelList", body)
	controls:Dock(LEFT)
	controls:SetWide(360)
	controls:DockMargin(0, 0, 12, 0)
	controls:EnableVerticalScrollbar(true)
	controls:SetSpacing(6)
	controls:SetPadding(8)

	local preview = vgui.Create("GmcorePanel", body)
	preview:Dock(FILL)

	local modelPanel = vgui.Create("DModelPanel", preview)
	modelPanel:Dock(FILL)
	modelPanel:DockMargin(6, 6, 6, 6)
	modelPanel:SetModel(DEFAULT_MODEL)
	modelPanel:SetAmbientLight(Color(60, 60, 60))
	modelPanel:SetDirectionalLight(BOX_TOP_IDX, Color(255, 255, 255))
	modelPanel:SetDirectionalLight(BOX_FRONT_IDX, Color(200, 200, 200))
	modelPanel:SetDirectionalLight(BOX_RIGHT_IDX, Color(100, 100, 100))

	-- State

	local state = {
		modelPath = DEFAULT_MODEL,
		outputId = "custom_icon",
		camPos = Vector(50, 50, 50),
		lookAt = Vector(0, 0, 0),
		fov = 45,
		angle = Angle(0, 0, 0),
		scale = 1,
		skin = 0,
		ambient = Color(60, 60, 60),
		lightTop = Color(255, 255, 255),
		lightFront = Color(200, 200, 200),
		lightRight = Color(100, 100, 100),
		subMaterials = {},
		originalMats = {},
		bodygroups = {},
	}

	local updating = false
	local camPosInputs, lookAtInputs, fovInput
	local anglesInputs, scaleInput, skinInput
	local modelEntry, outputEntry
	local focusInputs = {}
	local subMatWidgets = {}

	local function registerFocusInput(panel)
		if not IsValid(panel) then return end

		table.insert(focusInputs, panel)
	end

	local function isEditingInputs()
		local focus = vgui.GetKeyboardFocus()

		if not IsValid(focus) then return false end

		for _, panel in ipairs(focusInputs) do
			if focus == panel then return true end
		end

		return false
	end

	-- Helpers

	local function applyCamera()
		if updating then return end

		modelPanel:SetCamPos(state.camPos)
		modelPanel:SetLookAt(state.lookAt)
		modelPanel:SetFOV(state.fov)
	end

	local function applyLighting()
		modelPanel:SetAmbientLight(state.ambient)
		modelPanel:SetDirectionalLight(BOX_TOP_IDX, state.lightTop)
		modelPanel:SetDirectionalLight(BOX_FRONT_IDX, state.lightFront)
		modelPanel:SetDirectionalLight(BOX_RIGHT_IDX, state.lightRight)
	end

	local function applySubmaterials()
		if not IsValid(modelPanel.Entity) then return end

		for i = 0, math.max(#state.originalMats - 1, 0) do
			modelPanel.Entity:SetSubMaterial(i, "")
		end

		for index, matPath in pairs(state.subMaterials) do
			if matPath and matPath ~= "" then
				modelPanel.Entity:SetSubMaterial(index - 1, matPath)
			end
		end
	end

	local function applyBodygroups()
		if not IsValid(modelPanel.Entity) then return end

		for id, val in pairs(state.bodygroups) do
			modelPanel.Entity:SetBodygroup(id, val)
		end
	end

	local function applyEntity()
		if not IsValid(modelPanel.Entity) then return end

		modelPanel.Entity:SetAngles(state.angle)
		modelPanel.Entity:SetModelScale(state.scale, 0)
		modelPanel.Entity:SetSkin(state.skin)

		applySubmaterials()
		applyBodygroups()
	end

	local function fitCamera()
		if not IsValid(modelPanel.Entity) then return end

		local mins, maxs = modelPanel.Entity:GetRenderBounds()
		local center = (maxs + mins) / 2
		local distance = mins:Distance(maxs)
		modelPanel:SetCamPos(distance * Vector(0.5, 0.5, 0.5))
		modelPanel:SetLookAt(center)
		modelPanel.LayoutEntity = function() end

		state.camPos = modelPanel:GetCamPos()
		state.lookAt = modelPanel:GetLookAt()

		updating = true

		if camPosInputs then
			camPosInputs.x:SetValue(state.camPos.x)
			camPosInputs.y:SetValue(state.camPos.y)
			camPosInputs.z:SetValue(state.camPos.z)
		end

		if lookAtInputs then
			lookAtInputs.x:SetValue(state.lookAt.x)
			lookAtInputs.y:SetValue(state.lookAt.y)
			lookAtInputs.z:SetValue(state.lookAt.z)
		end

		updating = false
	end

	---Repopulate every text/number field from the current state + entity.
	---Safe to call any time after the entity is valid.
	local function syncAllInputsFromState()
		if not IsValid(modelPanel.Entity) then return end
		updating = true

		-- Derive output ID from the model filename (strip dir + .mdl)
		if IsValid(outputEntry) then
			local derived = state.modelPath:match("([^/\\]+)%.mdl$") or state.outputId

			outputEntry:SetValue(derived)
			state.outputId = derived
		end

		-- Camera
		if camPosInputs then
			camPosInputs.x:SetValue(state.camPos.x)
			camPosInputs.y:SetValue(state.camPos.y)
			camPosInputs.z:SetValue(state.camPos.z)
		end

		if lookAtInputs then
			lookAtInputs.x:SetValue(state.lookAt.x)
			lookAtInputs.y:SetValue(state.lookAt.y)
			lookAtInputs.z:SetValue(state.lookAt.z)
		end

		if IsValid(fovInput) then
			fovInput:SetValue(state.fov)
		end

		-- Transform (read back from entity so we always reflect reality)
		local ang   = modelPanel.Entity:GetAngles()
		local scale = modelPanel.Entity:GetModelScale()
		local skin  = modelPanel.Entity:GetSkin()
		state.angle = ang
		state.scale = scale
		state.skin  = skin

		if anglesInputs then
			anglesInputs.x:SetValue(ang.p)
			anglesInputs.y:SetValue(ang.y)
			anglesInputs.z:SetValue(ang.r)
		end

		if IsValid(scaleInput) then scaleInput:SetValue(scale) end
		if IsValid(skinInput)  then skinInput:SetValue(skin)   end

		-- (lighting wangs are not stored as upvalues so we just reapply)
		applyLighting()

		updating = false
	end

	local function getPanelCamPos()
		return modelPanel.vCamPos or Vector(0, 0, 0)
	end

	local function getPanelLookAt()
		return modelPanel.vLookatPos or Vector(0, 0, 0)
	end

	local function vecDifferent(a, b)
		if not a or not b then return true end

		return a:DistToSqr(b) > 0.01
	end

	local function syncCameraFromPanel()
		if updating or isEditingInputs() then return end

		local camPos = getPanelCamPos()
		local lookAt = getPanelLookAt()
		local fov = modelPanel.fFOV or state.fov

		updating = true

		if camPos and vecDifferent(camPos, state.camPos) then
			state.camPos = camPos

			if camPosInputs then
				camPosInputs.x:SetValue(camPos.x)
				camPosInputs.y:SetValue(camPos.y)
				camPosInputs.z:SetValue(camPos.z)
			end
		end

		if lookAt and vecDifferent(lookAt, state.lookAt) then
			state.lookAt = lookAt

			if lookAtInputs then
				lookAtInputs.x:SetValue(lookAt.x)
				lookAtInputs.y:SetValue(lookAt.y)
				lookAtInputs.z:SetValue(lookAt.z)
			end
		end

		if fov and math.abs(fov - state.fov) > 0.01 then
			state.fov = fov

			if fovInput then
				fovInput:SetValue(fov)
			end
		end

		updating = false
	end

	local subMatSectionPanels = {}
	local bodyGroupSectionPanels = {}

	local function collectSubMatOverrides()
		for i, entry in pairs(subMatWidgets) do
			if IsValid(entry) then
				local val = entry:GetValue()
				state.subMaterials[i] = (val ~= "" and val or nil)
			end
		end
	end

	local function buildSubmaterialRows()
		for _, child in ipairs(subMatSectionPanels) do
			if IsValid(child) then child:Remove() end
		end

		subMatSectionPanels = {}
		subMatWidgets = {}

		if not IsValid(modelPanel.Entity) then return end

		local mats = modelPanel.Entity:GetMaterials()
		if not mats or #mats == 0 then return end

		state.originalMats = mats
		state.subMaterials = {}

		local function addToSection(panel)
			controls:AddItem(panel)
			table.insert(subMatSectionPanels, panel)
		end

		addToSection(createSpacer(controls))
		addToSection(createHeader(controls, "Submaterials (" .. #mats .. ")"))

		for i, matPath in ipairs(mats) do
			local infoRow = vgui.Create("DPanel", controls)
			infoRow:SetTall(18)
			infoRow.Paint = nil

			local indexLabel = vgui.Create("DLabel", infoRow)
			indexLabel:Dock(LEFT)
			indexLabel:SetWide(30)
			indexLabel:SetText("[" .. i .. "]")
			indexLabel:SetFont(FONT_SUBMAT_INDEX)
			indexLabel:SetTextColor(PRIMARY_ACCENT_COLOR)
			indexLabel:SetContentAlignment(4)

			local pathLabel = vgui.Create("DLabel", infoRow)
			pathLabel:Dock(FILL)
			pathLabel:SetText(matPath)
			pathLabel:SetFont(FONT_SUBMAT_PATH)
			pathLabel:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
			pathLabel:SetContentAlignment(4)
			pathLabel:SetTooltip(matPath)

			addToSection(infoRow)

			local overrideRow = vgui.Create("DPanel", controls)
			overrideRow:SetTall(26)
			overrideRow.Paint = nil

			local entry = vgui.Create("GmcoreTextInput", overrideRow)
			entry:Dock(FILL)
			entry:SetValue("")

			subMatWidgets[i] = entry

			local idx = i
			entry:GetInputPanel().OnEnter = function()
				local val = entry:GetValue()

				state.subMaterials[idx] = (val ~= "" and val or nil)
				applySubmaterials()
			end

			addToSection(overrideRow)
			registerFocusInput(entry:GetInputPanel())
		end

		local applyBtn = createButton(controls, "Apply Submaterials", function()
			collectSubMatOverrides()
			applySubmaterials()
			gmcore.Notify("Submaterial overrides applied.", 2, gmcore.NotifyType.INFO)
		end)
		addToSection(applyBtn)

		local clearBtn = createButton(controls, "Clear Submaterials", function()
			state.subMaterials = {}
			applySubmaterials()

			for _, entry in pairs(subMatWidgets) do
				if IsValid(entry) then entry:SetValue("") end
			end
		end)

		addToSection(clearBtn)
	end

	local function buildBodygroupRows()
		for _, child in ipairs(bodyGroupSectionPanels) do
			if IsValid(child) then child:Remove() end
		end

		bodyGroupSectionPanels = {}
		bodyGroupWidgets = {}

		if not IsValid(modelPanel.Entity) then return end

		local groups = modelPanel.Entity:GetBodyGroups()
		if not groups or #groups == 0 then return end

		-- Only show groups with more than one option
		local usable = {}
		for _, g in ipairs(groups) do
			if g.num > 1 then
				table.insert(usable, g)
			end
		end

		if #usable == 0 then return end

		state.bodygroups = {}

		local function addToSection(panel)
			controls:AddItem(panel)
			table.insert(bodyGroupSectionPanels, panel)
		end

		addToSection(createSpacer(controls))
		addToSection(createHeader(controls, "Bodygroups (" .. #usable .. ")"))

		for _, g in ipairs(usable) do
			local gId = g.id
			local gNum = g.num
			local wang = createNumberRow(controls, g.name, 0, 0, gNum - 1, function(val)
				local v = math.max(0, math.min(gNum - 1, math.floor(val)))
				state.bodygroups[gId] = v
				applyBodygroups()
			end)

			controls:AddItem(wang:GetParent())
			registerFocusInput(wang:GetInputPanel())
			bodyGroupWidgets[gId] = wang
		end
	end

	-- Model section
	controls:AddItem(createHeader(controls, "Model"))

	modelEntry = createTextRow(controls, "Model path", state.modelPath)
	controls:AddItem(modelEntry:GetParent())
	registerFocusInput(modelEntry:GetInputPanel())
	modelEntry:GetInputPanel().OnChange = function()
		if not IsValid(outputEntry) then return end
		local path = modelEntry:GetValue()
		local derived = path:match("([^/\\]+)%.mdl$")
		if derived then outputEntry:SetValue(derived) end
	end

	outputEntry = createTextRow(controls, "Output id", state.outputId)
	controls:AddItem(outputEntry:GetParent())
	registerFocusInput(outputEntry:GetInputPanel())

	controls:AddItem(createButton(controls, "Load Model", function()
		local path = modelEntry:GetValue()
		if not isValidModel(path) then
			gmcore.Notify("Invalid model path: " .. tostring(path), 3, gmcore.NotifyType.WARN)

			return
		end

		state.modelPath = path
		state.subMaterials = {}
		modelPanel:SetModel(path)

		timer.Simple(0, function()
			if not IsValid(modelPanel) then return end

			fitCamera()
			applyEntity()
			applyLighting()
			syncAllInputsFromState()
			buildSubmaterialRows()
			buildBodygroupRows()
		end)
	end))

	controls:AddItem(createButton(controls, "Fit Camera", function()
		fitCamera()
	end))

	-- Camera section
	controls:AddItem(createSpacer(controls))
	controls:AddItem(createHeader(controls, "Camera"))

	camPosInputs = createVectorRow(controls, "Cam pos", state.camPos, -5000, 5000, function(vec)
		state.camPos = vec
		applyCamera()
	end)
	controls:AddItem(camPosInputs.x:GetParent())
	registerFocusInput(camPosInputs.x:GetInputPanel())
	registerFocusInput(camPosInputs.y:GetInputPanel())
	registerFocusInput(camPosInputs.z:GetInputPanel())

	lookAtInputs = createVectorRow(controls, "Look at", state.lookAt, -5000, 5000, function(vec)
		state.lookAt = vec
		applyCamera()
	end)
	controls:AddItem(lookAtInputs.x:GetParent())
	registerFocusInput(lookAtInputs.x:GetInputPanel())
	registerFocusInput(lookAtInputs.y:GetInputPanel())
	registerFocusInput(lookAtInputs.z:GetInputPanel())

	fovInput = createNumberRow(controls, "FOV", state.fov, 5, 120, function(val)
		state.fov = val
		applyCamera()
	end)
	controls:AddItem(fovInput:GetParent())
	registerFocusInput(fovInput:GetInputPanel())

	-- Transform section
	controls:AddItem(createSpacer(controls))
	controls:AddItem(createHeader(controls, "Transform"))

	anglesInputs = createVectorRow(controls, "Angles (P/Y/R)", Vector(state.angle.p, state.angle.y, state.angle.r), -180, 180, function(vec)
		state.angle = Angle(vec.x, vec.y, vec.z)
		applyEntity()
	end)
	controls:AddItem(anglesInputs.x:GetParent())
	registerFocusInput(anglesInputs.x:GetInputPanel())
	registerFocusInput(anglesInputs.y:GetInputPanel())
	registerFocusInput(anglesInputs.z:GetInputPanel())

	scaleInput = createNumberRow(controls, "Scale", state.scale, 0.1, 5, function(val)
		state.scale = val
		applyEntity()
	end)
	controls:AddItem(scaleInput:GetParent())
	registerFocusInput(scaleInput:GetInputPanel())

	skinInput = createNumberRow(controls, "Skin", state.skin, 0, 32, function(val)
		state.skin = math.max(0, math.floor(val))
		applyEntity()
	end)
	controls:AddItem(skinInput:GetParent())
	registerFocusInput(skinInput:GetInputPanel())

	-- Lighting section
	controls:AddItem(createSpacer(controls))
	controls:AddItem(createHeader(controls, "Lighting"))

	local ambientRow = createVectorRow(controls, "Ambient", Vector(state.ambient.r, state.ambient.g, state.ambient.b), 0, 255, function(vec)
		state.ambient = Color(vec.x, vec.y, vec.z)
		applyLighting()
	end)
	controls:AddItem(ambientRow.x:GetParent())
	registerFocusInput(ambientRow.x:GetInputPanel())
	registerFocusInput(ambientRow.y:GetInputPanel())
	registerFocusInput(ambientRow.z:GetInputPanel())

	local topRow = createVectorRow(controls, "Top light", Vector(state.lightTop.r, state.lightTop.g, state.lightTop.b), 0, 255, function(vec)
		state.lightTop = Color(vec.x, vec.y, vec.z)
		applyLighting()
	end)
	controls:AddItem(topRow.x:GetParent())
	registerFocusInput(topRow.x:GetInputPanel())
	registerFocusInput(topRow.y:GetInputPanel())
	registerFocusInput(topRow.z:GetInputPanel())

	local frontRow = createVectorRow(controls, "Front light", Vector(state.lightFront.r, state.lightFront.g, state.lightFront.b), 0, 255, function(vec)
		state.lightFront = Color(vec.x, vec.y, vec.z)
		applyLighting()
	end)
	controls:AddItem(frontRow.x:GetParent())
	registerFocusInput(frontRow.x:GetInputPanel())
	registerFocusInput(frontRow.y:GetInputPanel())
	registerFocusInput(frontRow.z:GetInputPanel())

	local rightRow = createVectorRow(controls, "Right light", Vector(state.lightRight.r, state.lightRight.g, state.lightRight.b), 0, 255, function(vec)
		state.lightRight = Color(vec.x, vec.y, vec.z)
		applyLighting()
	end)
	controls:AddItem(rightRow.x:GetParent())
	registerFocusInput(rightRow.x:GetInputPanel())
	registerFocusInput(rightRow.y:GetInputPanel())
	registerFocusInput(rightRow.z:GetInputPanel())

	buildSubmaterialRows()
	buildBodygroupRows()

	-- Generate section
	controls:AddItem(createSpacer(controls))
	controls:AddItem(createHeader(controls, "Generate"))

	controls:AddItem(createButton(controls, "Generate PNG", function()
		local outputId = outputEntry:GetValue()
		if not outputId or outputId == "" then
			gmcore.Notify("Output id is required.", 3, gmcore.NotifyType.WARN)

			return
		end

		if not IsValid(modelPanel.Entity) then
			gmcore.Notify("No valid model loaded.", 3, gmcore.NotifyType.WARN)

			return
		end

		collectSubMatOverrides()
		state.outputId = outputId
		captureFromPanel(modelPanel, outputId, state.subMaterials, state.bodygroups, function(success)
			if success then
				gmcore.Notify("Icon saved: data/gmcore/materials/pointshop/models/" .. outputId .. ".png", 3, gmcore.NotifyType.INFO)
			else
				gmcore.Notify("Failed to generate icon.", 3, gmcore.NotifyType.WARN)
			end
		end)
	end))

	-- Camera sync via DModelPanel Think
	local baseThink = modelPanel.Think
	modelPanel.Think = function(s, ...)
		if baseThink then baseThink(s, ...) end

		syncCameraFromPanel()
	end
end

concommand.Add("gmcore_icon_generator_menu", function()
	gmcore.Icon:OpenGeneratorMenu()
end)
