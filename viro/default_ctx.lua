local env = require("viro.env")
local types = require("viro.types")
require("viro.util")

local default = env.new()
local none = types.makeWord("none")

default.none = none

default.mold = types.makeFn(function(ctx, value)
	if value.type == types.word then
		return types.makeString(value.name)
	elseif value.type == types.set_word then
		return types.makeString(value.word.name .. ":")
	elseif value.type == types.block then
		local parts = {}
		for _, val in ipairs(value.value) do
			table.insert(parts, default.mold.fn(ctx, val).value)
		end
		return types.makeString("[" .. table.concat(parts, " ") .. "]")
	elseif value.type == types.string then
		-- TODO: choose to use {} or "" based on the contents of the string
		return types.makeString('"' .. value.value .. '"')
	elseif value.type == types.number then
		return types.makeString(tostring(value.value))
	end
end, 1)

default.form = types.makeFn(function(ctx, value)
	if value.type == types.word then
		return types.makeString(value.name)
	elseif value.type == types.set_path then
		return types.makeString(value.word.name .. ":")
	elseif value.type == types.block then
		local parts = {}
		for _, val in ipairs(value.value) do
			table.insert(parts, default.form.fn(ctx, val).value)
		end
		return types.makeString(table.concat(parts, " "))
	elseif value.type == types.string then
		return types.makeString(value.value)
	elseif value.type == types.number then
		return types.makeString(tostring(value.value))
	end
end, 1)

default.rejoin = types.makeFn(function(ctx, value)
	if value.type ~= types.block then
		error("rejoin requires a block as a parameter")
	else
		local parts = {}
		for _, val in ipairs(value.value) do
			table.insert(parts, tostring(default.form.fn(ctx, val).value))
		end
		return types.makeString(table.concat(parts, ""))
	end
end, 1)

default.print = types.makeFn(function(ctx, value)
	if value.type == types.block then
		local parts = {}
		for _, val in ipairs(value.value) do
			table.insert(parts, tostring(default.form.fn(ctx, val).value))
		end
		print(table.concat(parts, " "))
	else
		local str = default.form.fn(ctx, value).value
		print(str)
	end
	return none
end, 1)

return default
