local FONT_LIST_HEADER = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 18,
	weight = 600,
	antialias = true,
})

local FONT_LIST_ROW = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 16,
	weight = 500,
	antialias = true,
})

local LIST_ROW_BG = Color(30, 42, 56, 255)
local LIST_ROW_BG_ALT = Color(26, 36, 50, 255)
local LIST_ROW_HOVER = Color(36, 51, 67, 240)
local LIST_ROW_SELECTED = Color(52, 152, 219, 40)

local HEADER_HEIGHT = 40
local ROW_HEIGHT = 38
local ROW_GAP = 4
local TABLE_INSET = 0
local CELL_PADDING = 12
local HEADER_TEXT_PADDING = 12

---@class gmcoreListViewRow : DPanel
local ROW = {}

function ROW:Init()
	self.Cells = {}
	self.Values = {}
	self.Owner = nil
	self.LineID = 0
	self:SetTall(ROW_HEIGHT)
	self:SetCursor("hand")
end

function ROW:SetOwner(owner)
	self.Owner = owner
end

function ROW:SetValues(values)
	self.Values = values or {}
	self:SyncCells()
end

function ROW:GetValue(index)
	return self.Values[index]
end

function ROW:SetValue(index, value)
	self.Values[index] = value
	self:SyncCells()
end

function ROW:GetColumnText(index)
	return tostring(self.Values[index] or "")
end

function ROW:GetListView()
	return self.Owner
end

function ROW:SetSelected(state)
	if not self.Owner then
		self.Selected = state and true or false
		return
	end

	if state then
		self.Owner:SetSelectedRow(self)
	else
		if self.Owner.SelectedRow == self then
			self.Owner.SelectedRow = nil
		end
		self.Selected = false
	end
end

function ROW:IsLineSelected()
	return self.Selected == true
end

function ROW:IsSelected()
	return self.Selected == true
end

function ROW:SyncCells()
	if not self.Owner then return end

	for i = 1, #self.Owner.Columns do
		if not IsValid(self.Cells[i]) then
			local label = vgui.Create("DLabel", self)
			label:SetFont(FONT_LIST_ROW)
			label:SetTextColor(BTN_UNFOCUSED_TEXT_COLOR)
			label:SetContentAlignment(4)
			label:SetText("")
			self.Cells[i] = label
		end

		self.Cells[i]:SetText(tostring(self.Values[i] or ""))
	end

	self.Columns = self.Cells
end

function ROW:SetColumnWidths(widths, offset, cellPadding)
	self:SyncCells()

	local x = offset or 0
	local rowH = self:GetTall()
	local pad = cellPadding or 0

	for i, width in ipairs(widths) do
		local label = self.Cells[i]
		if IsValid(label) then
			local paddedWidth = math.max(width - (pad * 2), 0)
			label:SetPos(x + pad, 0)
			label:SetSize(paddedWidth, rowH)
		end
		x = x + width
	end
end

function ROW:Paint(w, h)
	local base = (self.LineID % 2 == 0) and LIST_ROW_BG_ALT or LIST_ROW_BG
	draw.RoundedBox(6, 0, 0, w, h, base)

	if self.Selected then
		draw.RoundedBox(6, 0, 0, w, h, LIST_ROW_SELECTED)
		surface.SetDrawColor(BUTTON_ACCENT_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	elseif self.Hovered then
		draw.RoundedBox(6, 0, 0, w, h, LIST_ROW_HOVER)
	end
end

function ROW:OnMousePressed(code)
	if not self.Owner then return end

	if code == MOUSE_RIGHT then
		if self.Owner.OnRowRightClick then
			self.Owner:OnRowRightClick(self.LineID, self)
		end
	elseif code == MOUSE_LEFT then
		self.Owner:SetSelectedRow(self)
	end
end

vgui.Register("GmcoreListViewRow", ROW, "DPanel")

---@class gmcoreListView : DPanel
local PANEL = {}

function PANEL:Init()
	self.Columns = {}
	self.Rows = {}
	self.Lines = self.Rows
	self.SelectedRow = nil
	self.RowHeight = ROW_HEIGHT
	self.SortColumn = nil
	self.SortDesc = false

	self.Header = vgui.Create("DPanel", self)
	self.Header:SetTall(HEADER_HEIGHT)
	self.Header.Paint = function(s, w, h)
		draw.RoundedBoxEx(8, 0, 0, w, h, FRAME_HEADER_COLOR, true, true, false, false)
		surface.SetDrawColor(FRAME_BORDER_COLOR)
		surface.DrawRect(0, h - 1, w, 1)
	end

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.List = vgui.Create("DListLayout", self.Scroll)
	self.List:Dock(FILL)
	self.VBar = self.Scroll:GetVBar()

	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
end

function PANEL:PerformLayout(w, h)
	self.Header:Dock(TOP)
	self.Scroll:Dock(FILL)
	self:UpdateColumnLayout()
end

function PANEL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, CARD_BACKGROUND_COLOR)
	surface.SetDrawColor(CARD_BORDER_COLOR)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function PANEL:SetRowHeight(height)
	self.RowHeight = height
	for _, row in ipairs(self.Rows) do
		if IsValid(row) then
			row:SetTall(height)
		end
	end
end

function PANEL:AddColumn(title)
	local columnIndex = #self.Columns + 1
	local column = {
		Title = title,
		Width = nil,
		FixedWidth = nil,
		MaxWidth = nil,
		Button = nil,
		Owner = self,
	}

	function column:SetFixedWidth(width)
		self.FixedWidth = width
		self.Width = width
		if IsValid(self.Owner) then
			self.Owner:InvalidateLayout(true)
		end
		return self
	end

	function column:SetMaxWidth(width)
		self.MaxWidth = width
		self.Width = width
		if IsValid(self.Owner) then
			self.Owner:InvalidateLayout(true)
		end
		return self
	end

	function column:SetWidth(width)
		self.Width = width
		if IsValid(self.Owner) then
			self.Owner:InvalidateLayout(true)
		end
		return self
	end

	column.Button = vgui.Create("DButton", self.Header)
	column.Button:SetFont(FONT_LIST_HEADER)
	column.Button:SetText("")
	column.Button:SetCursor("hand")
	column.Button.Paint = function(btn, w, h)
		if btn.Depressed or btn:IsDown() then
			draw.RoundedBox(0, 0, 0, w, h, Color(22, 30, 42, 200))
		elseif btn.Hovered then
			draw.RoundedBox(0, 0, 0, w, h, Color(36, 51, 67, 180))
		end

		local text = column.Title or ""
		draw.SimpleText(text, FONT_LIST_HEADER, HEADER_TEXT_PADDING, h * 0.5, CARD_TITLE_TEXT_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		if self.SortColumn == columnIndex then
			local indicator = self.SortDesc and "v" or "^"
			draw.SimpleText(indicator, FONT_LIST_HEADER, w - HEADER_TEXT_PADDING, h * 0.5, BTN_UNFOCUSED_TEXT_COLOR, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
	column.Button.DoClick = function()
		if not IsValid(self) then return end
		self:SortByColumn(columnIndex)
	end

	table.insert(self.Columns, column)
	self:InvalidateLayout(true)

	return column
end

function PANEL:AddLine(...)
	local values = {...}
	local row = vgui.Create("GmcoreListViewRow", self.List)
	row:SetOwner(self)
	row.LineID = #self.Rows + 1
	row:SetTall(self.RowHeight)
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, ROW_GAP)
	row:SetValues(values)

	self.Rows[row.LineID] = row
	self.Lines = self.Rows
	self:UpdateColumnLayout()

	return row
end

local function tryNumber(value)
	if value == nil then return nil end
	if isnumber(value) then return value end
	local text = tostring(value):match("^%s*(.-)%s*$")
	if text == "" then return nil end
	if text:match("^%-?%d+%.?%d*$") then
		return tonumber(text)
	end
	return nil
end

function PANEL:SortByColumn(index)
	if not index or not self.Columns[index] then return end

	if self.SortColumn == index then
		self.SortDesc = not self.SortDesc
	else
		self.SortColumn = index
		self.SortDesc = false
	end

	local desc = self.SortDesc

	table.sort(self.Rows, function(a, b)
		if not IsValid(a) or not IsValid(b) then return false end
		local av = a:GetValue(index)
		local bv = b:GetValue(index)

		local an = tryNumber(av)
		local bn = tryNumber(bv)

		if an ~= nil and bn ~= nil then
			if desc then return an > bn end
			return an < bn
		end

		local as = tostring(av or ""):lower()
		local bs = tostring(bv or ""):lower()

		if desc then return as > bs end
		return as < bs
	end)

	for i, row in ipairs(self.Rows) do
		if IsValid(row) then
			row.LineID = i
			row:SetZPos(i)
		end
	end

	self:UpdateColumnLayout()
	self.List:InvalidateLayout(true)
end

function PANEL:Clear()
	for _, row in ipairs(self.Rows) do
		if IsValid(row) then
			row:Remove()
		end
	end
	self.Rows = {}
	self.Lines = self.Rows
	self.SelectedRow = nil
end

function PANEL:GetSelected()
	if IsValid(self.SelectedRow) then
		return {self.SelectedRow}
	end
	return {}
end

function PANEL:SetMultiSelect(_)
end

function PANEL:SetSelectedRow(row)
	if IsValid(self.SelectedRow) then
		self.SelectedRow.Selected = false
	end

	self.SelectedRow = row

	if IsValid(row) then
		row.Selected = true
	end

	if self.OnRowSelected and IsValid(row) then
		self:OnRowSelected(row.LineID, row)
	end
end

function PANEL:UpdateColumnLayout()
	if #self.Columns == 0 then return end

	local totalWidth = math.max(self:GetWide() - (TABLE_INSET * 2), 0)
	local fixedWidth = 0
	local flexible = 0

	for _, column in ipairs(self.Columns) do
		if column.FixedWidth or column.Width then
			fixedWidth = fixedWidth + (column.FixedWidth or column.Width)
		else
			flexible = flexible + 1
		end
	end

	local remaining = math.max(totalWidth - fixedWidth, 0)
	local flexibleWidth = flexible > 0 and math.floor(remaining / flexible) or 0

	local widths = {}
	for i, column in ipairs(self.Columns) do
		local width = column.FixedWidth or column.Width or flexibleWidth

		if column.MaxWidth and width > column.MaxWidth then
			width = column.MaxWidth
		end

		widths[i] = width
	end

	local headerH = self.Header:GetTall()
	local x = TABLE_INSET

	for i, column in ipairs(self.Columns) do
		if IsValid(column.Button) then
			column.Button:SetPos(x, 0)
			column.Button:SetSize(widths[i], headerH)
		end
		x = x + widths[i]
	end

	for _, row in ipairs(self.Rows) do
		if IsValid(row) then
			row:SetColumnWidths(widths, TABLE_INSET, CELL_PADDING)
		end
	end
end

vgui.Register("GmcoreListView", PANEL, "DPanel")
