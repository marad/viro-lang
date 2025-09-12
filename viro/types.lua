local types = {
	word = "word",
	set_word = "set-word",
	set_path = "set-path",
	block = "block",
	string = "string",
	number = "number",
	fn = "fn",
}

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
	return { type = types.block, value = content }
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
