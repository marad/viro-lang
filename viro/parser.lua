local lpeg = require "lpeg"
lpeg.locale(lpeg)

local types = require "viro.types"

local P, V, S, C, Ct, Cp = lpeg.P, lpeg.V, lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cp

local space = lpeg.space ^ 0
local ig = space -- ignore whitespace
local digit = lpeg.R("09")
local period = lpeg.S(".")
local colon = lpeg.S(":")
local quote = S('"')
local string_content = (1 - quote) ^ 0
local lbrace = S('{')
local rbrace = S('}')
local braced_string_content = (1 - rbrace) ^ 0
local word_char = lpeg.alpha + S("-+?%!#$@^&~`*'/=")

local grammar = P {
  "Viro",
  Viro = ig * (Cp() * Ct(V("Expr") ^ 1) * Cp()) / types.makeBlock,
  Expr = V("Comment") + V("Block") + V("Set_Word") + V("Braced_String") + V("String") + V("Number") + V("Word"),
  Word = (Cp() * C(word_char ^ 1) * Cp() * ig) / types.makeWord,
  Number = (Cp() * C(digit ^ 1 * (period * digit ^ 1) ^ 0) * Cp() * ig) / types.makeNumber,
  String = (Cp() * quote * C(string_content) * quote * Cp() * ig) / types.makeString,
  Braced_String = (Cp() * lbrace * C(braced_string_content) * rbrace * Cp() * ig) / types.makeString,
  Set_Word = (Cp() * V("Word") * colon * Cp() * ig) / types.makeSetWord,
  Block = (Cp() * S("[") * ig * Ct(V("Expr") ^ 0) * ig * S("]") * Cp() * ig) / types.makeBlock,
  Comment = S(";") * ((1 - S("\n")) ^ 0) * ig,
}

local parser = {}

function parser.parse(code)
  return grammar:match(code)
end

return parser
