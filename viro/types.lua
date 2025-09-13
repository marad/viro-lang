local types = {
	word = "word",
	set_word = "set-word",
	set_path = "set-path",
	block = "block",
	string = "string",
	number = "number",
	fn = "fn",
}


local block_type = {
	index = 1,
	value = {},
	next = function(self)
		local new = self:copy(1)
		new.index = self.index + 1
		if new.index > #new.value + 1 then new.index = #new.value + 1 end
		return new
	end,
	back = function(self)
		local new = self:copy(1)
		new.index = self.index - 1
		if new.index < 1 then new.index = 1 end
		return new
	end,
	head = function(self)
		local new = self:copy(1)
		new.index = 1
		return new
	end,
	is_head = function(self)
		return self.index == 1
	end,
	tail = function(self)
		local new = self:copy(1)
		new.index = #new.value + 1
		return new
	end,
	is_tail = function(self)
		return self.index == #self.value + 1
	end,
	length = function(self)
		return #self.value
	end,
	pick = function(self, index)
		index = index or 1
		return self.value[self.index + index - 1]
	end,
}

function block_type.copy(self, from_index)
	local content = {}
	local index = from_index or self.index
	while index <= #self.value do
		table.insert(content, self.value[index])
		index = index + 1
	end
	return types.makeBlock(content)
end

function types.makeWord(word)
	return { type = types.word, name = word }
end

function types.makeSetWord(word)
	return { type = types.set_word, word = word }
end

function types.makeSetPath(word, path)
	return { type = types.set_path, word = word, path = path }
end

function types.makeBlock(content)
	local block = { type = types.block, value = content }
	setmetatable(block, { __index = block_type })
	return block
end

function types.makeString(content)
	return { type = types.string, value = content }
end

function types.makeNumber(value)
	return { type = types.number, value = tonumber(value) }
end

function types.makeFn(fn, arg_count)
	return { type = types.fn, fn = fn, arg_count = arg_count }
end

return types
