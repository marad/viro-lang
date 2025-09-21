require("viro.util")
local parser = require("viro.parser")
local types = require("viro.types")

function pp(arg)
	print(table.dump(arg))
end

local symbols = {}
symbols["+"] = { infix = true, args = 2 }
symbols["*"] = { infix = true, args = 2 }
symbols["to-number"] = { infix = false, args = 1 }
symbols["ask"] = { infix = false, args = 0 }

local prec = {}
prec["+"] = 1
prec["*"] = 2

--- Reads next expression from given position within the block
---@param block Block Block being read
---@param from integer Index of the token within the block
---@return integer, expr # Returns next index within block and the expression read
function read(block, from, last_expr)
	local index = from or 1

	while true do
		-- Get current and look-ahead tokens
		local current = block.value[index]

		-- Finish loop if no tokens available
		if current == nil then
			break
		end
		-- Move the 'pointer'
		index = index + 1

		if current.type == types.word then
			-- if value then return value
			-- else (if function) ->
			local current_info = symbols[current.name]

			if current_info.infix then
				-- Infix function is handled by Shunting Yard algorithm
				-- one level above
				return index, { op = current.name, prec = prec[current.name] or 0 }
			else
				-- Regular function - gather arguments and return
				local result = { current.name }
				local arg_idx = 0
				while arg_idx < current_info.args do
					arg_idx = arg_idx + 1
					local new_index, arg = read(block, index)
					index = new_index
					table.insert(result, arg)
				end
				return index, result
			end
		else
			return index, current
		end
	end

	return index, nil
end

local block = parser.parse([[ to-number ask + 10 * 2 ]])
local instructions = {}

require("viro.stack")
local output = NewStack()
local holding = NewStack()

local index = 1

-- Shunting Yard Algorithm
while true do
	local new_index, expr = read(block, index)
	if expr == nil then
		break
	end
	index = new_index

	if expr.op ~= nil and expr.prec ~= nil then
		while #holding > 0 and holding:peek().prec >= expr.prec do
			local op = holding:pop()
			output:push(op)
		end
		holding:push(expr)
	else
		output:push(expr)
	end
end

while #holding > 0 do
	output:push(holding:pop())
end

for _, e in ipairs(output) do
	pp(e)
end
