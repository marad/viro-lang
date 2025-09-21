local assert = require("luassert")
local say = require("say")
local types = require("viro.types")

function RunTests(t)
	local tests = 0
	local success = 0
	for name, test in pairs(t) do
		print("--- " .. name .. " ---")
		local ok, err = pcall(test)
		tests = tests + 1
		if ok then
			success = success + 1
		else
			print(err)
		end
	end

	print("========== Summary ==========")
	print("All: " .. tests .. " Success: " .. success .. " Failed: " .. (tests - success))
end

local function is_viro_number(_, args)
	local object, value = table.unpack(args)
	return object.type == types.number and object.value == value
end

say:set("assert.is_number.positive", "Expected %s to be a number: %s")
say:set("assert.is_number.negative", "Expected %s to not be a number: %s")
assert:register("assertion", "is_number", is_viro_number, "assert.is_number.positive", "assert.is_number.negative")

local function is_viro_string(_, args)
	local object, value = table.unpack(args)
	return object.type == types.string and object.value == value
end

say:set("assert.is_string.positive", "Expected %s to be a string: %s")
say:set("assert.is_string.negative", "Expected %s to not be a string: %s")
assert:register("assertion", "is_string", is_viro_string, "assert.is_string.positive", "assert.is_string.negative")

local function is_viro_bool(_, args)
	local object, value = table.unpack(args)
	return object.type == types.bool and object.value == value
end

say:set("assert.is_bool.positive", "Expected %s to be a bool: %s")
say:set("assert.is_bool.negative", "Expected %s to not be a bool: %s")
assert:register("assertion", "is_bool", is_viro_bool, "assert.is_bool.positive", "assert.is_bool.negative")

local function is_viro_word(_, args)
	local object, name = table.unpack(args)
	return object.type == types.word and object.name == name
end

say:set("assert.is_word.positive", "Expected %s to be a word: %s")
say:set("assert.is_word.negative", "Expected %s to not be a word: %s")
assert:register("assertion", "is_word", is_viro_word, "assert.is_word.positive", "assert.is_word.negative")
