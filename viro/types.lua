---@class Types
local types = {
	word = "word",
	set_word = "set-word",
	set_path = "set-path",
	block = "block",
	string = "string",
	number = "number",
	fn = "fn",
}



--------------------------------------------------------------------------------
---@class Series
--- Implements basic series methods.
--- Requires the following fields to be available on the object:
---  * copy(self, from_index)
---  * length(self)
local series_proto = {
	series = true,
	index = 1,
}


---@return Series out the copy of the series, but pointing to the next element
function series_proto.next(self)
	local new = self:copy(1)
	new.index = self.index + 1
	if new.index > new:length() then new.index = new:length() + 1 end
	return new
end

---@return Series out the copy of the series, but pointing to the previous element
function series_proto.back(self)
	local new = self:copy(1)
	new.index = self.index - 1
	if new.index < 1 then new.index = 1 end
	return new
end

---@return Series out copy of the series pointing to the first element
function series_proto.head(self)
	local new = self:copy(1)
	new.index = 1
	return new
end

---@return boolean out if the series is pointing at the first element
function series_proto.is_head(self)
	if self.index == 1 then 
		return types.trueval 
	else
		return types.falseval 
	end
end

---@return Series out copy of the series pointing after the last element
function series_proto.tail(self)
	local new = self:copy(1)
	new.index = new:length() + 1
	return new
end

---@return boolean out if the series is pointing after the last element
function series_proto.is_tail(self)
	if self.index == self:length() + 1 then
		return types.trueval
	else
		return types.falseval
	end
end

function series_proto.skip(self, count)
	local new = self:copy(1)
	new.index = self.index + count
	if new.index < 1 then new.index = 1 end
	if new.index > new:length() then new.index = new:length() + 1 end
	return new
end


--------------------------------------------------------------------------------
---@class Block
local block_type = {
	value = {},
	length = function(self)
		return #self.value
	end,
	pick = function(self, index)
		index = index or 1
		return self.value[self.index + index - 1]
	end,
}

setmetatable(block_type, { __index = series_proto })

---@return number length Length of the block
function block_type.length(self)
	return #self.value
end

function block_type.copy(self, from_index)
	local content = {}
	local index = from_index or self.index
	while index <= #self.value do
		table.insert(content, self.value[index])
		index = index + 1
	end
	return types.makeBlock(content)
end

function block_type.mold(self)
	local parts = {}
	local index = self.index
	while index <= #self.value do
		local val = self.value[index]
		index = index + 1
		table.insert(parts, val:mold(val).value)
	end
	return types.makeString("[" .. table.concat(parts, " ") .. "]")
end

function block_type.form(self)
	local parts = {}
	local index = self.index
	while index <= #self.value do
		local val = self.value[index]
		table.insert(parts, val:form(val).value)
		index = index + 1
	end
	return types.makeString(table.concat(parts, " "))
end

--------------------------------------------------------------------------------
---@class String
local string_type = {
	value = ""
}

setmetatable(string_type, { __index = series_proto })

function string_type.length(self)
	return #self.value
end

function string_type.copy(self, from_index) 
	from_index = from_index or self.index
	return types.makeString(string.sub(self.value, from_index))
end

function string_type.form(self)
	return self:copy()
end

function string_type.mold(self)
	local contains_quotes = string.match(self.value, "\"")
	if contains_quotes then
		return types.makeString("{" .. string.sub(self.value, self.index) .. "}")
	else
		return types.makeString("\"" .. string.sub(self.value, self.index) .. "\"")
	end
end

--------------------------------------------------------------------------------
---@class Word
local word_type = {
	name = ""
}

function word_type.mold(self)
	return types.makeString(self.name)
end

function word_type.form(self)
	return types.makeString(self.name)
end

--------------------------------------------------------------------------------
---@class SetWord 
local set_word_type = {
}

function set_word_type.mold(self)
	return types.makeString(self.word.name .. ":")
end

function set_word_type.form(self)
	return types.makeString(self.word.name)
end

--------------------------------------------------------------------------------
---@class SetPath
local set_path_type = {
}

function set_path_type.mold(self)
	return types.makeString(self.word.name .. "/" .. self.path.name .. ":")
end

function set_path_type.form(self)
	return types.makeString(self.word.name .. "/" .. self.path.name)
end

--------------------------------------------------------------------------------
---@class Number
local number_type = {
	value = 0
}

---@param self Number
function number_type.mold(self)
	return types.makeString(tostring(self.value))
end

---@param self Number
function number_type.form(self)
	return types.makeString(tostring(self.value))
end

--------------------------------------------------------------------------------
---@class Function
local fn_type = {
	fn = function() return types.none end,
	arg_count = 0,
}

function fn_type.mold(self)
	return "?function?"	
end

function fn_type.form(self)
	return "?function?"
end

--------------------------------------------------------------------------------

function types.makeWord(word)
	local value = { type = types.word, name = word }
	setmetatable(value, { __index = word_type })
	return value
end

function types.makeSetWord(word)
	local value = { type = types.set_word, word = word }
	setmetatable(value, { __index = set_word_type })
	return value
end

function types.makeSetPath(word, path)
	local value = { type = types.set_path, word = word, path = path }
	setmetatable(value, { __index = set_path_type })
	return value
end

function types.makeBlock(content)
	local block = { type = types.block, value = content }
	setmetatable(block, { __index = block_type })
	return block
end

function types.makeString(content)
	local string = { type = types.string, value = content }
	setmetatable(string, { __index = string_type })
	return string
end

function types.makeNumber(value)
	local node = { type = types.number, value = tonumber(value) }
	setmetatable(node, { __index = number_type })
	return node
end

function types.makeFn(fn, arg_count)
	local node = { type = types.fn, fn = fn, arg_count = arg_count }
	setmetatable(node, { __index = fn_type })
	return node
end

types.none = types.makeWord("none")
types.trueval = types.makeWord("true")
types.falseval = types.makeWord("false")

return types
