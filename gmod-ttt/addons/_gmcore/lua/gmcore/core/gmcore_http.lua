
---@type fun(req: HTTPReqwest)
---@diagnostic disable-next-line: lowercase-global
reqwest = nil

require("reqwest")

---@class HTTP_Ext
---@field blocking? boolean

---@alias HTTPReqwest HTTPRequest | HTTP_Ext
