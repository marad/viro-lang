local env = require("viro.env")
local types = require("viro.types")
local eval_block = require("viro.processor")
require("viro.util")

local default = env.new()

default.none = types.none
default["true"] = types.trueval
default["false"] = types.falseval

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

local function create_context_fn(field_name)
	return types.makeFn(function(_, value)
		if value[field_name] == nil then
			error("'" .. field_name .. "' not implemented for type " .. value.type)
		else
			return value[field_name](value)
		end
	end, 1)
end

default.copy = create_context_fn("copy")
default.mold = create_context_fn("mold")
default.form = create_context_fn("form")
default.next = create_context_fn("next")
default.back = create_context_fn("back")
default.head = create_context_fn("head")
default.tail = create_context_fn("tail")
default["head?"] = create_context_fn("is_head")
default["tail?"] = create_context_fn("is_tail")

default["do"] = types.makeFn(function(ctx, value)
	if value.type ~= types.block then
		return value
	else
		return eval_block(value, ctx)
	end
end, 1)

return default
