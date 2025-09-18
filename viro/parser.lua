local lpeg = require("lpeg")
lpeg.locale(lpeg)

-- TODO: (https://www.rebol.com/r3/docs/guide/code-syntax.html)
-- Add parens for groupping
-- Words should allow symbols: ?, -, !, #, $, @, %, ^, &, +, `, ~, |, =, *
-- Set_Path (x/1: 10)
-- "/" powinno kończyć słowo - bo zaczyna ścieżkę
-- Bloki powinny mieć wskaźnik instrukcji (dla funkcji back, next, etc)

local types = require("viro.types")
local parser = {}

local function withPos(node, from, to)
	node.srcPos = { from = from, to = to }
	return node
end

function parser.read_word(from, word, to)
	if string.sub(word, 1, 1) == "%" then
		local file = types.makeString(string.sub(word, 2))
		file.type = types.file
		return withPos(file, from, to)
	elseif string.sub(word, -1) == "!" then
		local type = types.makeWord(word)
		type.type = types.datatype
		return withPos(type)
	else
		return withPos(types.makeWord(word), from, to)
	end
end

function parser.read_set_word(from, word, to)
	return withPos(types.makeSetWord(word), from, to)
end

function parser.read_block(from, content, to)
	return withPos(types.makeBlock(content), from, to)
end

function parser.read_paren(from, content, to)
	local block = types.makeBlock(content)
	block.type = types.paren
	return block
end

function parser.read_string(from, content, to)
	return withPos(types.makeString(content), from, to)
end

function parser.read_number(from, value, to)
	return withPos(types.makeNumber(value), from, to)
end

local P, V, S, C, Ct, Cp = lpeg.P, lpeg.V, lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cp

local space = (lpeg.space + S(",")) ^ 0
local ig = space -- ignore whitespace
local digit = lpeg.R("09")
local period = lpeg.S(".")
local colon = lpeg.S(":")
local quote = S('"')
local string_content = (1 - quote) ^ 0
local lbrace = S("{")
local rbrace = S("}")
local braced_string_content = (1 - rbrace) ^ 0
local word_char = lpeg.alpha + S("._-+?%!#$@^&~`*'/=") + digit

local grammar = P({
	"Viro",
	Viro = ig * (Cp() * Ct(V("Expr") ^ 1) * Cp()) / parser.read_block,
	Expr = V("Comment") + V("Paren") + V("Block") + V("Set_Word") + V("Braced_String") + V("String") + V("Number") + V("Word"),
	Word = (Cp() * C(word_char ^ 1) * Cp() * ig) / parser.read_word,
	Number = (Cp() * C(digit ^ 1 * (period * digit ^ 1) ^ 0) * Cp() * ig) / parser.read_number,
	String = (Cp() * quote * C(string_content) * quote * Cp() * ig) / parser.read_string,
	Braced_String = (Cp() * lbrace * C(braced_string_content) * rbrace * Cp() * ig) / parser.read_string,
	Set_Word = (Cp() * V("Word") * colon * Cp() * ig) / parser.read_set_word,
	Block = (Cp() * S("[") * ig * Ct(V("Expr") ^ 0) * ig * S("]") * Cp() * ig) / parser.read_block,
	Paren = (Cp() * S("(") * ig * Ct(V("Expr") ^ 0) * ig * S(")") * Cp() * ig) / parser.read_paren,
	Comment = S(";") * ((1 - S("\n")) ^ 0) * ig,
})

function parser.parse(code)
	return grammar:match(code)
end

return parser
