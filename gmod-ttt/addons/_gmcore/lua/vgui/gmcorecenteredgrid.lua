
---@class gmcoreCenteredGrid : DPanel
local PANEL = {}

function PANEL:Init()
	self:SetChildWidth(64)
	self:SetChildHeight(64)
	self:SetChildPadding(8)
end

function PANEL:SetChildWidth(w) self.m_ChildWidth = w end
function PANEL:GetChildWidth() return self.m_ChildWidth end

function PANEL:SetChildHeight(h) self.m_ChildHeight = h end
function PANEL:GetChildHeight() return self.m_ChildHeight end

function PANEL:SetChildPadding(p) self.m_ChildPadding = p end
function PANEL:GetChildPadding() return self.m_ChildPadding end

function PANEL:SetCanLayout(flag)
	self.m_LayoutAllowed = flag

	if flag then
		self:InvalidateLayout()
	end
end

function PANEL:Paint(w, h)

end

function PANEL:PerformLayout(w, h)

	local count = self:ChildCount()
	local maxrow = math.floor(w / (self.m_ChildWidth + self.m_ChildPadding))
	local rows = math.ceil(count / maxrow)

	local index = 0
	for ri = 1, rows do
		local rowcount = math.min(count - index, maxrow)
		for i = 1, math.min(count - index, maxrow) do
			index = index + 1

			local pnl = self:GetChild(index - 1)
			pnl:SetSize(self.m_ChildWidth, self.m_ChildHeight)

			local row_width = (rowcount * self.m_ChildWidth) + ((rowcount - 1) * self.m_ChildPadding)
			local row_offset = (w - row_width) / 2

			pnl:SetPos(
				(i - 1) * (self.m_ChildWidth + self.m_ChildPadding) + row_offset,
				(ri - 1) * (self.m_ChildHeight + self.m_ChildPadding))

		end

		ri = ri + 1
	end
end

vgui.Register("GmcoreCenteredGrid", PANEL, "DPanel")
