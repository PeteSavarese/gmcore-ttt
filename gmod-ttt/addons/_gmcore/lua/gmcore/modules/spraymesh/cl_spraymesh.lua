local FONT_SPRAY_SIDEBAR = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 18,
	weight = 600,
	antialias = true,
})

local FONT_SPRAY_SECTION_HEADER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 22,
	weight = 600,
	antialias = true,
})

local SPRAY_PANEL_BORDER = FRAME_BORDER_COLOR

---SprayMesh client-side rendering. Handles spray placement, mesh generation, HTML texture loading, and the spray menu.
Sprays = Sprays or {}
Sprays.Menu = {}

--
-- Create ConVars
--
local CVAR_ENABLE_SPRAYS = CreateClientConVar("spraymesh_enablesprays", "1", true, false, "Whether or not to show all player sprays.", 0, 1)
local CVAR_ENABLE_ANIMATED_SPRAYS = CreateClientConVar("spraymesh_enableanimated", "1", true, false, "Whether or not to show animated sprays.", 0, 1)
CreateClientConVar("spraymesh_url", spraymesh.SPRAY_URL_DEFAULT, true, true, "The URL to use for your spray.")

--
-- Clientside variables and such
--

-- Used by the client to render sprays in order
-- Done so sprays can be "overwritten", and also for performance
spraymesh.RENDER_ITER_CLIENT = spraymesh.RENDER_ITER_CLIENT or {}

setmetatable(spraymesh.SPRAYDATA, {
		-- Reset render iteration table cache when the main spraymesh table is modified
		__newindex = function(tb, key, value)
				rawset(tb, key, value)

				spraymesh.RENDER_ITER_CLIENT = nil
		end,
})

-- Whether or not we're currently rendering names over player sprays (via spraymesh_shownames)
local SPRAY_SHOWING_NAMES = false

-- Sprays that need to be reloaded will be put in here
local SPRAY_RELOAD_QUEUE = {}

---Reloads all currently placed sprays by removing them and queuing for re-placement.
function spraymesh.ReloadSprays()
		spraymesh.RemoveSprays()

		for id64, data in pairs(spraymesh.SPRAYDATA) do
				SPRAY_RELOAD_QUEUE[id64] = data
		end
end

---Queues a single spray for reload.
---@param id64 string SteamID64 of the spray owner
function spraymesh.ReloadSpray(id64)
		if not spraymesh.SPRAYDATA[id64] then return end

		SPRAY_RELOAD_QUEUE[id64] = spraymesh.SPRAYDATA[id64]
end

---Removes a player's spray mesh and clears their spray data.
---@param id64 string SteamID64 of the spray owner
function spraymesh.RemoveSpray(id64)
		if not spraymesh.SPRAYDATA[id64] then return end

		local meshData = spraymesh.SPRAYDATA[id64].meshdata
		if meshData and meshData.mesh and IsValid(meshData.mesh) then
				meshData.mesh:Destroy()
				meshData.mesh = nil
		end

		spraymesh.SPRAYDATA[id64] = nil
end

-- URL material solver
local imats = {}

-- Where panels are during loading
local htmlpanels = {}

-- Where panels are for animation, after loading
local htmlpanelsanim = {}

local RT_SPRAY_PENDING = GetRenderTargetEx(
		"spraymesh_pending_spray",
		spraymesh.IMAGE_RESOLUTION,
		spraymesh.IMAGE_RESOLUTION,
		RT_SIZE_DEFAULT,
		MATERIAL_RT_DEPTH_SEPARATE,
		bit.bor(4, 8, 16, 256),
		0,
		IMAGE_FORMAT_BGR888
)

local MAT_SPRAY_PENDING = CreateMaterial("spraymesh/pending_spray_placeholder", "UnlitGeneric", {
		["$basetexture"] = RT_SPRAY_PENDING:GetName(),

		-- Allows custom coloring
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$model"] = 1,
		["$nocull"] = 1,
		["$receiveflashlight"] = 1
})

local RT_SPRAY_DISABLEDVIDEO = GetRenderTargetEx(
		"spraymesh_disabled_video",
		spraymesh.IMAGE_RESOLUTION,
		spraymesh.IMAGE_RESOLUTION,
		RT_SIZE_DEFAULT,
		MATERIAL_RT_DEPTH_SEPARATE,
		bit.bor(4, 8, 16, 256),
		0,
		IMAGE_FORMAT_BGR888
)

local RT_SPRAY_DISABLEDSPRAY = GetRenderTargetEx(
		"spraymesh_disabled_spray",
		spraymesh.IMAGE_RESOLUTION,
		spraymesh.IMAGE_RESOLUTION,
		RT_SIZE_DEFAULT,
		MATERIAL_RT_DEPTH_SEPARATE,
		bit.bor(4, 8, 16, 256),
		0,
		IMAGE_FORMAT_BGR888
)

---Creates an HTML panel to render a spray image or video, then passes the resulting material via callback.
---@param url string Sanitized URL
---@param urloriginal string Original URL
---@param steamID string SteamID64
---@param playerName string Name of the player who owns the spray
---@param callback fun(panel: Panel)
local function generateHTMLPanel(url, urloriginal, steamID, playerName, callback)
		if not string.find(url, "^https?://", 0, false) then
				url = "https://" .. url
		end

		spraymesh.DebugPrint("Generating HTML panel: ", url)

		-- Use spray image resolution from config
		local size = spraymesh.IMAGE_RESOLUTION

		-- Persisting container, for cutting short anims but also drawing an overlay
		local panelContainer = {}

		local panelHTML = vgui.Create("DHTML")
		panelHTML:SetSize(size, size)
		panelHTML:SetAllowLua(false)
		panelHTML:SetAlpha(0)
		panelHTML:SetMouseInputEnabled(false)
		panelHTML:SetScrollbars(false)
		panelHTML.ConsoleMessage = function(panel, msg)
				spraymesh.DebugPrint("HTML ConsoleMessage: " .. tostring(msg))
		end

		panelContainer.panel = panelHTML

		-- Set image/video HTML for the panel
		spraymesh.HTMLHandlers.Get(url, size, steamID, playerName, panelContainer)
		panelContainer.origurl = urloriginal
		panelContainer.callback = callback

		panelContainer.IsAnimated = (spraymesh.GetURLInfo(urloriginal) == SPRAYTYPE_VIDEO or string.EndsWith(urloriginal, ".gif"))

		panelContainer.RT = GetRenderTargetEx(
				"SprayMesh_URL_" .. util.SHA256(url),
				size,
				size,
				RT_SIZE_DEFAULT,
				MATERIAL_RT_DEPTH_SEPARATE,
				bit.bor(4, 8, 16, 256),
				0,
				IMAGE_FORMAT_BGRA8888
		)

		function panelContainer:PaintSpray()
				if not self.FinalMaterial then return end

				-- If sprays aren't enabled AT ALL
				if not CVAR_ENABLE_SPRAYS:GetBool() then
						self.FinalMaterial:SetTexture("$basetexture", RT_SPRAY_DISABLEDSPRAY)

						return
				end

				-- If animated sprays aren't enabled
				if self.IsAnimated and not CVAR_ENABLE_ANIMATED_SPRAYS:GetBool() then
						self.FinalMaterial:SetTexture("$basetexture", RT_SPRAY_DISABLEDVIDEO)

						return
				end

				-- If spraymesh_shownames was called, show a black background
				if SPRAY_SHOWING_NAMES then
						-- This makes the spray invisible/black for animkilled sprays...
						self.FinalMaterial:SetTexture("$basetexture", self.RT)
				else
						-- FPS saver when not showing names
						self.FinalMaterial:SetTexture("$basetexture", self.htmlmat:GetName())

						return
				end

				render.PushRenderTarget(self.RT)
						cam.Start2D()
								local sW, sH = ScrW(), ScrH()

								local spraytex = surface.GetTextureID(self.htmlmat:GetName())
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetTexture(spraytex)
								surface.DrawTexturedRect(0, 0, sW, sH)

								if SPRAY_SHOWING_NAMES then
										local count = 1

										for id64, data in pairs(spraymesh.SPRAYDATA) do
												-- * This is stupid and inefficient, but it only runs when spraymesh_shownames is called,
												-- * in which case, good FPS probably isn't important at that very moment
												if data.url == urloriginal then
														surface.SetDrawColor(0, 255, 0, 255)
														surface.DrawOutlinedRect(0, 0, sW, sH, 3)

														local text = ("%s (%s)"):format(data.PlayerName, id64)
														draw.WordBox(4, 10, (32 * count) - 22, text, "TargetID", color_black, color_white)

														count = count + 1
												end
										end

										draw.WordBox(4, 10, sH - 38, urloriginal, "TargetID", color_black, color_white)
								end
						cam.End2D()
				render.PopRenderTarget()
		end

		table.insert(htmlpanels, panelContainer)
end

---Generates an HTML-based texture (IMaterial) for a spray and assigns it to the mesh data.
---@param url string Spray URL to generate a texture from
---@param meshData table Mesh data table to assign the generated material to
---@param steamID string SteamID64
---@param playerName string Name of the player who owns the spray
---@param callback? fun(mat: IMaterial)
---@return IMaterial|nil material The pending or existing material, or nil if generation fails
local function generateHTMLTexture(url, meshData, steamID, playerName, callback)
		--[[
				how to use:
				MyNewImaterial = generateHTMLTexture(url, meshData, function(imat)
						-- custom callback code, for when the image is fully loaded and the meshData has been applied
						-- imat argument is the loaded imaterial
				end)
				meshData is a table pointer, and needs to contain an imaterial key
		]]
		spraymesh.DebugPrint("Generating HTML material for " .. url)

		-- NOTE: Commented out if check to display username and SteamID of player's spray. Originally once an image
		-- was generated, it would only use the original generator's info since the HTML info was cached
		-- Now even reused textures will be regenerated resulting in duplicates. This isn't my favorite
		-- approach but its better than using cam.2D and murdering player FPS

		-- If the IMaterial doesn't exist yet, initialize it
		-- if imats[url] == nil then
				-- Pending table
				imats[url] = {}
				table.insert(imats[url], {meshData, callback})

				-- The uniquerequest guff is to stop the game from ever using its internal cache of web resources, because it returns bonkers sizes at random
				local newURL = url .. "?uniquerequest=" .. math.floor(SysTime() * 1000)

				generateHTMLPanel(newURL, url, steamID, playerName, function(imat)
						-- Should be
						if type(imats[url]) == "table" then
								for k, v in pairs(imats[url]) do
										local meshDataCurrent = v[1]
										local optionalCallback = v[2]

										meshDataCurrent.imaterial = imat

										if optionalCallback then
												optionalCallback(imat)
										end

										spraymesh.DebugPrint("Finished generating HTML material; replacing dummy texture")
								end

								imats[url] = imat
						end
				end)

				spraymesh.DebugPrint("Generating, giving dummy texture")

				return MAT_SPRAY_PENDING
		-- elseif type(imats[url]) == "table" then
		--     -- Pending table; texture is still generating
		--     spraymesh.DebugPrint("Generated texture is currently pending...")
		--
		--     table.insert(imats[url], {meshData, callback})
		--
		--     return MAT_SPRAY_PENDING
		-- else
		--     spraymesh.DebugPrint("Generated texture already exists")
		--
		--     return imats[url]
		-- end
end

---Copies vertex position data and applies UV coordinates and normal/tangent info.
---@param copy table Vertex data to copy position from
---@param u number Texture U coordinate
---@param v number Texture V coordinate
---@param norm Vector Normal vector
---@param bnorm Vector Binormal vector
---@param tang Vector Tangent vector
---@return table vertex
local function copyVert(copy, u, v, norm, bnorm, tang)
		u = u or 0
		v = v or 0
		norm = norm or 1
		bnorm = bnorm or Vector(0, 0, 0)
		tang = tang or 1
		local t = table.Copy(copy)
		t.u, t.v, t.normal, t.bitnormal, t.tangent = u, v, norm, bnorm, tang

		return t
end

---Adds a quad (two triangles) to the mesh points array from the coordinate grid.
---@param x number Grid X position
---@param y number Grid Y position
---@param points table Mesh vertex data
---@param coords table Grid coordinate data
local function addSquareToPoints(x, y, points, coords)
		--[[local _a = copyVert(coords[x+0][y+0],0,0) -- Repeating texture per square
		local _b = copyVert(coords[x+1][y+0],1,0) -- Probably also needs a y flip
		local _c = copyVert(coords[x+1][y+1],1,1)
		local _d = copyVert(coords[x+0][y+1],0,1)]]
		local rm1 = spraymesh.MESH_RESOLUTION - 1
		local __a = coords[x + 0][y + 0]
		local __b = coords[x + 1][y + 0]
		local __c = coords[x + 1][y + 1]
		local __d = coords[x + 0][y + 1]

		if __a.bad then
				__a = coords[x + 0][math.Clamp(y + 1, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __b.bad then
				__b = coords[x + 1][math.Clamp(y + 1, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __c.bad then
				__c = coords[x + 1][math.Clamp(y + 0, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __d.bad then
				__d = coords[x + 0][math.Clamp(y + 0, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		-- Probably could simply replace the other but eh
		if __a.bad then
				__a = coords[math.Clamp(x + 1, 0, spraymesh.MESH_RESOLUTION - 1)][math.Clamp(y + 1, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __b.bad then
				__b = coords[math.Clamp(x + 0, 0, spraymesh.MESH_RESOLUTION - 1)][math.Clamp(y + 1, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __c.bad then
				__c = coords[math.Clamp(x + 0, 0, spraymesh.MESH_RESOLUTION - 1)][math.Clamp(y + 0, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		if __d.bad then
				__d = coords[math.Clamp(x + 1, 0, spraymesh.MESH_RESOLUTION - 1)][math.Clamp(y + 0, 0, spraymesh.MESH_RESOLUTION - 1)]
		end

		local _a = copyVert(__a, (x + 0) / rm1, 1 - ((y + 0) / rm1)) -- Stretch texture over all squares
		local _b = copyVert(__b, (x + 1) / rm1, 1 - ((y + 0) / rm1))
		local _c = copyVert(__c, (x + 1) / rm1, 1 - ((y + 1) / rm1))
		local _d = copyVert(__d, (x + 0) / rm1, 1 - ((y + 1) / rm1))
		table.insert(points, _a) -- Adccba
		table.insert(points, _d)
		table.insert(points, _c)
		table.insert(points, _c)
		table.insert(points, _b)
		table.insert(points, _a)
end

---Places a spray in the world by generating its mesh and texture from the given spray data.
---@param sprayData table Spray placement data from server
function spraymesh.PlaceSpray(sprayData)
		local id64 = sprayData.SteamID64
		local nick = sprayData.PlayerName
		local hitpos = sprayData.HitPos
		local hitnormal = sprayData.HitNormal
		local url = sprayData.URL
		local playSpraySound = sprayData.PlaySpraySound
		local coordDist = sprayData.CoordDistance
		local sprayTime = sprayData.SprayTime

		local tracenormal = sprayData.TraceNormal
		local anglenormal = tracenormal:Angle()
		anglenormal:Normalize()

		local URLToSpray = url
		-- local lpid64 = LocalPlayer():SteamID64()

		-- Give other code a chance to block the spray on the client
		local shouldAllowSpray = hook.Run("SprayMesh.ClientShouldAllowSpray", sprayData) ~= false
		if not shouldAllowSpray then return end

		-- If the local player is spraying the default spray, show them help instructions in chat
		local sprayIsDefault = url == spraymesh.SPRAY_URL_DEFAULT
		sprayIsDefault = sprayIsDefault or url == "http://" .. spraymesh.SPRAY_URL_DEFAULT
		sprayIsDefault = sprayIsDefault or url == "https://" .. spraymesh.SPRAY_URL_DEFAULT

		-- if id64 == lpid64 and sprayIsDefault then
		--     spraymesh.Instructions()
		-- end

		-- Play the spray sound
		if playSpraySound then sound.Play("SprayCan.Paint", hitpos, 60, 100, .3) end

		--
		-- Create spray mesh
		--

		-- Benchmark how long it takes to create the spray mesh
		local timestart = SysTime()

		local pos = hitpos + hitnormal -- One unit out
		local points = {}
		local coords = {}

		--
		-- Calculate spray angle
		--
		local tangang = hitnormal:Angle()
		tangang:Normalize()

		-- Note to anyone who reads this:
		-- I pretty much just fiddled with random values and equations until I got it right.
		-- If you're a math person and can understand it, great.
		local angToRotateBy = 0
		if tangang.p < 0 then
				angToRotateBy = 180 + (anglenormal - tangang).y
		elseif tangang.p > 0 then
				angToRotateBy = 180 + (tangang - anglenormal).y
		end

		tangang:RotateAroundAxis(tangang:Forward(), angToRotateBy)

		--
		-- Calculate spray's mesh coordinates
		--
		coordDist = coordDist or spraymesh.COORD_DIST_DEFAULT

		-- Sizing formula to keep the spray the same size (roughly) when mesh resolution changes
		coordDist = coordDist * (1 / spraymesh.MESH_RESOLUTION) * 30

		for ix = 0, spraymesh.MESH_RESOLUTION - 1 do
				coords[ix] = {}

				for iy = 0, spraymesh.MESH_RESOLUTION - 1 do
						coords[ix][iy] = {}

						local coord = coords[ix][iy]

						--local yawMultiplier = math.abs(tangang.p) / 180
						--tangang.y = math.Remap(yawMultiplier, 0, 1, anglenormal.y, tangang.p)

						coord.pos = pos + (-(tangang:Right() * ix) + (tangang:Up() * iy)) * coordDist
						coord.pos = coord.pos + (tangang:Right() * coordDist * spraymesh.MESH_RESOLUTION / 2) - (tangang:Up() * coordDist * spraymesh.MESH_RESOLUTION / 1.8)

						if not (ix == 0 and iy == 0) then
								local testtr = util.TraceLine({
										start = coord.pos + hitnormal * 16,
										endpos = coord.pos - hitnormal * 16,
										filter = function(ent)
												if not IsValid(ent) then return false end
												if ent:IsWorld() then return true end

												return false
										end
								})

								if not testtr.Hit or not testtr.HitWorld then
										if ix == 0 then
												coord.pos = coords[ix][iy - 1].pos
										else
												coord.pos = coords[ix - 1][iy].pos
										end

										coord.bad = true
								else
										coord.pos = testtr.HitPos + hitnormal
								end
						end

						coord.u, coord.v = 0, 0
						coord.bitnormal = 1
						coord.tangent = 1
						coord.normal = hitnormal

						--
						-- Calculate vertex color
						--
						local lcol = render.ComputeLighting(coord.pos, hitnormal) + render.GetAmbientLightColor()
						lcol = lcol * 255

						local baseBrightness = 60

						local finalCol = Color(255, 255, 255)
						finalCol.r = math.min(lcol.x + baseBrightness, 255)
						finalCol.g = math.min(lcol.y + baseBrightness, 255)
						finalCol.b = math.min(lcol.z + baseBrightness, 255)

						coord.color = finalCol
				end
		end

		for ix = 0, spraymesh.MESH_RESOLUTION - 2 do
				for iy = 0, spraymesh.MESH_RESOLUTION - 2 do
						addSquareToPoints(ix, iy, points, coords)
				end
		end

		-- Create the actual mesh for the spray
		-- PrintTable(sprayData)
		local meshdata = {}
		meshdata.mesh = Mesh()
		meshdata.mesh:BuildFromTriangles(points)
		meshdata.imaterial = generateHTMLTexture(URLToSpray, meshdata, sprayData.SteamID64, sprayData.PlayerName) -- Ughhhhh hand this off to five funcs so we can show SteamID and PlayerName. Hot potato

		-- Remove the existing spray, if any
		spraymesh.RemoveSpray(id64)

		-- Put together new spray info table
		local sprayInfo = spraymesh.SPRAYDATA[id64] or {}
		sprayInfo.meshdata = meshdata
		sprayInfo.meshdata.url = URLToSpray
		sprayInfo.hitpos = hitpos
		sprayInfo.hitnormal = hitnormal
		sprayInfo.TraceNormal = tracenormal
		sprayInfo.url = url
		sprayInfo.PlayerName = nick
		sprayInfo.CoordDistance = coordDist
		sprayInfo.Time = sprayTime or CurTime()

		spraymesh.SPRAYDATA[id64] = sprayInfo

		spraymesh.DebugPrint("Spray mesh created in: " .. SysTime() - timestart .. "s")
end

---Removes all sprays from the world and cleans up HTML panels.
function spraymesh.RemoveSprays()
		for k, v in pairs(htmlpanelsanim) do
				imats[v.origurl] = nil
				v.panel:Remove()
		end

		for k, v in pairs(spraymesh.SPRAYDATA) do
				if v.meshdata and v.meshdata.mesh then
						v.meshdata.mesh:Destroy()
						v.meshdata.mesh = nil
				end
		end

		htmlpanelsanim = {}
end

--
-- HTML handlers
--
-- This is the HTML that prepares the spray to be displayed
--

spraymesh.HTMLHandlers = {}

---Routes a spray URL to the appropriate HTML handler (image or video).
---@param url string Spray URL (without uniquerequest suffix)
---@param size number Image resolution
---@param steamID string SteamID64
---@param playerName string Name of the player who owns the spray
---@param panelcontainer table Panel container holding the DHTML panel
function spraymesh.HTMLHandlers.Get(url, size, steamID, playerName, panelcontainer)
		-- Remove uniquerequest garbage
		url = string.Explode("?", url, false)[1]

		-- Needs redoing for the extension
		local sprayType = spraymesh.GetURLInfo(url)

		if sprayType == SPRAYTYPE_IMAGE then
				spraymesh.DebugPrint("Using HTMLHandlers.Image for URL: " .. url)

				return spraymesh.HTMLHandlers.Image(url, size, steamID, playerName, panelcontainer)
		elseif sprayType == SPRAYTYPE_VIDEO then
				spraymesh.DebugPrint("Using HTMLHandlers.Video for URL: " .. url)

				return spraymesh.HTMLHandlers.Video(url, size, steamID, playerName, panelcontainer)
		end

		spraymesh.DebugPrint("Using (FALLBACK) HTMLHandlers.Image for URL: " .. url)

		return spraymesh.HTMLHandlers.Image(url, size, steamID, playerName, panelcontainer)
end

local SPRAY_HTML_IMAGE = [=[
<!DOCTYPE html>
<html>
		<head>
				<meta charset="UTF-8">
				<title>title</title>
				<style type = "text/css">
						html {
								overflow: hidden;
						}

						body {
								margin: 0;
								background: transparent;
						}

						img {
								width: 100%;
								height: 100%;

								position: absolute;
								top: 0px;
								bottom: 0px;
								left: 0px;
								right: 0px;

								object-fit: contain;
						}

						#overlayText {
								position: absolute;
								top: 0;
								left: 0;
								width: 100%;
								padding: 10px;
								color: white;
								font-family: sans-serif;
								font-size: 16px;
								text-shadow: 1px 1px 4px black;
								z-index: 1000;
								pointer-events: none; /* let mouse events pass through */
						}

						#steamid {
								font-size: 15px;
								font-weight: bold;
						}
				</style>
		</head>
		<body>
				<div id="sprayimage"></div>
				<script>
						// Thanks to http://www.andygup.net/tag/magic-number/
						var imageContainer = document.getElementById("sprayimage");

						function getImageType(arrayBuffer) {
								var type = "";
								var dv = new DataView(arrayBuffer, 0, 5);
								var nume1 = dv.getUint8(0);
								var nume2 = dv.getUint8(1);
								var hex = nume1.toString(16) + nume2.toString(16);

								switch (hex) {
										case "8950":
												type = "image/png";
												break;
										case "4749":
												type = "image/gif";
												break;
										case "424d":
												type = "image/bmp";
												break;
										case "ffd8":
												type = "image/jpeg";
												break;
										default:
												type = "application/octet-stream";
												break;
								}

								return type;
						}

						function getImageFromServer(path, callback) {
								var xhr = new XMLHttpRequest();

								xhr.open("GET", path, true);
								xhr.responseType = "arraybuffer";
								xhr.onload = function (e) {
										if (this.status == 200) {
												var imageType = getImageType(this.response);
												callback(imageType);
										}
										else {
												//console.log("Problem retrieving image " + JSON.stringify(e))
												callback("NIL");
										}
								}

								xhr.send();
						}

						function makeimage() {
								var src = "{SPRAY_URL}";
								getImageFromServer(src, function (imageType) {
										console.log("Image Type: " + imageType);

										// Anti-GIF
										// TODO: Do GIF files still drain FPS on current-day Garry's Mod?
										// It might not even be necessary to limit them nowadays
										/*if (imageType == "image/gif") {
												src = "https://{SPRAY_URL_ANTIGIF}";
										}*/

										var sprayImage = document.createElement("img");
										sprayImage.src = src;

										console.log(src);

										// Check to ensure image container is valid before appending our img element
										if (!!imageContainer) {
												imageContainer.appendChild(sprayImage);
										}
								});
						};

						makeimage();
				</script>

				<div id="overlayText">
					<div id="username">{USERNAME}</div>
					<div id="steamid">{STEAMID}</div>
				</div>
		</body>
</html>
]=]

---Sets the HTML content for an image spray.
---@param url string Image URL
---@param size number Image resolution
---@param username string Player display name
---@param steamID string SteamID64
---@param panelcontainer table Panel container holding the DHTML panel
function spraymesh.HTMLHandlers.Image(url, size, username, steamID, panelcontainer)
		local sprayHTML = SPRAY_HTML_IMAGE
		sprayHTML = sprayHTML:Replace("{SPRAY_URL}", string.JavascriptSafe(url))
		sprayHTML = sprayHTML:Replace("{USERNAME}", string.JavascriptSafe(username or "Unknown"))
		sprayHTML = sprayHTML:Replace("{STEAMID}", string.JavascriptSafe(steamID or ""))
		sprayHTML = sprayHTML:Replace("{SIZE}", string.JavascriptSafe(size or ""))
		--sprayHTML = sprayHTML:Replace("{SPRAY_URL_ANTIGIF}", string.JavascriptSafe(spraymesh.SPRAY_URL_ANTIGIF))

		panelcontainer.panel:SetHTML(sprayHTML)
end

local SPRAY_HTML_VIDEO = [=[
<!DOCTYPE html>
<html>
		<head>
				<meta charset="UTF-8">
				<style>
						html {
								overflow: hidden;
						}

						body {
								margin: 0;
								background: transparent;
						}

						video {
								width: 100%;
								height: 100%;

								position: absolute;
								top: 0px;
								bottom: 0px;
								left: 0px;
								right: 0px;

								object-fit: contain;
						}
				</style>
		</head>
		<body>
				<video id="sprayimage" onload="fiximage()" src="{SPRAY_URL}" autoplay loop muted>
				<script>
						function fiximage() {
								var videoElem = document.getElementById("sprayimage");
								if (!!videoElem && videoElem.height > videoElem.width) {
										videoElem.style.height = "{SIZE}px";
										videoElem.style.width = "auto";
								}
						};
				</script>
		</body>
</html>
]=]

---Sets the HTML content for a video spray.
---@param url string Video URL
---@param size number Video resolution
---@param panelcontainer table Panel container holding the DHTML panel
function spraymesh.HTMLHandlers.Video(url, size, panelcontainer)
		local sprayHTML = SPRAY_HTML_VIDEO
		sprayHTML = sprayHTML:Replace("{SPRAY_URL}", string.JavascriptSafe(url))
		sprayHTML = sprayHTML:Replace("{SIZE}", string.JavascriptSafe(size))

		if not IsValid(panelcontainer) then return end

		panelcontainer.panel:SetHTML(sprayHTML)
end

--
-- Network handlers
--

-- Received when the server wants to place a player's spray
net.Receive("SprayMesh.SV_SendSpray", function(length)
		local id64 = net.ReadString()
		local nick = net.ReadString()
		local hitPos = net.ReadVector()
		local hitNormal = net.ReadNormal()
		local traceNormal = net.ReadNormal()
		local url = net.ReadString()
		local coordDist = net.ReadFloat()
		local sprayTime = net.ReadFloat()

		spraymesh.DebugPrint("Receiving spray: " .. url)

		local sprayData = {
				SteamID64 = id64,
				PlayerName = nick,
				HitPos = hitPos,
				HitNormal = hitNormal,
				TraceNormal = traceNormal,
				URL = url,
				CoordDistance = coordDist,
				SprayTime = sprayTime,
				PlaySpraySound = true
		}

		spraymesh.PlaceSpray(sprayData)
end)

-- Received when the server wants to remove a player's spray
net.Receive("SprayMesh.SV_ClearSpray", function()
		local id64 = net.ReadString()
		spraymesh.RemoveSpray(id64)
end)

--
-- Hooks
--

hook.Add("Think", "SprayMesh.Generate", function()
		for k, v in pairs(htmlpanels) do
				local htmlmat = v.panel:GetHTMLMaterial()

				if v and htmlmat then
						spraymesh.DebugPrint("FINISHED")

						local uid = string.Replace(htmlmat:GetName(), "__vgui_texture_", "")

						spraymesh.DebugPrint("Material name: spraymesh_" .. uid)
						local FinalMaterial = CreateMaterial("spraymesh_" .. uid, "UnlitGeneric", {
								["$basetexture"] = htmlmat:GetName(),
								["$vertexcolor"] = 1,
								["$vertexalpha"] = 1,
								["$model"] = 1,
								["$nocull"] = 1,
								["$receiveflashlight"] = 1
						})

						v.callback(FinalMaterial)

						table.remove(htmlpanels, k)
						table.insert(htmlpanelsanim, v)

						v.FinalMaterial = FinalMaterial
						v.htmlmat = htmlmat

						break
				else
						spraymesh.DebugPrint("GENERATING...")
				end
		end
end)

-- Ensures animated sprays are still animating properly (e.g. IMaterial is still valid)
hook.Add("Think", "SprayMesh.HandleAnimatedSprays", function()
		for index, panelData in ipairs(htmlpanelsanim) do
				if panelData then
						if panelData.origurl then
								if imats[panelData.origurl] == nil then
										panelData.panel:Remove()
										panelData = nil
										table.remove(htmlpanelsanim, index)
										break
								end
						else
								table.remove(htmlpanelsanim, index)
								break
						end
				else
						table.remove(htmlpanelsanim, index)
						break
				end
		end
end)

hook.Add("PostDrawHUD", "SprayMesh.AnimatedSpraysPaint", function()
		for k, panelData in ipairs(htmlpanelsanim) do
				if not panelData then
						table.remove(htmlpanelsanim, k)
						break
				end

				if panelData.PaintSpray then
						panelData:PaintSpray()
				end
		end
end)

hook.Add("PostDrawHUD", "SprayMesh.GenerateSprayPlaceholderTextures", function()
		render.PushRenderTarget(RT_SPRAY_PENDING)
				render.Clear(0, 0, 0, 255, true, true)

				cam.Start2D()
						draw.SimpleText("Loading spray...", "DermaLarge", ScrW() / 2, ScrH() / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cam.End2D()
		render.PopRenderTarget()

		render.PushRenderTarget(RT_SPRAY_DISABLEDVIDEO)
				render.Clear(0, 0, 0, 255, true, true)

				cam.Start2D()
						surface.SetDrawColor(255, 0, 0, 255)
						surface.DrawOutlinedRect(0, 0, ScrW(), ScrH(), 3)

						draw.SimpleText("This spray is animated, but you have animated sprays turned off.", "DermaDefaultBold", ScrW() / 2, ScrH() / 2 - 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						draw.SimpleText("Use /spraymesh to enable animated sprays.", "DermaDefaultBold", ScrW() / 2, ScrH() / 2 + 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cam.End2D()
		render.PopRenderTarget()

		render.PushRenderTarget(RT_SPRAY_DISABLEDSPRAY)
				render.Clear(0, 0, 0, 255, true, true)

				cam.Start2D()
						surface.SetDrawColor(255, 255, 0, 255)
						surface.DrawOutlinedRect(0, 0, ScrW(), ScrH(), 3)

						draw.SimpleText("[sprays are disabled]", "DermaLarge", ScrW() / 2, ScrH() / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cam.End2D()
		render.PopRenderTarget()

		hook.Remove("PostDrawHUD", "SprayMesh.GenerateSprayPlaceholderTextures")
end)

-- Draw meshes for all player sprays
hook.Add("PreDrawTranslucentRenderables", "SprayMesh.DrawSprays", function(isDrawingDepth, isDrawingSkybox, isDrawing3DSkybox)
		if isDrawingDepth or isDrawingSkybox then return end

		-- If render order doesn't exist yet, rebuild it
		if not spraymesh.RENDER_ITER_CLIENT then
				spraymesh.RENDER_ITER_CLIENT = {}

				local i = 1
				for id64, sprayData in SortedPairsByMemberValue(spraymesh.SPRAYDATA, "Time") do
						spraymesh.RENDER_ITER_CLIENT[i] = sprayData.meshdata

						i = i + 1
				end
		end

		-- Render all sprays
		for _, meshData in ipairs(spraymesh.RENDER_ITER_CLIENT) do
				local meshToDraw = meshData.mesh

				if meshData and meshToDraw and IsValid(meshToDraw) then
						render.SetMaterial(meshData.imaterial)
						meshToDraw:Draw()
				end
		end
end)

-- Coroutine function; used to reload sprays with spraymesh_reload
---Coroutine body that processes one spray from the reload queue per resume.
local function cycleReloadSprays()
		local id64, data = next(SPRAY_RELOAD_QUEUE)
		if not id64 then return end

		print(("Reloading spray for %s (%s) at %s"):format(id64, data.PlayerName, data.hitpos))

		local sprayData = {
				SteamID64 = id64,
				PlayerName = data.PlayerName,
				HitPos = data.hitpos,
				HitNormal = data.hitnormal,
				TraceNormal = data.TraceNormal,
				URL = data.url,
				CoordDistance = data.CoordDistance,
				SprayTime = data.Time,
				PlaySpraySound = false
		}

		spraymesh.PlaceSpray(sprayData)

		SPRAY_RELOAD_QUEUE[id64] = nil

		coroutine.yield()
end

local sprayThread = nil
hook.Add("Think", "SprayMesh.ManageSprayReloadCoroutine", function()
		if (not sprayThread or not coroutine.resume(sprayThread)) and next(SPRAY_RELOAD_QUEUE) then
				sprayThread = coroutine.create(cycleReloadSprays)

				coroutine.resume(sprayThread)
		end
end)

--
-- Console commands
--

concommand.Add("spraymesh_debug", function()
		PrintTable(htmlpanelsanim)

		for _, v in pairs(htmlpanelsanim) do
				local panel = v.panel

				if not IsValid(panel) then continue end

				panel:SetAllowLua(true)

				-- Prevent re-adding the function multiple times
				if not panel._hasSendHTML then
						panel:AddFunction("gmod", "SendHTML", function(content)
								print("[HTML dumped]:", content)
						end)
						panel._hasSendHTML = true
				end

				-- Use QueueJavascript so you don't rely on OnDocumentReady timing
				panel:QueueJavascript("gmod.SendHTML(document.documentElement.outerHTML);")
		end
end)


concommand.Add("spraymesh_reload", function()
		spraymesh.ReloadSprays()
end)

concommand.Add("spraymesh_shownames", function(ply, cmd, args, argstr)
		local t = CurTime()
		SPRAY_SHOWING_NAMES_TIME = CurTime()

		SPRAY_SHOWING_NAMES = true

		timer.Simple(10, function()
				-- Easy way to allow overlapping commands
				if t == SPRAY_SHOWING_NAMES_TIME then
						SPRAY_SHOWING_NAMES = false
				end
		end)

		-- Print data to console
		for id64, data in pairs(spraymesh.SPRAYDATA) do
				local plyStr = ([[%s (%s)]]):format(data.PlayerName, id64)

				local URLStr = "No URL"

				if data.meshdata and data.meshdata.url then
						URLStr = data.meshdata.url
				end

				print(([[%s %s]]):format(plyStr, URLStr))
		end
end)

if spraymesh.DEBUG_MODE then
		concommand.Add("spraymesh_debug_place", function()
				local tr = LocalPlayer():GetEyeTrace()

				local sprayData = {
						SteamID64 = "DEBUG_" .. util.SHA1(CurTime()),
						PlayerName = "Debug Spray " .. CurTime(),
						HitPos = tr.HitPos,
						HitNormal = tr.HitNormal,
						TraceNormal = tr.Normal,
						URL = spraymesh.SPRAY_URL_DEFAULT,
						CoordDistance = spraymesh.COORD_DIST_DEFAULT,
						SprayTime = CurTime(),
						PlaySpraySound = true
				}

				spraymesh.PlaceSpray(sprayData)
		end)
end

--[[
	Holds all side side buttons and their panels to load

	Table setup:
		[1] - Button text
		[2] - Function to load panel
		[3] - Filter to check if button should be displayed
]]
Sprays.Menu.SideButtons = {
	[1] = {
		"Sprays", function(menu)
			local container = vgui.Create("GmcorePanel", menu)
			container:SetSize(menu:GetWide(), menu:GetTall())

			local urlTextEntry = vgui.Create("GmcoreTextInput", container)
			urlTextEntry:SetSize(container:GetWide() - 20, 40)
			urlTextEntry:SetHint("Spray URL")
			urlTextEntry:SetPos(10, 15)
			urlTextEntry:GetInputPanel():SetValue(GetConVar("SprayMesh_URL"):GetString())
			urlTextEntry:GetInputPanel().OnEnter = function(s, value)
				local url = value
				local foundHttpPrefix = false -- Used for http.Fetch since this won't work without http(s)

				if string.sub(value, 1, 4) == "http" then
					foundHttpPrefix = true
					local amountToStrip = #"http://"

					if string.sub(value, 5, 5) == "s" then
						amountToStrip = amountToStrip + 1
					end

					url = string.Right(value, #value - amountToStrip)
				end

				-- Extract domain from the URL (after stripping the http/https prefix)
				local domain = string.match(url, "^([^/]+)")

				if domain and spraymesh.VALID_URL_DOMAINS_IMAGE[domain] then
					http.Fetch(foundHttpPrefix and value or "https://" .. url, function(body, len, header, code)
						-- Successful response
						if string.find(header["Content-Type"], "image") then
							GetConVar("SprayMesh_URL"):SetString(url)
							GMCore_MessageDialog("Spray successfully updated.", "Spray Update", "Ok")

							if IsValid(htmlPreviewSpray) and isfunction(htmlPreviewSpray.UpdateHTML) then
								htmlPreviewSpray.UpdateHTML()
							end
						else
							GMCore_MessageDialog("Failed to update spray to provided input. Error: The provided URL does not return an image of .png or .jpg", "Spray Update", "Ok")

							return
						end
					end, function(errorMsg)
						-- Failed response (probably invalid url)
						GMCore_MessageDialog("Failed to update spray to provided input. HTTP response error: " .. errorMsg, "Spray Update", "Ok")
					end)
				else
					local approvedDomains = {}

					for domain in pairs(spraymesh.VALID_URL_DOMAINS_IMAGE) do
							table.insert(approvedDomains, domain)
					end

					table.sort(approvedDomains)

					local domainList = table.concat(approvedDomains, "\n")

					GMCore_MessageDialog(
							"Failed to update spray to provided input. The provided link is not from an approved domain. Approved domains:\n" .. domainList,
							"Spray Update",
							"Ok"
					)
				end
			end

			local lblPreview = vgui.Create("DLabel", container)
			lblPreview:SetFont(FONT_SPRAY_SECTION_HEADER)
			lblPreview:SetText("Spray Preview")
			lblPreview:SetTextColor(CARD_TITLE_TEXT_COLOR)
			lblPreview:SizeToContents()
			lblPreview:SetPos(10, urlTextEntry:GetY() + urlTextEntry:GetTall() + 20)

			local htmlPreviewPosY = lblPreview:GetY() + lblPreview:GetTall()
			htmlPreviewSpray = vgui.Create("DHTML", container)
			htmlPreviewSpray:SetSize(container:GetWide() - 50, container:GetTall() - htmlPreviewPosY - 40)
			htmlPreviewSpray:SetPos(10, htmlPreviewPosY)
			htmlPreviewSpray:SetHTML([[
			<style>
				img {
					-khtml-user-select: none;
					-o-user-select: none;
					-moz-user-select: none;
					-webkit-user-select: none;
					user-select: none;
					opacity: 0;
					-webkit-transition: opacity 0.5s;
					-moz-transition: opacity 0.5s;
					transition: opacity 0.5s;
				}
			</style>
			<img id="spray" style="overflow-x:hidden;overflow-y:hidden" src="https://]] .. GetConVar("SprayMesh_URL"):GetString() ..  [[" width="350" height="350" />
			]])
			htmlPreviewSpray.UpdateHTML = function()
				htmlPreviewSpray:SetHTML([[
				<style>
					img {
						-khtml-user-select: none;
						-o-user-select: none;
						-moz-user-select: none;
						-webkit-user-select: none;
						user-select: none;
						opacity: 1;
						-webkit-transition: opacity 0.5s;
						-moz-transition: opacity 0.5s;
						transition: opacity 0.5s;
					}
				</style>
				<img id="spray" src="https://]] .. GetConVar("SprayMesh_URL"):GetString() ..  [[" width="350" height="350" />
				]])
			end

			menu:GetParent().OnRemoveClicked = function(s)
				if !IsValid(htmlPreviewSpray) then return end

				htmlPreviewSpray:Call([[
					document.getElementById("spray").style.opacity = 0;
				]])
			end

			htmlPreviewSpray:Call([[
				document.getElementById("spray").style.opacity = 1;
			]])

			local btnSaveSettings = vgui.Create("GmcoreButton", container)
			btnSaveSettings:SetText("Save Spray")
			btnSaveSettings:SizeToText()
			btnSaveSettings:SetPos(container:GetWide() - btnSaveSettings:GetWide() - 5, container:GetTall() - btnSaveSettings:GetTall() - 5)
			btnSaveSettings.DoClick = function()
				urlTextEntry:GetInputPanel():OnEnter(urlTextEntry:GetInputPanel():GetValue())
			end

			return container
		end,
	},

	[2] = {
		"Settings", function(menu)
			local container = vgui.Create("GmcorePanel", menu)
			container:SetSize(menu:GetWide(), menu:GetTall())

			local settingsPanelList = vgui.Create("DIconLayout", container)
			settingsPanelList:StretchToParent(10, 10, 10, 10)
			settingsPanelList:SetSpaceX(0)
			settingsPanelList:SetSpaceY(0)

			local enableSprays = settingsPanelList:Add("GmcoreCheckBoxLabel")
			enableSprays:SetText("Show animated sprays")
			enableSprays:SetConVar("SprayMesh_EnableVideos")
			enableSprays:SizeToContents()

			local clearSprays = vgui.Create("GmcoreButton", container)
			clearSprays:SetText("Clear All Sprays")
			clearSprays:SizeToText()
			clearSprays:SetPos(menu:GetWide() - clearSprays:GetWide() - 5, menu:GetTall() - clearSprays:GetTall() - 5)
			clearSprays.DoClick = function()
				RunConsoleCommand("SprayMesh_Clear")
			end

			return container
		end,
	},

	[3] = {
		"Staff Manager", function(menu)
			local container = vgui.Create("GmcorePanel", menu)
			container:SetSize(menu:GetWide(), menu:GetTall())

			menu.spraysListView = vgui.Create("GmcoreListView", container)
			menu.spraysListView:Dock(FILL)
			menu.spraysListView:DockMargin(10, 10, 10, 10)
			menu.spraysListView:AddColumn("Name"):SetMaxWidth(200)
			menu.spraysListView:AddColumn("SteamID"):SetFixedWidth(150)
			menu.spraysListView:AddColumn("Spray URL")

			menu.spraysListView.OnRowRightClick = function(self, lineId, linePanel)
				local sSteamID = linePanel:GetValue(2)
				local sSprayURL = linePanel:GetValue(3)
				local ply = player.GetBySteamID(sSteamID)

				local options = DermaMenu()

				options:AddOption("Copy SteamID", function()
					SetClipboardText(sSteamID)

					surface.PlaySound("buttons/button9.wav")
				end):SetImage("icon16/tag_blue.png")

				options:AddOption("Copy Spray URL", function()
					SetClipboardText(sSprayURL)

					surface.PlaySound("buttons/button9.wav")
				end):SetImage("icon16/world_link.png")

				options:AddOption("View Spray", function()
					local frame = vgui.Create("DFrame")
					frame:SetSize(700, 500)
					frame:Center()
					frame:SetTitle("Spray Preview")
					frame:MakePopup()

					local html = vgui.Create("DHTML", frame)
					html:Dock(FILL)
					html:OpenURL(sSprayURL)

					surface.PlaySound("buttons/button9.wav")
				end):SetImage("icon16/world_link.png")

				options:AddSpacer()

				options:AddOption("Remove Spray", function()
					net.Start("gmcore.Sprays.RemoveSpray")
					net.WriteString(sSteamID)
					net.SendToServer()

					-- It was 3:30 am when I did this. I'll make it refresh better later //  broken (disabled by temar)
					--timer.Simple(0.01, function()
					--	managerFrame:Remove()
					--	RunConsoleCommand("spraysmanager")
					--end)

					surface.PlaySound("buttons/button9.wav")
				end):SetImage("icon16/cross.png")

				options:Open()
			end

			-- Now load the sprays
			for steamID, spray in pairs(spraymesh.SPRAYDATA) do
				if player.GetBySteamID64(steamID) and spray and spray.meshdata then
					local ply = player.GetBySteamID64(steamID)

					menu.spraysListView:AddLine(ply:Nick(), steamID, "https://" .. spray.meshdata.url)
				end
			end

			return container
		end,

		function(ply)
			return ULib.ucl.query(ply, "ulx spraysmanager")
		end
	},
}


---Populates the sidebar navigation with all registered side buttons.
function Sprays.Menu:LoadSideBar()
	for k, v in ipairs(self.SideButtons) do
		self.SideBarNav:AddTab(v[1], v[2], v[3])
	end
end

---Opens the spray settings menu with sidebar navigation.
function Sprays.Menu:OpenMenu()
	if IsValid(self.Frame) then return end

	self.Frame = vgui.Create("GmcoreFrame")
	self.Frame:SetSize(800, 580)
	self.Frame:SetTitle("Spray Settings")
	self.Frame:SetPaintShadow(true)
	self.Frame:MakePopup()
	self.Frame:Center()

	local SIDEBAR_W = 220
	local HEADER_H  = 56

	-- Sidebar
	self.sidebarContainer = vgui.Create("DScrollPanel", self.Frame)
	self.sidebarContainer:SetPos(0, HEADER_H)
	self.sidebarContainer:SetSize(SIDEBAR_W, self.Frame:GetTall() - HEADER_H)

	self.sidebarContainer.Paint = function(s, w, h)
		draw.RoundedBoxEx(10, 0, 0, w, h, FRAME_HEADER_COLOR, false, false, false, true)
	end

	-- Main container
	self.mainContainer = vgui.Create("GmcorePanel", self.Frame)
	self.mainContainer:SetPos(SIDEBAR_W, HEADER_H)
	self.mainContainer:SetSize(self.Frame:GetWide() - SIDEBAR_W, self.Frame:GetTall() - HEADER_H)

	self.mainContainer.Paint = function(s, w, h)
		draw.RoundedBoxEx(10, 0, 0, w, h, CARD_BACKGROUND_COLOR, false, false, true, false)
	end

	self.SideBarNav = vgui.Create("GmcoreSideBarNav", self.sidebarContainer)
	self.SideBarNav:SetSize(self.sidebarContainer:GetWide(), self.sidebarContainer:GetTall())
	self.SideBarNav:SetTabContainer(self.mainContainer)
	self.SideBarNav:SetButtonFont(FONT_SPRAY_SIDEBAR)

	self:LoadSideBar()
end
