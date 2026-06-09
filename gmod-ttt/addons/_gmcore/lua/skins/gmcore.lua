---GL derma skin definition. Dark theme skin with custom paint functions for all standard derma controls. Also overrides DMenuOption and DLabel.
local function registerSkinWithName(name)
	local surface = surface
	local Color = Color
	SKIN = {}
	SKIN.PrintName = "GMCore Skin"
	SKIN.Author = "My Dime Is Up"
	SKIN.DermaVersion = 1
	SKIN.GwenTexture = Material("gwenskin/gmcore.png")
	SKIN.bg_color = Color(30, 42, 56, 255)
	SKIN.bg_color_sleep = Color(23, 32, 48, 255)
	SKIN.bg_color_dark = Color(21, 32, 44, 255)
	SKIN.bg_color_bright = Color(236, 240, 241, 255)
	SKIN.frame_border = Color(52, 73, 94, 255)
	SKIN.fontFrame = "DermaDefault"
	SKIN.control_color = Color(44, 62, 80, 255)
	SKIN.control_color_highlight = Color(52, 73, 94, 255)
	SKIN.control_color_active = Color(52, 152, 219, 255)
	SKIN.control_color_bright = Color(52, 152, 219, 255)
	SKIN.control_color_dark = Color(23, 32, 48, 255)
	SKIN.bg_alt1 = Color(23, 32, 48, 255)
	SKIN.bg_alt2 = Color(21, 32, 44, 255)
	SKIN.listview_hover = Color(32, 45, 60, 255)
	SKIN.listview_selected = Color(52, 152, 219, 255)
	SKIN.text_bright = Color(236, 240, 241, 255)
	SKIN.text_normal = Color(189, 195, 199, 255)
	SKIN.text_dark = Color(236, 240, 241, 255) -- keep bright for dark theme
	SKIN.text_highlight = Color(231, 76, 60, 255)
	SKIN.texGradientUp = Material("gui/gradient_up")
	SKIN.texGradientDown = Material("gui/gradient_down")
	SKIN.combobox_selected = SKIN.listview_selected
	SKIN.panel_transback = Color(255, 255, 255, 50)
	SKIN.tooltip = Color(255, 245, 175, 255)
	SKIN.colPropertySheet = Color(44, 62, 80, 255)
	SKIN.colTab = SKIN.colPropertySheet
	SKIN.colTabInactive = Color(32, 45, 60, 255)
	SKIN.colTabShadow = Color(0, 0, 0, 170)
	SKIN.colTabText = Color(236, 240, 241, 255)
	SKIN.colTabTextInactive = Color(189, 195, 199, 255)
	SKIN.fontTab = "DermaDefault"
	SKIN.colCollapsibleCategory = Color(255, 255, 255, 14)
	SKIN.colCategoryText = Color(236, 240, 241, 255)
	SKIN.colCategoryTextInactive = Color(189, 195, 199, 255)
	SKIN.fontCategoryHeader = "TabLarge"
	SKIN.colNumberWangBG = Color(30, 42, 56, 255)
	SKIN.colTextEntryBG = Color(15, 22, 32, 255)
	SKIN.colTextEntryBorder = Color(52, 73, 94, 255)
	SKIN.colTextEntryText = Color(0,0,0, 255)
	SKIN.colTextEntryTextHighlight = Color(52, 152, 219, 255)
	SKIN.colTextEntryTextCursor = Color(52, 152, 219, 255)
	SKIN.colTextEntryTextPlaceholder = Color(149, 165, 166, 255)
	SKIN.colMenuBG = Color(23, 32, 48, 230)
	SKIN.colMenuBorder = Color(52, 73, 94, 220)
	SKIN.colButtonText = Color(236, 240, 241, 255)
	SKIN.colButtonTextDisabled = Color(236, 240, 241, 70)
	SKIN.colButtonBorder = Color(52, 73, 94, 255)
	SKIN.colButtonBorderHighlight = Color(52, 152, 219, 120)
	SKIN.colButtonBorderShadow = Color(0, 0, 0, 100)
	SKIN.tex = {}
	SKIN.tex.Selection = GWEN.CreateTextureBorder(384, 32, 31, 31, 4, 4, 4, 4)
	SKIN.tex.Panels = {}
	SKIN.tex.Panels.Normal = GWEN.CreateTextureBorder(256, 0, 63, 63, 16, 16, 16, 16)
	SKIN.tex.Panels.Bright = GWEN.CreateTextureBorder(256 + 64, 0, 63, 63, 16, 16, 16, 16)
	SKIN.tex.Panels.Dark = GWEN.CreateTextureBorder(256, 64, 63, 63, 16, 16, 16, 16)
	SKIN.tex.Panels.Highlight = GWEN.CreateTextureBorder(256 + 64, 64, 63, 63, 16, 16, 16, 16)
	SKIN.tex.Button = GWEN.CreateTextureBorder(480, 0, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Button_Hovered = GWEN.CreateTextureBorder(480, 32, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Button_Dead = GWEN.CreateTextureBorder(480, 64, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Button_Down = GWEN.CreateTextureBorder(480, 96, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Shadow = GWEN.CreateTextureBorder(448, 0, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Tree = GWEN.CreateTextureBorder(256, 128, 127, 127, 16, 16, 16, 16)
	SKIN.tex.Checkbox_Checked = GWEN.CreateTextureNormal(448, 32, 15, 15)
	SKIN.tex.Checkbox = GWEN.CreateTextureNormal(464, 32, 15, 15)
	SKIN.tex.CheckboxD_Checked = GWEN.CreateTextureNormal(448, 48, 15, 15)
	SKIN.tex.CheckboxD = GWEN.CreateTextureNormal(464, 48, 15, 15)
	SKIN.tex.RadioButton_Checked = GWEN.CreateTextureNormal(448, 64, 15, 15)
	SKIN.tex.RadioButton = GWEN.CreateTextureNormal(464, 64, 15, 15)
	SKIN.tex.RadioButtonD_Checked = GWEN.CreateTextureNormal(448, 80, 15, 15)
	SKIN.tex.RadioButtonD = GWEN.CreateTextureNormal(464, 80, 15, 15)
	SKIN.tex.TreePlus = GWEN.CreateTextureNormal(448, 96, 15, 15)
	SKIN.tex.TreeMinus = GWEN.CreateTextureNormal(464, 96, 15, 15)
	SKIN.tex.TextBox = GWEN.CreateTextureBorder(0, 150, 127, 21, 4, 4, 4, 4)
	SKIN.tex.TextBox_Focus = GWEN.CreateTextureBorder(0, 172, 127, 21, 4, 4, 4, 4)
	SKIN.tex.TextBox_Disabled = GWEN.CreateTextureBorder(0, 194, 127, 21, 4, 4, 4, 4)
	SKIN.tex.MenuBG_Column = GWEN.CreateTextureBorder(128, 128, 127, 63, 24, 8, 8, 8)
	SKIN.tex.MenuBG = GWEN.CreateTextureBorder(128, 192, 127, 63, 8, 8, 8, 8)
	SKIN.tex.MenuBG_Hover = GWEN.CreateTextureBorder(128, 256, 127, 31, 8, 8, 8, 8)
	SKIN.tex.MenuBG_Spacer = GWEN.CreateTextureNormal(128, 288, 127, 3)
	SKIN.tex.Menu_Strip = GWEN.CreateTextureBorder(0, 128, 127, 21, 8, 8, 8, 8)
	SKIN.tex.Menu_Check = GWEN.CreateTextureNormal(448, 112, 15, 15)
	SKIN.tex.Tab_Control = GWEN.CreateTextureBorder(0, 256, 127, 127, 8, 8, 8, 8)
	SKIN.tex.TabB_Active = GWEN.CreateTextureBorder(0, 416, 63, 31, 8, 8, 8, 8)
	SKIN.tex.TabB_Inactive = GWEN.CreateTextureBorder(128, 416, 63, 31, 8, 8, 8, 8)
	SKIN.tex.TabT_Active = GWEN.CreateTextureBorder(0, 384, 63, 31, 8, 8, 8, 8)
	SKIN.tex.TabT_Inactive = GWEN.CreateTextureBorder(128, 384, 63, 31, 8, 8, 8, 8)
	SKIN.tex.TabL_Active = GWEN.CreateTextureBorder(64, 384, 31, 63, 8, 8, 8, 8)
	SKIN.tex.TabL_Inactive = GWEN.CreateTextureBorder(64 + 128, 384, 31, 63, 8, 8, 8, 8)
	SKIN.tex.TabR_Active = GWEN.CreateTextureBorder(96, 384, 31, 63, 8, 8, 8, 8)
	SKIN.tex.TabR_Inactive = GWEN.CreateTextureBorder(96 + 128, 384, 31, 63, 8, 8, 8, 8)
	SKIN.tex.Tab_Bar = GWEN.CreateTextureBorder(128, 352, 127, 31, 4, 4, 4, 4)
	SKIN.tex.Window = {}
	SKIN.tex.Window.Normal = GWEN.CreateTextureBorder(0, 0, 127, 127, 8, 24, 8, 8)
	SKIN.tex.Window.Inactive = GWEN.CreateTextureBorder(128, 0, 127, 127, 8, 24, 8, 8)
	SKIN.tex.Window.Close = GWEN.CreateTextureNormal(32, 448, 31, 24)
	SKIN.tex.Window.Close_Hover = GWEN.CreateTextureNormal(64, 448, 31, 24)
	SKIN.tex.Window.Close_Down = GWEN.CreateTextureNormal(96, 448, 31, 24)
	SKIN.tex.Window.Maxi = GWEN.CreateTextureNormal(32 + 96 * 2, 448, 31, 24)
	SKIN.tex.Window.Maxi_Hover = GWEN.CreateTextureNormal(64 + 96 * 2, 448, 31, 24)
	SKIN.tex.Window.Maxi_Down = GWEN.CreateTextureNormal(96 + 96 * 2, 448, 31, 24)
	SKIN.tex.Window.Restore = GWEN.CreateTextureNormal(32 + 96 * 2, 448 + 32, 31, 24)
	SKIN.tex.Window.Restore_Hover = GWEN.CreateTextureNormal(64 + 96 * 2, 448 + 32, 31, 24)
	SKIN.tex.Window.Restore_Down = GWEN.CreateTextureNormal(96 + 96 * 2, 448 + 32, 31, 24)
	SKIN.tex.Window.Mini = GWEN.CreateTextureNormal(32 + 96, 448, 31, 24)
	SKIN.tex.Window.Mini_Hover = GWEN.CreateTextureNormal(64 + 96, 448, 31, 24)
	SKIN.tex.Window.Mini_Down = GWEN.CreateTextureNormal(96 + 96, 448, 31, 24)
	SKIN.tex.Scroller = {}
	SKIN.tex.Scroller.TrackV = GWEN.CreateTextureBorder(384, 208, 15, 127, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonV_Normal = GWEN.CreateTextureBorder(384 + 16, 208, 15, 127, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonV_Hover = GWEN.CreateTextureBorder(384 + 32, 208, 15, 127, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonV_Down = GWEN.CreateTextureBorder(384 + 48, 208, 15, 127, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonV_Disabled = GWEN.CreateTextureBorder(384 + 64, 208, 15, 127, 4, 4, 4, 4)
	SKIN.tex.Scroller.TrackH = GWEN.CreateTextureBorder(384, 128, 127, 15, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonH_Normal = GWEN.CreateTextureBorder(384, 128 + 16, 127, 15, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonH_Hover = GWEN.CreateTextureBorder(384, 128 + 32, 127, 15, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonH_Down = GWEN.CreateTextureBorder(384, 128 + 48, 127, 15, 4, 4, 4, 4)
	SKIN.tex.Scroller.ButtonH_Disabled = GWEN.CreateTextureBorder(384, 128 + 64, 127, 15, 4, 4, 4, 4)
	SKIN.tex.Scroller.LeftButton_Normal = GWEN.CreateTextureBorder(464, 208, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.LeftButton_Hover = GWEN.CreateTextureBorder(480, 208, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.LeftButton_Down = GWEN.CreateTextureBorder(464, 272, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.LeftButton_Disabled = GWEN.CreateTextureBorder(480 + 48, 272, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.UpButton_Normal = GWEN.CreateTextureBorder(464, 208 + 16, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.UpButton_Hover = GWEN.CreateTextureBorder(480, 208 + 16, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.UpButton_Down = GWEN.CreateTextureBorder(464, 272 + 16, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.UpButton_Disabled = GWEN.CreateTextureBorder(480 + 48, 272 + 16, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.RightButton_Normal = GWEN.CreateTextureBorder(464, 208 + 32, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.RightButton_Hover = GWEN.CreateTextureBorder(480, 208 + 32, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.RightButton_Down = GWEN.CreateTextureBorder(464, 272 + 32, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.RightButton_Disabled = GWEN.CreateTextureBorder(480 + 48, 272 + 32, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.DownButton_Normal = GWEN.CreateTextureBorder(464, 208 + 48, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.DownButton_Hover = GWEN.CreateTextureBorder(480, 208 + 48, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.DownButton_Down = GWEN.CreateTextureBorder(464, 272 + 48, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.DownButton_Disabled = GWEN.CreateTextureBorder(480 + 48, 272 + 48, 15, 15, 2, 2, 2, 2)
	SKIN.tex.Menu = {}
	SKIN.tex.Menu.RightArrow = GWEN.CreateTextureNormal(464, 112, 15, 15)
	SKIN.tex.Input = {}
	SKIN.tex.Input.ComboBox = {}
	SKIN.tex.Input.ComboBox.Normal = GWEN.CreateTextureBorder(384, 336, 127, 31, 8, 8, 32, 8)
	SKIN.tex.Input.ComboBox.Hover = GWEN.CreateTextureBorder(384, 336 + 32, 127, 31, 8, 8, 32, 8)
	SKIN.tex.Input.ComboBox.Down = GWEN.CreateTextureBorder(384, 336 + 64, 127, 31, 8, 8, 32, 8)
	SKIN.tex.Input.ComboBox.Disabled = GWEN.CreateTextureBorder(384, 336 + 96, 127, 31, 8, 8, 32, 8)
	SKIN.tex.Input.ComboBox.Button = {}
	SKIN.tex.Input.ComboBox.Button.Normal = GWEN.CreateTextureNormal(496, 272, 15, 15)
	SKIN.tex.Input.ComboBox.Button.Hover = GWEN.CreateTextureNormal(496, 272 + 16, 15, 15)
	SKIN.tex.Input.ComboBox.Button.Down = GWEN.CreateTextureNormal(496, 272 + 32, 15, 15)
	SKIN.tex.Input.ComboBox.Button.Disabled = GWEN.CreateTextureNormal(496, 272 + 48, 15, 15)
	SKIN.tex.Input.UpDown = {}
	SKIN.tex.Input.UpDown.Up = {}
	SKIN.tex.Input.UpDown.Up.Normal = GWEN.CreateTextureCentered(384, 112, 7, 7)
	SKIN.tex.Input.UpDown.Up.Hover = GWEN.CreateTextureCentered(384 + 8, 112, 7, 7)
	SKIN.tex.Input.UpDown.Up.Down = GWEN.CreateTextureCentered(384 + 16, 112, 7, 7)
	SKIN.tex.Input.UpDown.Up.Disabled = GWEN.CreateTextureCentered(384 + 24, 112, 7, 7)
	SKIN.tex.Input.UpDown.Down = {}
	SKIN.tex.Input.UpDown.Down.Normal = GWEN.CreateTextureCentered(384, 120, 7, 7)
	SKIN.tex.Input.UpDown.Down.Hover = GWEN.CreateTextureCentered(384 + 8, 120, 7, 7)
	SKIN.tex.Input.UpDown.Down.Down = GWEN.CreateTextureCentered(384 + 16, 120, 7, 7)
	SKIN.tex.Input.UpDown.Down.Disabled = GWEN.CreateTextureCentered(384 + 24, 120, 7, 7)
	SKIN.tex.Input.Slider = {}
	SKIN.tex.Input.Slider.H = {}
	SKIN.tex.Input.Slider.H.Normal = GWEN.CreateTextureNormal(416, 32, 15, 15)
	SKIN.tex.Input.Slider.H.Hover = GWEN.CreateTextureNormal(416, 32 + 16, 15, 15)
	SKIN.tex.Input.Slider.H.Down = GWEN.CreateTextureNormal(416, 32 + 32, 15, 15)
	SKIN.tex.Input.Slider.H.Disabled = GWEN.CreateTextureNormal(416, 32 + 48, 15, 15)
	SKIN.tex.Input.Slider.V = {}
	SKIN.tex.Input.Slider.V.Normal = GWEN.CreateTextureNormal(416 + 16, 32, 15, 15)
	SKIN.tex.Input.Slider.V.Hover = GWEN.CreateTextureNormal(416 + 16, 32 + 16, 15, 15)
	SKIN.tex.Input.Slider.V.Down = GWEN.CreateTextureNormal(416 + 16, 32 + 32, 15, 15)
	SKIN.tex.Input.Slider.V.Disabled = GWEN.CreateTextureNormal(416 + 16, 32 + 48, 15, 15)
	SKIN.tex.Input.ListBox = {}
	SKIN.tex.Input.ListBox.Background = GWEN.CreateTextureBorder(256, 256, 63, 127, 8, 8, 8, 8)
	SKIN.tex.Input.ListBox.Hovered = GWEN.CreateTextureBorder(320, 320, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Input.ListBox.EvenLine = GWEN.CreateTextureBorder(352, 256, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Input.ListBox.OddLine = GWEN.CreateTextureBorder(352, 288, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Input.ListBox.EvenLineSelected = GWEN.CreateTextureBorder(320, 256, 31, 31, 8, 8, 8, 8)
	SKIN.tex.Input.ListBox.OddLineSelected = GWEN.CreateTextureBorder(320, 288, 31, 31, 8, 8, 8, 8)
	SKIN.tex.ProgressBar = {}
	SKIN.tex.ProgressBar.Back = GWEN.CreateTextureBorder(384, 0, 31, 31, 8, 8, 8, 8)
	SKIN.tex.ProgressBar.Front = GWEN.CreateTextureBorder(384 + 32, 0, 31, 31, 8, 8, 8, 8)
	SKIN.tex.CategoryList = {}
	SKIN.tex.CategoryList.Outer = GWEN.CreateTextureBorder(256, 384, 63, 63, 8, 8, 8, 8)
	SKIN.tex.CategoryList.Inner = GWEN.CreateTextureBorder(320, 384, 63, 63, 8, 21, 8, 8)
	SKIN.tex.CategoryList.Header = GWEN.CreateTextureBorder(320, 352, 63, 31, 8, 8, 8, 8)
	SKIN.tex.Tooltip = GWEN.CreateTextureBorder(384, 64, 31, 31, 8, 8, 8, 8)
	SKIN.Colours = {}
	SKIN.Colours.Window = {}
	SKIN.Colours.Window.TitleActive = GWEN.TextureColor(4 + 8 * 0, 508)
	SKIN.Colours.Window.TitleInactive = GWEN.TextureColor(4 + 8 * 1, 508)
	SKIN.Colours.Button = {}
	SKIN.Colours.Button.Normal = GWEN.TextureColor(4 + 8 * 2, 508)
	SKIN.Colours.Button.Hover = GWEN.TextureColor(4 + 8 * 3, 508)
	SKIN.Colours.Button.Down = GWEN.TextureColor(4 + 8 * 2, 500)
	SKIN.Colours.Button.Disabled = GWEN.TextureColor(4 + 8 * 3, 500)
	SKIN.Colours.Tab = {}
	SKIN.Colours.Tab.Active = {}
	SKIN.Colours.Tab.Active.Normal = GWEN.TextureColor(4 + 8 * 4, 508)
	SKIN.Colours.Tab.Active.Hover = GWEN.TextureColor(4 + 8 * 5, 508)
	SKIN.Colours.Tab.Active.Down = GWEN.TextureColor(4 + 8 * 4, 500)
	SKIN.Colours.Tab.Active.Disabled = GWEN.TextureColor(4 + 8 * 5, 500)
	SKIN.Colours.Tab.Inactive = {}
	SKIN.Colours.Tab.Inactive.Normal = GWEN.TextureColor(4 + 8 * 6, 508)
	SKIN.Colours.Tab.Inactive.Hover = GWEN.TextureColor(4 + 8 * 7, 508)
	SKIN.Colours.Tab.Inactive.Down = GWEN.TextureColor(4 + 8 * 6, 500)
	SKIN.Colours.Tab.Inactive.Disabled = GWEN.TextureColor(4 + 8 * 7, 500)
	SKIN.Colours.Label = {}
	SKIN.Colours.Label.Default = GWEN.TextureColor(4 + 8 * 8, 508)
	SKIN.Colours.Label.Bright = GWEN.TextureColor(4 + 8 * 9, 508)
	SKIN.Colours.Label.Dark = GWEN.TextureColor(4 + 8 * 8, 500)
	SKIN.Colours.Label.Highlight = GWEN.TextureColor(4 + 8 * 9, 500)
	SKIN.Colours.Tree = {}
	SKIN.Colours.Tree.Lines = GWEN.TextureColor(4 + 8 * 10, 508) ---- !!!
	SKIN.Colours.Tree.Normal = GWEN.TextureColor(4 + 8 * 11, 508)
	SKIN.Colours.Tree.Hover = GWEN.TextureColor(4 + 8 * 10, 500)
	SKIN.Colours.Tree.Selected = GWEN.TextureColor(4 + 8 * 11, 500)
	SKIN.Colours.Properties = {}
	SKIN.Colours.Properties.Line_Normal = GWEN.TextureColor(4 + 8 * 12, 508)
	SKIN.Colours.Properties.Line_Selected = GWEN.TextureColor(4 + 8 * 13, 508)
	SKIN.Colours.Properties.Line_Hover = GWEN.TextureColor(4 + 8 * 12, 500)
	SKIN.Colours.Properties.Title = GWEN.TextureColor(4 + 8 * 13, 500)
	SKIN.Colours.Properties.Column_Normal = GWEN.TextureColor(4 + 8 * 14, 508)
	SKIN.Colours.Properties.Column_Selected = GWEN.TextureColor(4 + 8 * 15, 508)
	SKIN.Colours.Properties.Column_Hover = GWEN.TextureColor(4 + 8 * 14, 500)
	SKIN.Colours.Properties.Border = GWEN.TextureColor(4 + 8 * 15, 500)
	SKIN.Colours.Properties.Label_Normal = GWEN.TextureColor(4 + 8 * 16, 508)
	SKIN.Colours.Properties.Label_Selected = GWEN.TextureColor(4 + 8 * 17, 508)
	SKIN.Colours.Properties.Label_Hover = GWEN.TextureColor(4 + 8 * 16, 500)
	SKIN.Colours.Category = {}
	SKIN.Colours.Category.Header = GWEN.TextureColor(4 + 8 * 18, 500)
	SKIN.Colours.Category.Header_Closed = GWEN.TextureColor(4 + 8 * 19, 500)
	SKIN.Colours.Category.Line = {}
	SKIN.Colours.Category.Line.Text = GWEN.TextureColor(4 + 8 * 20, 508)
	SKIN.Colours.Category.Line.Text_Hover = GWEN.TextureColor(4 + 8 * 21, 508)
	SKIN.Colours.Category.Line.Text_Selected = GWEN.TextureColor(4 + 8 * 20, 500)
	SKIN.Colours.Category.Line.Button = GWEN.TextureColor(4 + 8 * 21, 500)
	SKIN.Colours.Category.Line.Button_Hover = GWEN.TextureColor(4 + 8 * 22, 508)
	SKIN.Colours.Category.Line.Button_Selected = GWEN.TextureColor(4 + 8 * 23, 508)
	SKIN.Colours.Category.LineAlt = {}
	SKIN.Colours.Category.LineAlt.Text = GWEN.TextureColor(4 + 8 * 22, 500)
	SKIN.Colours.Category.LineAlt.Text_Hover = GWEN.TextureColor(4 + 8 * 23, 500)
	SKIN.Colours.Category.LineAlt.Text_Selected = GWEN.TextureColor(4 + 8 * 24, 508)
	SKIN.Colours.Category.LineAlt.Button = GWEN.TextureColor(4 + 8 * 25, 508)
	SKIN.Colours.Category.LineAlt.Button_Hover = GWEN.TextureColor(4 + 8 * 24, 500)
	SKIN.Colours.Category.LineAlt.Button_Selected = GWEN.TextureColor(4 + 8 * 25, 500)
	SKIN.Colours.TooltipText = GWEN.TextureColor(4 + 8 * 26, 500)

	--[[---------------------------------------------------------
	Panel
	-----------------------------------------------------------]]
	function SKIN:PaintPanel(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		self.tex.Panels.Normal(0, 0, w, h, panel.m_bgColor)
	end

	--[[---------------------------------------------------------
	Panel
	-----------------------------------------------------------]]
	function SKIN:PaintShadow(panel, w, h)
		SKIN.tex.Shadow(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	Frame
	-----------------------------------------------------------]]
	function SKIN:PaintFrame(panel, w, h)
		if (panel.m_bPaintShadow) then
			DisableClipping(true)
			SKIN.tex.Shadow(-4, -4, w + 10, h + 10)
			DisableClipping(false)
		end

		if (panel:HasHierarchicalFocus()) then
			self.tex.Window.Normal(0, 0, w, h)
		else
			self.tex.Window.Inactive(0, 0, w, h)
		end
	end

	--[[---------------------------------------------------------
	Button
	-----------------------------------------------------------]]
	function SKIN:PaintButton(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel.Depressed or panel:IsSelected() or panel:GetToggle()) then
			return self.tex.Button_Down(0, 0, w, h)
		end

		if (panel:GetDisabled()) then
			return self.tex.Button_Dead(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Button_Hovered(0, 0, w, h)
		end

		self.tex.Button(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	Tree
	-----------------------------------------------------------]]
	function SKIN:PaintTree(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		self.tex.Tree(0, 0, w, h, panel.m_bgColor)
	end

	--[[---------------------------------------------------------
	CheckBox
	-----------------------------------------------------------]]
	function SKIN:PaintCheckBox(panel, w, h)
		if (panel:GetChecked()) then
			if (panel:GetDisabled()) then
				self.tex.CheckboxD_Checked(0, 0, w, h)
			else
				self.tex.Checkbox_Checked(0, 0, w, h)
			end
		else
			if (panel:GetDisabled()) then
				self.tex.CheckboxD(0, 0, w, h)
			else
				self.tex.Checkbox(0, 0, w, h)
			end
		end
	end

	--[[---------------------------------------------------------
	ExpandButton
	-----------------------------------------------------------]]
	function SKIN:PaintExpandButton(panel, w, h)
		if (not panel:GetExpanded()) then
			self.tex.TreePlus(0, 0, w, h)
		else
			self.tex.TreeMinus(0, 0, w, h)
		end
	end

	--[[---------------------------------------------------------
	TextEntry
	-----------------------------------------------------------]]
	function SKIN:PaintTextEntry(panel, w, h)
		if (panel.m_bBackground) then
			if (panel:GetDisabled()) then
				self.tex.TextBox_Disabled(0, 0, w, h)
			elseif (panel:HasFocus()) then
				self.tex.TextBox_Focus(0, 0, w, h)
			else
				self.tex.TextBox(0, 0, w, h)
			end
		end

		-- Hack on a hack, but this produces the most close appearance to what it will actually look if text was actually there
		if (panel.GetPlaceholderText and panel.GetPlaceholderColor and panel:GetPlaceholderText() and panel:GetPlaceholderText():Trim() ~= "" and panel:GetPlaceholderColor() and (not panel:GetText() or panel:GetText() == "")) then
			local oldText = panel:GetText()
			local str = panel:GetPlaceholderText()

			if (str:StartWith("#")) then
				str = str:sub(2)
			end

			str = language.GetPhrase(str)
			panel:SetText(str)
			panel:DrawTextEntryText(panel:GetPlaceholderColor(), panel:GetHighlightColor(), panel:GetCursorColor())
			panel:SetText(oldText)

			return
		end

		panel:DrawTextEntryText(panel:GetTextColor(), panel:GetHighlightColor(), panel:GetCursorColor())
	end

	--[[---------------------------------------------------------
	Menu
	-----------------------------------------------------------]]
	function SKIN:PaintMenu(panel, w, h)
		if (panel:GetDrawColumn()) then
			self.tex.MenuBG_Column(0, 0, w, h)
		else
			self.tex.MenuBG(0, 0, w, h)
		end
	end

	--[[---------------------------------------------------------
	Menu
	-----------------------------------------------------------]]
	function SKIN:PaintMenuSpacer(panel, w, h)
		surface.SetDrawColor(Color(0, 0, 0, 100))
		surface.DrawRect(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	MenuOption
	-----------------------------------------------------------]]
	function SKIN:PaintMenuOption(panel, w, h)
		if (panel.m_bBackground and not panel:IsEnabled()) then
			surface.SetDrawColor(Color(0, 0, 0, 50))
			surface.DrawRect(0, 0, w, h)
		end

		if (panel.m_bBackground and (panel.Hovered or panel.Highlight)) then
			self.tex.MenuBG_Hover(0, 0, w, h)
		end

		if (panel:GetChecked()) then
			self.tex.Menu_Check(5, h / 2 - 7, 15, 15)
		end
	end

	--[[---------------------------------------------------------
	MenuRightArrow
	-----------------------------------------------------------]]
	function SKIN:PaintMenuRightArrow(panel, w, h)
		self.tex.Menu.RightArrow(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	PropertySheet
	-----------------------------------------------------------]]
	function SKIN:PaintPropertySheet(panel, w, h)
		-- TODO: Tabs at bottom, left, right
		local ActiveTab = panel:GetActiveTab()
		local Offset = 0

		if (ActiveTab) then
			Offset = ActiveTab:GetTall() - 8
		end

		self.tex.Tab_Control(0, Offset, w, h - Offset)
	end

	--[[---------------------------------------------------------
	Tab
	-----------------------------------------------------------]]
	function SKIN:PaintTab(panel, w, h)
		if (panel:IsActive()) then
			return self:PaintActiveTab(panel, w, h)
		end

		self.tex.TabT_Inactive(0, 0, w, h)
	end

	function SKIN:PaintActiveTab(panel, w, h)
		self.tex.TabT_Active(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	Button
	-----------------------------------------------------------]]
	function SKIN:PaintWindowCloseButton(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel:GetDisabled()) then
			return self.tex.Window.Close(0, 0, w, h, Color(255, 255, 255, 50))
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Window.Close_Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Window.Close_Hover(0, 0, w, h)
		end

		self.tex.Window.Close(0, 0, w, h)
	end

	function SKIN:PaintWindowMinimizeButton(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel:GetDisabled()) then
			return self.tex.Window.Mini(0, 0, w, h, Color(255, 255, 255, 50))
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Window.Mini_Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Window.Mini_Hover(0, 0, w, h)
		end

		self.tex.Window.Mini(0, 0, w, h)
	end

	function SKIN:PaintWindowMaximizeButton(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel:GetDisabled()) then
			return self.tex.Window.Maxi(0, 0, w, h, Color(255, 255, 255, 50))
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Window.Maxi_Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Window.Maxi_Hover(0, 0, w, h)
		end

		self.tex.Window.Maxi(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	VScrollBar
	-----------------------------------------------------------]]
	function SKIN:PaintVScrollBar(panel, w, h)
		self.tex.Scroller.TrackV(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ScrollBarGrip
	-----------------------------------------------------------]]
	function SKIN:PaintScrollBarGrip(panel, w, h)
		if (panel:GetDisabled()) then
			return self.tex.Scroller.ButtonV_Disabled(0, 0, w, h)
		end

		if (panel.Depressed) then
			return self.tex.Scroller.ButtonV_Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Scroller.ButtonV_Hover(0, 0, w, h)
		end

		return self.tex.Scroller.ButtonV_Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ButtonDown
	-----------------------------------------------------------]]
	function SKIN:PaintButtonDown(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Scroller.DownButton_Down(0, 0, w, h)
		end

		if (panel:GetDisabled()) then
			return self.tex.Scroller.DownButton_Dead(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Scroller.DownButton_Hover(0, 0, w, h)
		end

		self.tex.Scroller.DownButton_Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ButtonUp
	-----------------------------------------------------------]]
	function SKIN:PaintButtonUp(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Scroller.UpButton_Down(0, 0, w, h)
		end

		if (panel:GetDisabled()) then
			return self.tex.Scroller.UpButton_Dead(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Scroller.UpButton_Hover(0, 0, w, h)
		end

		self.tex.Scroller.UpButton_Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ButtonLeft
	-----------------------------------------------------------]]
	function SKIN:PaintButtonLeft(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Scroller.LeftButton_Down(0, 0, w, h)
		end

		if (panel:GetDisabled()) then
			return self.tex.Scroller.LeftButton_Dead(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Scroller.LeftButton_Hover(0, 0, w, h)
		end

		self.tex.Scroller.LeftButton_Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ButtonRight
	-----------------------------------------------------------]]
	function SKIN:PaintButtonRight(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		if (panel.Depressed or panel:IsSelected()) then
			return self.tex.Scroller.RightButton_Down(0, 0, w, h)
		end

		if (panel:GetDisabled()) then
			return self.tex.Scroller.RightButton_Dead(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Scroller.RightButton_Hover(0, 0, w, h)
		end

		self.tex.Scroller.RightButton_Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ComboDownArrow
	-----------------------------------------------------------]]
	function SKIN:PaintComboDownArrow(panel, w, h)
		if (panel.ComboBox:GetDisabled()) then
			return self.tex.Input.ComboBox.Button.Disabled(0, 0, w, h)
		end

		if (panel.ComboBox.Depressed or panel.ComboBox:IsMenuOpen()) then
			return self.tex.Input.ComboBox.Button.Down(0, 0, w, h)
		end

		if (panel.ComboBox.Hovered) then
			return self.tex.Input.ComboBox.Button.Hover(0, 0, w, h)
		end

		self.tex.Input.ComboBox.Button.Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ComboBox
	-----------------------------------------------------------]]
	function SKIN:PaintComboBox(panel, w, h)
		if (panel:GetDisabled()) then
			return self.tex.Input.ComboBox.Disabled(0, 0, w, h)
		end

		if (panel.Depressed or panel:IsMenuOpen()) then
			return self.tex.Input.ComboBox.Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Input.ComboBox.Hover(0, 0, w, h)
		end

		self.tex.Input.ComboBox.Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	ComboBox
	-----------------------------------------------------------]]
	function SKIN:PaintListBox(panel, w, h)
		self.tex.Input.ListBox.Background(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	NumberUp
	-----------------------------------------------------------]]
	function SKIN:PaintNumberUp(panel, w, h)
		if (panel:GetDisabled()) then
			return self.tex.Input.UpDown.Up.Disabled(0, 0, w, h)
		end

		if (panel.Depressed) then
			return self.tex.Input.UpDown.Up.Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Input.UpDown.Up.Hover(0, 0, w, h)
		end

		self.tex.Input.UpDown.Up.Normal(0, 0, w, h)
	end

	--[[---------------------------------------------------------
	NumberDown
	-----------------------------------------------------------]]
	function SKIN:PaintNumberDown(panel, w, h)
		if (panel:GetDisabled()) then
			return self.tex.Input.UpDown.Down.Disabled(0, 0, w, h)
		end

		if (panel.Depressed) then
			return self.tex.Input.UpDown.Down.Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Input.UpDown.Down.Hover(0, 0, w, h)
		end

		self.tex.Input.UpDown.Down.Normal(0, 0, w, h)
	end

	function SKIN:PaintTreeNode(panel, w, h)
		if (not panel.m_bDrawLines) then
			return
		end

		surface.SetDrawColor(self.Colours.Tree.Lines)

		if (panel.m_bLastChild) then
			surface.DrawRect(9, 0, 1, 7)
			surface.DrawRect(9, 7, 9, 1)
		else
			surface.DrawRect(9, 0, 1, h)
			surface.DrawRect(9, 7, 9, 1)
		end
	end

	function SKIN:PaintTreeNodeButton(panel, w, h)
		if (not panel.m_bSelected) then
			return
		end

		-- Don't worry this isn't working out the size every render
		-- it just gets the cached value from inside the Label
		local w, _ = panel:GetTextSize()
		self.tex.Selection(38, 0, w + 6, h)
	end

	function SKIN:PaintSelection(panel, w, h)
		self.tex.Selection(0, 0, w, h)
	end

	function SKIN:PaintSliderKnob(panel, w, h)
		if (panel:GetDisabled()) then
			return self.tex.Input.Slider.H.Disabled(0, 0, w, h)
		end

		if (panel.Depressed) then
			return self.tex.Input.Slider.H.Down(0, 0, w, h)
		end

		if (panel.Hovered) then
			return self.tex.Input.Slider.H.Hover(0, 0, w, h)
		end

		self.tex.Input.Slider.H.Normal(0, 0, w, h)
	end

	local function PaintNotches(x, y, w, h, num)
		if (not num) then
			return
		end

		local space = w / num

		for i = 0, num do
			surface.DrawRect(x + i * space, y + 4, 1, 5)
		end
	end

	function SKIN:PaintNumSlider(panel, w, h)
		surface.SetDrawColor(Color(0, 0, 0, 100))
		surface.DrawRect(8, h / 2 - 1, w - 15, 1)
		PaintNotches(8, h / 2 - 1, w - 16, 1, panel.m_iNotches)
	end

	function SKIN:PaintProgress(panel, w, h)
		self.tex.ProgressBar.Back(0, 0, w, h)
		self.tex.ProgressBar.Front(0, 0, w * panel:GetFraction(), h)
	end

	function SKIN:PaintCollapsibleCategory(panel, w, h)
		if (h < 21) then
			return self.tex.CategoryList.Header(0, 0, w, h)
		end

		self.tex.CategoryList.Inner(0, 0, w, 63)
	end

	function SKIN:PaintCategoryList(panel, w, h)
		self.tex.CategoryList.Outer(0, 0, w, h, panel:GetBackgroundColor())
	end

	function SKIN:PaintCategoryButton(panel, w, h)
		if (panel.AltLine) then
			if (panel.Depressed or panel.m_bSelected) then
				surface.SetDrawColor(self.Colours.Category.LineAlt.Button_Selected)
			elseif (panel.Hovered) then
				surface.SetDrawColor(self.Colours.Category.LineAlt.Button_Hover)
			else
				surface.SetDrawColor(self.Colours.Category.LineAlt.Button)
			end
		else
			if (panel.Depressed or panel.m_bSelected) then
				surface.SetDrawColor(self.Colours.Category.Line.Button_Selected)
			elseif (panel.Hovered) then
				surface.SetDrawColor(self.Colours.Category.Line.Button_Hover)
			else
				surface.SetDrawColor(self.Colours.Category.Line.Button)
			end
		end

		surface.DrawRect(0, 0, w, h)
	end

	function SKIN:PaintListViewLine(panel, w, h)
		if (panel:IsSelected()) then
			self.tex.Input.ListBox.EvenLineSelected(0, 0, w, h)
		elseif (panel.Hovered) then
			self.tex.Input.ListBox.Hovered(0, 0, w, h)
		elseif (panel.m_bAlt) then
			self.tex.Input.ListBox.EvenLine(0, 0, w, h)
		end
	end

	function SKIN:PaintListView(panel, w, h)
		if (not panel.m_bBackground) then
			return
		end

		self.tex.Input.ListBox.Background(0, 0, w, h)
	end

	function SKIN:PaintTooltip(panel, w, h)
		self.tex.Tooltip(0, 0, w, h)
	end

	function SKIN:PaintMenuBar(panel, w, h)
		self.tex.Menu_Strip(0, 0, w, h)
	end

	derma.DefineSkin(name, "Made to look like regular VGUI", SKIN)

	if name == "default" then
		gmcore.print("Overridden default derma skin")
	else
		gmcore.print("Loaded derma skin: " .. name)
	end
end

registerSkinWithName("default")
registerSkinWithName("gl")

hook.Add("ForceDermaSkin", "gmcore.Derma.ForceSkin", function()
	return "gl"
end)

hook.Add("Initialize", "gmcore.Derma.DirtyXGUIFix", function()
	xgui.settings.skin = "gl" -- Dirty fix for forcing XGUI skin
end)

-- gmcore.print("Loaded gmcore Derma Skin")


--[[
	Overwrite for DMenuOption
	Change text color to contrast with dark theme
]]
local PANEL = {}
AccessorFunc(PANEL, "m_pMenu", "Menu")
AccessorFunc(PANEL, "m_bChecked", "Checked")
AccessorFunc(PANEL, "m_bCheckable", "IsCheckable")

function PANEL:Init()
	self:SetContentAlignment(4)
	self:SetTextInset(30, 0) -- Room for icon on left
	self:SetTextColor(Color(255, 255, 255))
	self:SetChecked(false)
end

function PANEL:SetSubMenu(menu)
	self.SubMenu = menu

	if (not IsValid(self.SubMenuArrow)) then
		self.SubMenuArrow = vgui.Create("DPanel", self)

		self.SubMenuArrow.Paint = function(panel, w, h)
			derma.SkinHook("Paint", "MenuRightArrow", panel, w, h)
		end
	end
end

function PANEL:AddSubMenu()
	local SubMenu = DermaMenu(self)
	SubMenu:SetVisible(false)
	SubMenu:SetParent(self)
	self:SetSubMenu(SubMenu)

	return SubMenu
end

function PANEL:OnCursorEntered()
	if (IsValid(self.ParentMenu)) then
		self.ParentMenu:OpenSubMenu(self, self.SubMenu)

		return
	end

	self:GetParent():OpenSubMenu(self, self.SubMenu)
end

function PANEL:OnCursorExited()
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "MenuOption", self, w, h)
	--
	-- Draw the button text
	--

	return false
end

function PANEL:OnMousePressed(mousecode)
	self.m_MenuClicking = true
	DButton.OnMousePressed(self, mousecode)
end

function PANEL:OnMouseReleased(mousecode)
	DButton.OnMouseReleased(self, mousecode)

	if (self.m_MenuClicking and mousecode == MOUSE_LEFT) then
		self.m_MenuClicking = false
		CloseDermaMenus()
	end
end

function PANEL:DoRightClick()
	if (self:GetIsCheckable()) then
		self:ToggleCheck()
	end
end

function PANEL:DoClickInternal()
	if (self:GetIsCheckable()) then
		self:ToggleCheck()
	end

	if (self.m_pMenu) then
		self.m_pMenu:OptionSelectedInternal(self)
	end
end

function PANEL:ToggleCheck()
	self:SetChecked(not self:GetChecked())
	self:OnChecked(self:GetChecked())
end

function PANEL:OnChecked(b)
end

function PANEL:PerformLayout()
	self:SizeToContents()
	self:SetWide(self:GetWide() + 30)
	local w = math.max(self:GetParent():GetWide(), self:GetWide())
	self:SetSize(w, 22)

	if (IsValid(self.SubMenuArrow)) then
		self.SubMenuArrow:SetSize(15, 15)
		self.SubMenuArrow:CenterVertical()
		self.SubMenuArrow:AlignRight(4)
	end

	DButton.PerformLayout(self)
end

function PANEL:GenerateExample()
	-- Do nothing!
end

derma.DefineControl("DMenuOption", "Menu Option Line", PANEL, "DButton")

--[[
	DLabel
	We don't allow dark text colors here! SetColor checks if color is black, and if it is, then set it to white
]]


local PANEL = {}

AccessorFunc( PANEL, "m_colText",		"TextColor" )
AccessorFunc( PANEL, "m_colTextStyle",	"TextStyleColor" )
AccessorFunc( PANEL, "m_FontName",		"Font" )

AccessorFunc( PANEL, "m_bDoubleClicking",		"DoubleClickingEnabled",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bAutoStretchVertical",	"AutoStretchVertical",		FORCE_BOOL )
AccessorFunc( PANEL, "m_bIsMenuComponent",		"IsMenu",					FORCE_BOOL )

AccessorFunc( PANEL, "m_bBackground",	"PaintBackground",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bBackground",	"DrawBackground",	FORCE_BOOL ) -- deprecated, see line above
AccessorFunc( PANEL, "m_bDisabled",		"Disabled",			FORCE_BOOL ) -- deprecated, use SetEnabled/IsEnabled isntead

AccessorFunc( PANEL, "m_bIsToggle",		"IsToggle",		FORCE_BOOL )
AccessorFunc( PANEL, "m_bToggle",		"Toggle",		FORCE_BOOL )

AccessorFunc( PANEL, "m_bBright",		"Bright",		FORCE_BOOL )
AccessorFunc( PANEL, "m_bDark",			"Dark",			FORCE_BOOL )
AccessorFunc( PANEL, "m_bHighlight",	"Highlight",	FORCE_BOOL )

function PANEL:Init()

	self:SetIsToggle( false )
	self:SetToggle( false )
	self:SetDisabled( false )
	self:SetMouseInputEnabled( false )
	self:SetKeyboardInputEnabled( false )
	self:SetDoubleClickingEnabled( true )

	-- Nicer default height
	self:SetTall( 20 )

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )

	self:SetFont( "DermaDefault" )

end

function PANEL:SetFont( strFont )

	self.m_FontName = strFont
	self:SetFontInternal( self.m_FontName )
	self:ApplySchemeSettings()

end

function PANEL:SetTextColor( clr )
	if (clr.r == 20 and clr.g == 20 and clr.b == 20) then -- Dont' allow dark labels. '20' to override traditional SKIN.dark_text
		clr = Color(255, 255, 255)
	end

	self.m_colText = clr
	self:UpdateFGColor()

end
PANEL.SetColor = PANEL.SetTextColor

function PANEL:GetColor()

	return self.m_colText || self.m_colTextStyle

end

function PANEL:UpdateFGColor()

	local col = self:GetTextStyleColor()
	if ( self:GetTextColor() ) then col = self:GetTextColor() end

	if ( !col ) then return end

	self:SetFGColor( col.r, col.g, col.b, col.a )

end

function PANEL:Toggle()

	if ( !self:GetIsToggle() ) then return end

	self:SetToggle( !self:GetToggle() )
	self:OnToggled( self:GetToggle() )

end

function PANEL:SetDisabled( bDisabled )

	self.m_bDisabled = bDisabled
	self:InvalidateLayout()

end

function PANEL:SetEnabled( bEnabled )

	self:SetDisabled( !bEnabled )

end

function PANEL:IsEnabled()

	return !self:GetDisabled()

end

function PANEL:UpdateColours( skin )

	if ( self:GetBright() ) then return self:SetTextStyleColor( skin.Colours.Label.Bright ) end
	if ( self:GetDark() ) then return self:SetTextStyleColor( skin.Colours.Label.Dark ) end
	if ( self:GetHighlight() ) then return self:SetTextStyleColor( skin.Colours.Label.Highlight ) end

	return self:SetTextStyleColor( skin.Colours.Label.Default )

end

function PANEL:ApplySchemeSettings()

	self:UpdateColours( self:GetSkin() )

	self:UpdateFGColor()

end

function PANEL:Think()

	if ( self:GetAutoStretchVertical() ) then
		self:SizeToContentsY()
	end

end

function PANEL:PerformLayout()

	self:ApplySchemeSettings()

end


function PANEL:OnCursorEntered()

	self:InvalidateLayout( true )

end

function PANEL:OnCursorExited()

	self:InvalidateLayout( true )

end

function PANEL:OnMousePressed( mousecode )

	if ( self:GetDisabled() ) then return end

	if ( mousecode == MOUSE_LEFT && !dragndrop.IsDragging() && self.m_bDoubleClicking ) then

		if ( self.LastClickTime && SysTime() - self.LastClickTime < 0.2 ) then

			self:DoDoubleClickInternal()
			self:DoDoubleClick()

			return

		end

		self.LastClickTime = SysTime()

	end

	-- If we're selectable and have shift held down then go up
	-- the parent until we find a selection canvas and start box selection
	if ( self:IsSelectable() && mousecode == MOUSE_LEFT && input.IsShiftDown() ) then

		return self:StartBoxSelection()

	end

	self:MouseCapture( true )
	self.Depressed = true
	self:OnDepressed()
	self:InvalidateLayout( true )

	--
	-- Tell DragNDrop that we're down, and might start getting dragged!
	--
	self:DragMousePress( mousecode )

end

function PANEL:OnMouseReleased( mousecode )

	self:MouseCapture( false )

	if ( self:GetDisabled() ) then return end
	if ( !self.Depressed && dragndrop.m_DraggingMain != self ) then return end

	if ( self.Depressed ) then
		self.Depressed = nil
		self:OnReleased()
		self:InvalidateLayout( true )
	end

	--
	-- If we were being dragged then don't do the default behaviour!
	--
	if ( self:DragMouseRelease( mousecode ) ) then
		return
	end

	if ( self:IsSelectable() && mousecode == MOUSE_LEFT ) then

		local canvas = self:GetSelectionCanvas()
		if ( canvas ) then
			canvas:UnselectAll()
		end

	end

	if ( !self.Hovered ) then return end

	--
	-- For the purposes of these callbacks we want to
	-- keep depressed true. This helps us out in controls
	-- like the checkbox in the properties dialog. Because
	-- the properties dialog will only manually change the value
	-- if IsEditing() is true - and the only way to work out if
	-- a label/button based control is editing is when it's depressed.
	--
	self.Depressed = true

	if ( mousecode == MOUSE_RIGHT ) then
		self:DoRightClick()
	end

	if ( mousecode == MOUSE_LEFT ) then
		self:DoClickInternal()
		self:DoClick()
	end

	if ( mousecode == MOUSE_MIDDLE ) then
		self:DoMiddleClick()
	end

	self.Depressed = nil

end

function PANEL:OnReleased()
end

function PANEL:OnDepressed()
end

function PANEL:OnToggled( bool )
end

function PANEL:DoClick()

	self:Toggle()

end

function PANEL:DoRightClick()
end

function PANEL:DoMiddleClick()
end

function PANEL:DoClickInternal()
end

function PANEL:DoDoubleClick()
end

function PANEL:DoDoubleClickInternal()
end

function PANEL:GenerateExample( ClassName, PropertySheet, Width, Height )

	local ctrl = vgui.Create( ClassName )
	ctrl:SetText( "This is a label example." )
	ctrl:SizeToContents()

	PropertySheet:AddSheet( ClassName, ctrl, nil, true, true )

end

derma.DefineControl( "DLabel", "A Label", PANEL, "Label" )
