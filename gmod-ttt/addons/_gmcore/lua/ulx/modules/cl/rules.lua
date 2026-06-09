---Client-side ULX module that creates the GMCore TTT rules popup.
---Displays a DHTML frame loading a remote rules URL, invoked via `gmcore.ShowRulesMenu`
---from a server-side `ULib.clientRPC` call.

---Creates the popup for rules. Can't follow coding standards with function definition since clientRPC functions needed to be defined with "." and not ":"
---@param url string The url for the DHTML to load
---@param isOnSpawn boolean Boolean if we are opening this menu on initial spawn. If so, do not have fade-in anim play
function gmcore.ShowRulesMenu(url, isOnSpawn)
	local frame = vgui.Create("GmcoreFrame")
	if ScrW() > 640 then
		frame:SetSize(ScrW() * 0.9, ScrH() * 0.9)
	else
		frame:SetSize(640, 480)
	end
	frame:SetTitle("GMCore TTT Rules")
	frame:ShowCloseButton(false)
	frame:SetFadeOnOpen(!isOnSpawn)
	frame:Center()
	frame:MakePopup()

	local mainContainer = vgui.Create("GmcorePanel", frame)
	mainContainer:SetSize(frame:GetWide(), frame:GetTall() - 50)
	mainContainer:SetPos(0, 50)

	local closeBtn = vgui.Create("GmcoreButton", mainContainer)
	closeBtn:SetText("Close")
	closeBtn:SetSize(100, 40)
	closeBtn:SetPos((mainContainer:GetWide() / 2) - (closeBtn:GetWide() / 2), mainContainer:GetTall() - closeBtn:GetTall() - 10)
	closeBtn.DoClick = function()
		frame:Close()
	end

	local rulesHTML = vgui.Create("DHTML", mainContainer)
	rulesHTML:SetSize(mainContainer:GetWide() - 20, mainContainer:GetTall() - closeBtn:GetTall() - 30)
	rulesHTML:SetPos(10, 10)
	rulesHTML:OpenURL(url)
	rulesHTML:Call([[
		if (navigator.userAgent == "Mozilla/5.0 (Windows; Valve Source Client) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1003.1 Safari/535.19 Awesomium/1.7.5.1 GMod/13") {
			document.getElementById("header").style.setProperty("display", "none");
		}
	]])

	frame.OnRemoveClicked = function(s)
		if !IsValid(rulesHTML) then return end

		rulesHTML:Call([[
			var body = document.getElementById("XF");

			body.style.setProperty("-webkit-transition", "opacity 0.5s");
			body.style.setProperty("-moz-transition", "opacity 0.5s");
			body.style.setProperty("transition", "opacity 0.5s");

			body.style.opacity = 0;
		]])
	end
end
