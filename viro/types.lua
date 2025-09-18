---@class Types
local types = {
	datatype = "datatype!",
	word = "word!",
	set_word = "set-word!",
	set_path = "set-path!",
	block = "block!",
	paren = "paren!",
	string = "string!",
	number = "number!",
	object = "object!",
	fn = "fn!",

	series = "series!",
	file = "file!",
}

---@class Base
local base_type = {
	type = "unset!",
	kind = "unset!"
}



--------------------------------------------------------------------------------
---@class Series
--- Implements basic series methods.
--- Requires the following fields to be available on the object:
---  * copy(self, from_index)
---  * length(self)
---  * get_at(self, index)
---  * set_at(self, index, value)
local series_proto = {
	type = types.series,
	series = true,
	index = 1,
}

setmetatable(series_proto, { __index = base_type })


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

---@param offset Number Offset to apply to current position
---@return Series out returns a copy of the series with position offset by count
function series_proto.skip(self, offset)
	local new = self:copy(1)
	new.index = self.index + offset.value
	if new.index < 1 then new.index = 1 end
	if new.index > new:length() then new.index = new:length() + 1 end
	return new
end

function series_proto.is_empty(self)
	if self.index > self:length() then
		return types.trueval
	else
		return types.falseval
	end
end

function series_proto.at(self, index)
	local new = self:copy(1)
	new.index = index.value
	if new.index < 1 then new.index = 1 end
	if new.index > new:length() then new.index = new:length() + 1 end
	return new
end

function series_proto.pick(self, index)
	return self:get_at(index)
end

function series_proto.iterator(self)
	local index = 0
	return function()
		index = index + 1
		return self:at(index)
	end
end


--------------------------------------------------------------------------------
---@class Block
local block_type = {
	type = types.block,
	kind = types.block,
	value = {},
	length = function(self)
		return #self.value
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

function block_type.get_at(self, index)
	return self.value[index.value]
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
	type = types.string,
	kind = types.string,
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

function string_type.get_at(self, index)
	return types.makeNumber(utf8.codepoint(self.value, index.value))
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
	type = types.word,
	kind = types.word,
	name = ""
}

setmetatable(word_type, { __index = base_type })

function word_type.copy(self)
	return types.makeWord(self.name)
end

function word_type.mold(self)
	return types.makeString(self.name)
end

function word_type.form(self)
	return types.makeString(self.name)
end

--------------------------------------------------------------------------------
---@class SetWord 
local set_word_type = {
	type = types.set_word,
	kind = types.set_word,
}

setmetatable(set_word_type, { __index = base_type })

function set_word_type.copy(self)
	return types.makeSetWord(self.word)
end

function set_word_type.mold(self)
	return types.makeString(self.word.name .. ":")
end

function set_word_type.form(self)
	return types.makeString(self.word.name)
end

--------------------------------------------------------------------------------
---@class SetPath
local set_path_type = {
	type = types.set_path,
	kind = types.set_path,
}

setmetatable(set_path_type, { __index = base_type })

function set_path_type.copy(self)
	return types.makeSetPath(self.word, self.path)
end

function set_path_type.mold(self)
	return types.makeString(self.word.name .. "/" .. self.path.name .. ":")
end

function set_path_type.form(self)
	return types.makeString(self.word.name .. "/" .. self.path.name)
end

--------------------------------------------------------------------------------
---@class Number
local number_type = {
	type = types.number,
	kind = types.number,
	value = 0
}

setmetatable(number_type, { __index = base_type })

function number_type.copy(self)
return types.makeNumber(self.value)	
end

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
	type = types.fn,
	kind = types.fn,
	fn = function() return types.none end,
	arg_count = 0,
}

setmetatable(fn_type, { __index = base_type })

function fn_type.copy(self)
	return types.makeFn(self.fn, self.arg_count)
end

function fn_type.mold(self)
	return types.makeString("\"?function?\"")
end

function fn_type.form(self)
	return types.makeString("?function?")
end

--------------------------------------------------------------------------------
---@class Object
local object_type = {
	type = types.object,
	kind = types.object,
	value = {},
}

setmetatable(object_type, { __index = base_type })

function object_type.copy(self)
	local obj = {}
	setmetatable(obj, getmetatable(self.value))
	for key, value in pairs(self.value) do
		obj[key] = value
	end
	return types.makeObject(obj)
end

---@param word Word
function object_type.set_word(self, word, value)
	self.value[word.name] = value
	return value
end

function object_type.get_word(self, word)
	return self.value[word.name]
end

function object_type.mold(self)
	local result = {"make " .. self.type .. " ["}
	for key, value in pairs(self.value) do
		table.insert(result, "    " .. key .. ": " .. value:mold().value)
	end
	table.insert(result, "]")
	return types.makeString(table.concat(result, "\n"))
end

function object_type.form(self)
	local result = {"make " .. self.type .. " ["}
	for key, value in pairs(self.value) do
		table.insert(result, "    " .. key .. ": " .. value:form().value)
	end
	table.insert(result, "]")
	return types.makeString(table.concat(result, "\n"))
end

--------------------------------------------------------------------------------

function types.make(type_name, value)
	local node = { type = type_name, value = value}
	return node
end

function types.makeWord(word)
	local value = { name = word }
	setmetatable(value, { __index = word_type })
	return value
end

function types.makeSetWord(word)
	local value = { word = word }
	setmetatable(value, { __index = set_word_type })
	return value
end

function types.makeSetPath(word, path)
	local value = { word = word, path = path }
	setmetatable(value, { __index = set_path_type })
	return value
end

function types.makeBlock(content)
	local block = { value = content }
	setmetatable(block, { __index = block_type })
	return block
end

function types.makeString(content)
	local string = { value = content }
	setmetatable(string, { __index = string_type })
	return string
end

function types.makeNumber(value)
	local node = { value = tonumber(value) }
	setmetatable(node, { __index = number_type })
	return node
end

function types.makeFn(fn, arg_count, infix)
	local node = { fn = fn, arg_count = arg_count, infix = infix }
	setmetatable(node, { __index = fn_type })
	return node
end

function types.makeObject(table)
	local node = { value = table }
	setmetatable(node, { __index = object_type })
	return node
end

types.none = types.makeWord("none")
types.trueval = types.makeWord("true")
types.falseval = types.makeWord("false")

return types
