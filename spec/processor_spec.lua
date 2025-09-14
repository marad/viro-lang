require("spec")
require("viro.util")
local env = require("viro.env")
local parser = require("viro.parser")
local process = require("viro.processor").eval_block
local types = require("viro.types")
local assert = require("luassert")

RunTests({
	["set-word should change the context"] = function()
		local ast = parser.parse([[ x: 42 ]])
		local ctx = env.new()
		process(ast, ctx)
		assert.are.same(ctx.x, parser.read_number(5, 42, 7))
	end,

	["set-word should return a value"] = function()
		local ast = parser.parse([[ x: 42 ]])
		local ctx = env.new()
		local result = process(ast, ctx)
		assert.are.same(result, parser.read_number(5, 42, 7))
	end,

	["word evaluates to it's value from context"] = function()
		local ast = parser.parse([[ x ]])
		local ctx = env.new()
		ctx.x = parser.read_number(0, 42, 0)
		local result = process(ast, ctx)
		assert.are.same(result, ctx.x)
	end,

	["set-word evaluates it's value"] = function()
		local ast = parser.parse([[ x: y ]])
		local ctx = env.new()
		ctx.y = parser.read_number(0, 42, 0)
		process(ast, ctx)
		assert.are.same(ctx.x, ctx.y)
	end,

	["native functions are evaluated and their value is returned"] = function()
		local ast = parser.parse([[ foo ]])
		local ctx = env.new()
		local number = parser.read_number(0, 42, 0)
		ctx.foo = types.makeFn(function()
			return number
		end, 0)
		local result = process(ast, ctx)
		assert.are.same(result, number)
	end,

	["native functions get context as first parameter"] = function()
		local ast = parser.parse([[ foo ]])
		local ctx = env.new()
		local number = parser.read_number(0, 42, 0)
		ctx.foo = types.makeFn(function(c)
			c.bar = number
			return c.bar
		end, 0)
		local result = process(ast, ctx)
		assert.are.same(result, number)
		assert.are.same(ctx.bar, number)
	end,

	["native functions get declared amount of parameters evaluated"] = function()
		local ast = parser.parse([[
	    foo: 1
	    bar: 2
	    add foo bar
	  ]])
		local ctx = env.new()
		ctx.add = types.makeFn(function(_, a, b)
			return parser.read_number(a.value + b.value)
		end, 2)
		local result = process(ast, ctx)
		assert.are.same(result, parser.read_number(3))
	end,
})
