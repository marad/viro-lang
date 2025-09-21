local types = require("viro.types")

local evaluator = {}

---@param fn_node Function
function evaluator.handle_fn_call(fn_node, block, idx, ctx, last_result)
	local evaluated_args = {}
	local current_index = idx
	local arg_idx = 1
	if fn_node.infix then
		arg_idx = 2
		table.insert(evaluated_args, last_result)
	end
	while arg_idx <= fn_node.arg_count do
		local arg_value, next_idx = evaluator.eval_expr(block, current_index, ctx)
		table.insert(evaluated_args, arg_value)
		current_index = next_idx
		arg_idx = arg_idx + 1
	end
	local result = fn_node.fn(ctx, table.unpack(evaluated_args))
	return result, current_index
end

function evaluator.eval_expr(block, idx, ctx, last_result)
	local current_value = block.value[idx]
	assert(current_value ~= nil,
		"Tried to read past the end of the block " .. block:mold().value .. " at index " .. tostring(idx))

	if current_value.type == types.set_word then
		local word = current_value.word.name
		local to_set, next_idx = evaluator.eval_expr(block, idx + 1, ctx)
		ctx[word] = to_set
		return to_set, next_idx
	elseif current_value.type == types.word then
		local value = ctx[current_value.name]
		if value == nil then
			error("Word '" .. current_value.name .. "' has no value assigned")
		end
		if value.type == types.fn then
			return evaluator.handle_fn_call(value, block, idx + 1, ctx, last_result)
		else
			return value, idx + 1
		end
	elseif current_value.type == types.paren then
		local value = evaluator.eval_block(current_value, ctx)
		return value, idx + 1
	else
		return current_value, idx + 1
	end
end

function evaluator.eval_block(block, ctx)
	local index = 1
	local last_result = nil
	while index <= #block.value do
		last_result, index = evaluator.eval_expr(block, index, ctx, last_result)
	end
	return last_result
end

return evaluator
