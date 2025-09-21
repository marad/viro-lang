require("spec")
require("viro.stack")
local assert = require("luassert")

RunTests({
	["should work like a stack"] = function()
		local stack = NewStack()
		stack:push(1)
		stack:push(2)

		assert.are.equal(2, #stack)
		assert.are.same(2, stack:peek())
		assert.are.equal(2, #stack)

		assert.are.equal(2, stack:pop())
		assert.are.equal(1, #stack)
		assert.are.equal(1, stack:pop())
	end,

	["should return nil when popping from empty stack"] = function()
		local stack = NewStack()
		assert.are.same(nil, stack:pop())
	end,
})
