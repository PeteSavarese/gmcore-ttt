Damagelog.SQLiteDatabase = {}

function Damagelog.SQLiteDatabase.Query(queryString)
	local result = sql.Query(queryString)
	if(result == false) then
		local errorLog = string.format(
			"[%s] Error performing SQLite query:\n%s\n[SQL Error] %s\n\n",
			util.DateStamp(),
			queryString,
			sql.LastError())

		file.Append("tttdamagelogs-sql-errors.txt", errorLog)

		local queryShort = queryString
		if(string.len(queryShort) > 20) then queryShort = string.sub(queryString, 1, 20) .. "..." end

		local errorMessage = string.format(
			"Error performing SQLite query\nCheck garrysmod/data/tttdamagelogs-sql-errors.txt (%s)\n%s - %s",
			util.DateStamp(),
			queryShort,
			sql.LastError())

		assert(false, errorMessage)
	end

	return result
end

function Damagelog.SQLiteDatabase.QuerySingle(queryString)
	local result = Damagelog.SQLiteDatabase.Query(queryString)
	if result == nil then return nil end

	return result[1]
end

function Damagelog.SQLiteDatabase.QueryValue(queryString)
	local result = Damagelog.SQLiteDatabase.QuerySingle(queryString)
	if result == nil then return nil end

	for k, v in pairs(result) do return v end
	return result
end
