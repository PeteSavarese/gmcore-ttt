if file.Exists("damagelog/filters_v3.txt", "DATA") and not Damagelog.disabled_filters then
	local settings = file.Read("damagelog/filters_v3.txt", "DATA")

	if settings then
		Damagelog.disabled_filters = util.JSONToTable(settings) or {}
	end
end

function Damagelog:SaveFilters()
	file.Write("damagelog/filters_v3.txt", util.TableToJSON(self.disabled_filters or {}))
end

Damagelog.filters = Damagelog.filters or {}
Damagelog.disabled_filters = Damagelog.disabled_filters or {}
DAMAGELOG_FILTER_BOOL = 1
DAMAGELOG_FILTER_PLAYER = 2

function Damagelog:AddFilter(name, filter_type, default_value)
	self.filters[name] = filter_type
end

function Damagelog:IsFilterEnabled(name)
	return not self.disabled_filters[name]
end