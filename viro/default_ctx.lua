local env = require("viro.env")
local types = require("viro.types")
local evaluator = require("viro.processor")
local parser = require("viro.parser")
require("viro.util")

local default = env.new()

default.none = types.none
default["true"] = types.trueval
default["false"] = types.falseval

default["+"] = types.makeFn(function(ctx, a, b)
	return types.makeNumber(a.value + b.value)
end, 2)

default["-"] = types.makeFn(function(ctx, a, b)
	return types.makeNumber(a.value - b.value)
end, 2)

default["*"] = types.makeFn(function(ctx, a, b)
	return types.makeNumber(a.value * b.value)
end, 2)

default["/"] = types.makeFn(function(ctx, a, b)
	return types.makeNumber(a.value + b.value)
end, 2)

default.make = types.makeFn(function(ctx, proto, definition)
	if proto.name == types.object then
		local object = env.new(ctx)
		evaluator.eval_block(definition, object)
		return types.makeObject(object)
	else
		error("Making " .. proto .. " is not yet supported!")
	end
end, 2)

default["get-context"] = types.makeFn(function(ctx)
	return types.makeObject(ctx)
end, 0)

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
		local index = 1
		local results = {}
		while index <= #value.value do
			local result
			result, index = evaluator.eval_expr(value, index, ctx)
			table.insert(results, result)
		end
		return types.makeBlock(results)
	else
		return value
	end
end, 1)

default.print = types.makeFn(function(ctx, value)
	local str = default.form.fn(ctx, default.reduce.fn(ctx, value)).value
	print(str)
	return types.none
end, 1)

default.probe = types.makeFn(function(ctx, value)
	local str = default.mold.fn(ctx, value).value
	print(str)
	return value
end, 1)

default.load = types.makeFn(function(ctx, value)
	if value.type == types.string then
		return parser.parse(value.value)
	elseif value.type == types.file then
		return parser.parse(default.read.fn(ctx, value).value)
	else
		error("Load requires string! or file! argument")
	end
end, 1)

default["type?"] = types.makeFn(function(_, value)
	return types.makeString(value.type)
end, 1)

default["kind?"] = types.makeFn(function(_, value)
	return types.makeString(value.kind)
end, 1)

default["to"] = types.makeFn(function(_, type, value)
end, 1)

default.char = types.makeFn(function(_, value)
	return types.makeString(utf8.char(value.value))
end, 1)

default["to-file"] = types.makeFn(function(_, value)
	value.type = types.file
	return value
end, 1)

default.read = types.makeFn(function(_, value)
	assert(value.type == types.file, "Read requires '".. types.file .."' type")
	local f = assert(io.open(value.value, "rb"))
	local content = f:read("*all")
	f:close()
	return types.makeString(content)
end, 1)

default.save = types.makeFn(function(ctx, file, value)
	assert(file.type == types.file, "Save requires '".. types.file .."' type")
	local f = assert(io.open(file.value, "wb"))
	local s = default.mold.fn(ctx, value).value
	s = s:gsub("^[[]", ""):gsub("]$", "")
	f:write(s)
	f:close()
	return types.none
end, 2)

default.fn = types.makeFn(function(def_ctx, args, body)
	local arg_count = #args.value
	return types.makeFn(function(ctx, ...)
		local fn_ctx = {}
		setmetatable(fn_ctx, { __index = def_ctx })
		local params = table.pack(...)
		for idx = 1, arg_count, 1 do
			fn_ctx[args.value[idx].name] = params[idx]
		end
		return evaluator.eval_block(body, fn_ctx)
	end, arg_count)
end, 2)

-- TODO: ?, compose


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
default.sort = dispatch_fn_on_type { method_name = "sort" }


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
		return evaluator.eval_block(value, ctx)
	elseif value.type == types.string then
		local block = parser.parse(value.value)
		return evaluator.eval_block(block, ctx)
	elseif value.type == types.file then
		local code = default.read.fn(ctx, value)
		local block = parser.parse(code.value)
		return evaluator.eval_block(block, ctx)
	else
		return value
	end
end, 1)

default.lua = types.makeFn(function(ctx, value)
	assert(value.type == types.string, "Expected string argument")
	local f = load(value.value)
	f()
	return types.none
end, 1)

default["if"] = types.makeFn(function(ctx, cond, body)
	if cond ~= types.none and cond ~= types.falseval then
		return evaluator.eval_block(body, ctx)
	end
	return types.none
end, 2)

default["either"] = types.makeFn(function(ctx, cond, then_body, else_body)
	assert(then_body.type == types.block, "Then branch should be a block")
	assert(else_body.type == types.block, "Else branch should be a block")
	if cond ~= types.none and cond ~= types.falseval then
		return evaluator.eval_block(then_body, ctx)
	else
		return evaluator.eval_block(else_body, ctx)
	end
end, 3)


default["forever"] = types.makeFn(function(ctx, body)
	assert(body.type == types.block, "Loop body should be a block")
	function run_loop()
		while true do 
			evaluator.eval_block(body, ctx)
		end
	end
	local co = coroutine.create(run_loop)
	coroutine.resume(co)
	coroutine.close(co)
	return types.none
end, 1)

default["break"] = types.makeFn(function(ctx)
	local _, is_main = coroutine.running()
	if is_main then
		error("Cannot use break outside the loop")
	end
	coroutine.yield()
end, 0)

return default
