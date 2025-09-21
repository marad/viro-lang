-- Reader converts the block into Lua

require("viro.stack")
require("viro.util")
local types = require("viro.types")

local reader = {}

----------------------------------------------------------------------------------
---
--- TYPES AND AST DEFINITIONS
---
----------------------------------------------------------------------------------

--- Some doc
---@class Context

---@class Symbol
---@field type Type

---@class FnSymbol: Symbol
---@field infix boolean
---@field args ArgSpec[]

--- Represents the value in Shanting Yard algorithm
--- Might be a literal value or a complex expression
---@class ValueNode
---@field type "value"
---@field value Base

---@class FnCallNode
---@field type "fn-call"
---@field fn Word
---@field args Node[]

--- Represetns the operation in Shanting Yard algorithm
--- This might be an infix binary operator (like +)
--- or prefix unary operator (like x:)
---@class OpNode
---@field type "op"
---@field prec integer
---@field op Base
---@field arg_count integer

---@alias Node ValueNode | OpNode | FnCallNode

---@param value Base
---@return ValueNode
local function value_node(value)
	return { type = "value", value = value }
end

---@param word Word
---@return ValueNode
local function read_value_node(word)
	return value_node(word)
end

---@param fn_word Word Word that evaluates to a function
---@param args Node[] argument nodes
local function fn_call_node(fn_word, args)
	return { type = "fn-call", fn = fn_word, args = args }
end

---@param op Base Operation to perform
---@param prec integer Node precedence for Shunting Yard Algorithm
---@param arg_count integer Number of arguments this operator needs
---@return OpNode
local function op_node(op, prec, arg_count)
	return { type = "op", prec = prec, op = op, arg_count = arg_count }
end

---@param set_word SetWord
local function set_word_op(set_word)
	return op_node(set_word, 0, 1)
end

----------------------------------------------------------------------------------
---
--- READ EXPRESSION
---
----------------------------------------------------------------------------------

---@param ctx Context
---@param block Block Block to read next expression from
---@param from_idx integer? Starting element for the expression
---@return integer, Node # Returns index after the read expression and the parsed Node
function reader.read_expr(ctx, block, from_idx)
	local idx = from_idx or 1
	local current_value = block.value[idx]
	idx = idx + 1
	assert(
		current_value ~= nil,
		"Tried to read past the end of block" .. block:mold().value .. " at index " .. tostring(idx)
	)

	if current_value.type == types.set_word then
		---@cast current_value SetWord
		return idx, set_word_op(current_value)
	elseif current_value.type == types.word then
		---@cast current_value Word
		local info = ctx[current_value.name]
		---@cast info Symbol

		if info ~= nil and info.type == types.fn then
			-- If the word points to the function - read further to get the arguments
			---@cast info FnSymbol
			return reader.read_fn_args(ctx, current_value, info, block, idx)
		else
			-- Otherwise - assume that it should read the value from context
			return idx, read_value_node(current_value)
		end
	else
		return idx, value_node(current_value)
	end
end

----------------------------------------------------------------------------------
---
--- READ FUNCTION ARGUMENTS
---
----------------------------------------------------------------------------------

---@param ctx Context
---@param fn_word Word Word pointing to the function
---@param fn_symbol FnSymbol Symbol information
---@param block Block
---@param from_idx integer
---@return integer, FnCallNode # Returns index after the read expression and the parsed Node
function reader.read_fn_args(ctx, fn_word, fn_symbol, block, from_idx)
	local idx = from_idx
	local args = {}
	local arg_idx = 1

	while arg_idx <= #fn_symbol.args do
		local new_index, node = reader.read_expr(ctx, block, idx)
		idx = new_index
		-- We can unpack the Node abstraction here as it's necessary only for Shunting Yard
		-- algorithm, and those values are already packed within another node
		if node.type == "fn-call" then
			---@cast node FnCallNode
			table.insert(args, { node.fn, table.unpack(node.args) })
		elseif node.type == "value" then
			---@cast node ValueNode
			table.insert(args, node.value)
		else
			error("Unhandled argument node: " .. table.dump(node))
		end
		arg_idx = arg_idx + 1
	end

	return idx, fn_call_node(fn_word, args)
end

----------------------------------------------------------------------------------
---
--- READ BLOCK
---
----------------------------------------------------------------------------------

--- Reads the block from given position.
--- Implements the Shunting Yard algorithm
---@param ctx Context
---@param block Block Block to read next expression from
---@param from_idx integer? Starting element for the expression
---@return integer, table # Returns index after the read expression and the parsed Node
function reader.read(ctx, block, from_idx)
	local output = NewStack()
	local holding = NewStack()
	local index = from_idx or 1

	-- Shunting Yard implementation
	while index <= #block.value do
		local new_index, expr = reader.read_expr(ctx, block, index)
		index = new_index
		if expr == nil then
			break
		end

		print(expr.type)
		if expr.type == "op" then
			---@cast expr OpNode
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

	-- Building the AST from nodes
	-- The algorithm here processes the postfix notation produced by
	-- Shunting Yard algorithm and constructs an AST tree.
	local argstack = NewStack()
	for _, node in ipairs(output) do
		if node.type == "op" then
			---@cast node OpNode
			-- If infix op node is encountered then it collects arguments
			-- from the argstack and builds an AST node from them
			local args = {}
			local arg_idx = 1
			while arg_idx <= node.arg_count do
				assert(#argstack > 0, "Argument stack is empty but an argument is expected!")
				table.insert(args, argstack:pop())
				arg_idx = arg_idx + 1
			end

			table.insert(argstack, {
				node.op,
				table.unpack(args),
			})
		elseif node.type == "fn-call" then
			---@cast node FnCallNode
			-- If a function call is encountered then it's only reformed into an AST
			-- tree node and pushed onto the argstack as a value
			argstack:push({ node.fn, table.unpack(node.args) })
		else
			-- And value nodes go straight to the argstack
			argstack:push(node)
		end
	end

	return index, argstack
end

return reader
