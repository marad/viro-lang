require("spec")
require("viro.util")
local parser = require("viro.parser")
local reader = require("viro.reader")
local types = require("viro.types")
local assert = require("luassert")

local function read_expr_in_ctx(ctx, code)
	ctx = ctx or {}
	local block = parser.parse(code)
	local _, result = reader.read_expr(ctx, block)
	return result
end

local function read_expr(code)
	return read_expr_in_ctx(nil, code)
end

local function read_in_ctx(ctx, code)
	function run()
		ctx = ctx or {}
		local block = parser.parse(code)
		local _, result = reader.read(ctx, block)
		return result
	end

	function trace(err)
		print(table.dump(err))
		print(debug.traceback())
	end

	local ok, result = xpcall(run, trace)
	return result
end

local function read(code)
	return read_in_ctx(nil, code)
end

RunTests({
	-- ["should read simple values"] = function()
	-- 	local num_node = read_expr([[ 1 ]])
	-- 	assert.is.same(num_node.type, "value")
	-- 	assert.is_number(num_node.value, 1)
	--
	-- 	local string_node = read_expr([[ "hello" ]])
	-- 	assert.is.same(string_node.type, "value")
	-- 	assert.is_string(string_node.value, "hello")
	-- end,
	--
	-- ["word that evaluates to a value should be returned as is"] = function()
	-- 	local symbols = {
	-- 		["true"] = { type = types.bool },
	-- 	}
	-- 	local result = read_expr_in_ctx(nil, [[ true ]])
	-- 	assert.is_word(result.value, "true")
	-- end,
	--
	-- ["set-word should be read as an op"] = function()
	-- 	local symbols = {}
	-- 	read_expr_in_ctx(symbols, [[ x: 10 ]])
	-- end,

	["test"] = function()
		local context = {
			["foo"] = {
				type = types.fn,
				infix = false,
				args = {
					{ eval = true },
				},
			},
		}
		local result = read_in_ctx(context, [[ x: foo foo 1 foo 23]])

		-- 1 foo foo x:

		print(table.dump(result))
	end,
})
