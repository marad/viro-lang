local env = require("viro.env")
local types = require("viro.types")
local eval_block = require("viro.processor")
require("viro.util")

local default = env.new()
local none = types.makeWord("none")
local trueval = types.makeWord("true")
local falseval = types.makeWord("false")

default.none = none
default["true"] = trueval
default["false"] = falseval

default.mold = types.makeFn(function(ctx, value)
	if value.type == types.word then
		return types.makeString(value.name)
	elseif value.type == types.set_word then
		return types.makeString(value.word.name .. ":")
	elseif value.type == types.block then
		local parts = {}
		local index = value.index
		--for _, val in ipairs(value.value) do
		while index <= #value.value do
			local val = value.value[index]
			index = index + 1
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
		local index = value.index
		--for _, val in ipairs(value.value) do
		while index <= #value.value do
			local val = value.value[index]
			table.insert(parts, default.form.fn(ctx, val).value)
			index = index + 1
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

default.reduce = types.makeFn(function(ctx, value)
	if value.type == types.block then
		-- something
		
	else
		return value
	end
end, 1)

default.print = types.makeFn(function(ctx, value)
	local str = default.form.fn(ctx, value).value
	print(str)
	return none
end, 1)

-- default.compose

--default.reduce = types.makeFn(function(ctx, value)
--	if value.type == types.block then
--		local parts = {}
--		
--		return parts
--	else
--		return value
--	end
--end)
--

-- TODO: ?,reduce, compose, next, back

default.copy = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return block:copy()
	end
end, 1)

default.next = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return block:next()
	end
end, 1)

default.back = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return block:back()
	end
end, 1)

default.head = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return block:head()
	end
end, 1)

default.tail = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return block:tail()
	end
end, 1)

default["tail?"] = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		if block:is_tail() then
			return trueval
		else
			return falseval
		end
	end
end, 1)

default["head?"] = types.makeFn(function(_, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		if block:is_head() then
			return trueval
		else
			return falseval
		end
	end
end, 1)

default["do"] = types.makeFn(function(ctx, block)
	if block.type ~= types.block then
		error("next requires a block as a parameter")
	else
		return eval_block(block, ctx)
	end
end, 1)

return default
