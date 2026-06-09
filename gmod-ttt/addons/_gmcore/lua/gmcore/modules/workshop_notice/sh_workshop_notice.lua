---Linux workshop notice configuration. Shows a dialog to Linux/Proton users about potential workshop issues.
gmcore.WorkshopNotice = gmcore.WorkshopNotice or {}

gmcore.WorkshopNotice.Enabled = gmcore.WorkshopNotice.Enabled ~= false
gmcore.WorkshopNotice.Url = gmcore.WorkshopNotice.Url or "https://google.com"
gmcore.WorkshopNotice.CookieKey = gmcore.WorkshopNotice.CookieKey or "gmcore_workshop_notice_hide"

gmcore.WorkshopNotice.Vgui = {
	Title = "Workshop Addons on Linux",
	Body = "Linux/Proton users may see Steam Workshop addons fail to mount. If you notice missing content, click Learn More for details and workarounds.",
	CheckboxText = "Don't show this again",
	ButtonOpenText = "Learn More",
	ButtonCloseText = "Dismiss"
}
