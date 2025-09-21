---@class Stack
local StackPrototype = {}

---@return Stack
function NewStack()
	local stack = {}
	setmetatable(stack, { __index = StackPrototype })
	return stack
end

--- Pushes value onto the stack
--- @param value any Value to push
--- @return any # The same value that was passed
function StackPrototype:push(value)
	self[#self + 1] = value
	return value
end

--- Pops value from the top of the stack
--- @return any #
function StackPrototype:pop()
	local value = self[#self]
	self[#self] = nil
	return value
end

function StackPrototype:peek()
	return self[#self]
end
