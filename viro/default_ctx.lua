local env = require("viro.env")
local types = require("viro.types")
local eval_block = require("viro.processor")
local parser = require("viro.parser")
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
	return types.none
end, 1)

default.probe = types.makeFn(function(ctx, value)
	local str = default.mold.fn(ctx, value).value
	print(str)
	return value
end, 1)

default.load = types.makeFn(function(_, value)
	return parser.parse(value.value).value[1]
end, 1)

default["type?"] = types.makeFn(function(_, value)
	return types.makeString(value.type)
end, 1)

default.char = types.makeFn(function(_, value)
	return types.makeString(utf8.char(value.value))
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


---@param config table Dispatch configuration.
--- Available config fields:
--- - method_name: string -  name of the method to dispatch
--- - wrapper_fn: function - (optional) if present it will be used to transform the result
--- - arg_count: number - (optional) number of arguments, must be at least 1
local function dispatch_fn_on_type(config)
	local arg_count = config.arg_count or 1
	assert(arg_count >= 1, "Type-dispatched methods need at least one argument.")
	local method_name = config.method_name
	assert(method_name ~= nil, "Method name is required")

	if config.wrapper_fn then
		return types.makeFn(function(_, value, ...)
			local method = value[method_name]
			if method ~= nil then
				return config.wrapper_fn(method(value, ...))
			else
				error("'" .. method_name .. "' not supported for " .. value.type .. " type")
			end
		end, arg_count)
	else
		return types.makeFn(function(_, value, ...)
			local method = value[method_name]
			if method ~= nil then 
				return method(value, ...)
			else
				error("'" .. method_name .. "' not supported for " .. value.type .. " type")
			end
		end, arg_count)
	end
end

-- creation functions
default.copy = dispatch_fn_on_type { method_name = "copy" }
-- make

-- Navigation functions
default.next = dispatch_fn_on_type { method_name = "next" }
default.back = dispatch_fn_on_type { method_name = "back" }
default.head = dispatch_fn_on_type { method_name = "head" }
default.tail = dispatch_fn_on_type { method_name = "tail" }
default.skip = dispatch_fn_on_type { method_name = "skip", arg_count = 2 }
default.at = dispatch_fn_on_type { method_name = "at", arg_count = 2}


-- Information functions
default["head?"] = dispatch_fn_on_type { method_name = "is_head" }
default["tail?"] = dispatch_fn_on_type { method_name = "is_tail" }
default["length?"] = dispatch_fn_on_type { method_name = "length", wrapper_fn = types.makeNumber }
default["index?"] = types.makeFn(function(_, value)
	if value.index ~= nil then
		return types.makeNumber(value.index)
	else
		error("'index?' is not supported for type " .. value.type)
	end
end, 1)
default["offset?"] = types.makeFn(function(_, a, b)
	if a.index == nil then error(a.type .. "does not support indexing") end
	if b.index == nil then error(b.type .. "does not support indexing") end
	return types.makeNumber(b.index - a.index)
end, 2)
default["empty?"] = dispatch_fn_on_type { method_name = "is_empty" }


-- Extraction functions 
default.pick = dispatch_fn_on_type { method_name = "pick", arg_count = 2 }
-- copy/part 
-- first
-- second 
-- third
-- fourth
-- fifth
-- last


-- Modification functions 
-- insert 
-- append
-- remove
-- clear
-- change
-- poke


-- Search functions
-- find 
-- select
-- replace 
-- parse


-- Ordering functions 
-- sort 
-- reverse


-- Set functions 
-- unique 
-- intersect 
-- union 
-- exclude
-- difference



-- General functions
default.mold = dispatch_fn_on_type { method_name = "mold" }
default.form = dispatch_fn_on_type { method_name = "form" }

default["do"] = types.makeFn(function(ctx, value)
	if value.type == types.block then
		return eval_block(value, ctx)
	elseif value.type == types.string then
		local block = parser.parse(value.value)
		return eval_block(block, ctx)
	else
		return value
	end
end, 1)

return default
