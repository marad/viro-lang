local lpeg = require "lpeg"

local P, V, S, R, C, Ct, Cp = lpeg.P, lpeg.V, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.Cp

lpeg.locale(lpeg)

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


local function dump(o, indent)
  if indent == nil then
    indent = ""
  end
  local baseindent = indent
  indent = indent .. "  "

  if type(o) == 'table' then
    local result = {}
    for k, v in pairs(o) do
      --if type(k) ~= 'number' then k = '"' .. k .. '"' end
      table.insert(result, indent .. k .. ' = ' .. dump(v, indent))
    end
    return "{\n" .. table.concat(result, ",\n") .. "\n" .. baseindent .. "}"
  else
    return tostring(o)
  end
end

local NodeTypes = {
  word = 1,
  set_word = 2,
  block = 3,
  string = 4,
  number = 5
}

local function makePos(from, to)
  return { from = from, to = to }
end

local function makeWord(from, word, to)
  return { type = NodeTypes.word, name = word, srcPos = makePos(from, to) }
end

local function makeSetWord(from, word, to)
  return { type = NodeTypes.set_word, word = word, srcPos = makePos(from, to) }
end

local function makeBlock(from, content, to)
  return { type = NodeTypes.block, value = content, srcPos = makePos(from, to) }
end

local function makeString(from, content, to)
  return { type = NodeTypes.string, value = content, srcPos = makePos(from, to) }
end

local function makeNumber(from, value, to)
  return { type = NodeTypes.number, value = tonumber(value), srcPos = makePos(from, to) }
end



local grammar = P {
  "Viro",
  Viro = ig * (Cp() * Ct(V("Expr") ^ 1) * Cp()) / makeBlock,
  Expr = V("Comment") + V("Block") + V("Set_Word") + V("Braced_String") + V("String") + V("Number") + V("Word"),
  Word = (Cp() * C(lpeg.alpha ^ 1) * Cp() * ig) / makeWord,
  Number = (Cp() * C(digit ^ 1 * (period * digit ^ 1) ^ 0) * Cp() * ig) / makeNumber,
  String = (Cp() * quote * C(string_content) * quote * Cp() * ig) / makeString,
  Braced_String = (Cp() * lbrace * C(braced_string_content) * rbrace * Cp() * ig) / makeString,
  -- TODO: set-word nie powinien mieć wartości - to tylko element
  -- to dopiero procesowanie bloku "bierze" kolejny element i go przypisuje
  Set_Word = (Cp() * V("Word") * colon * Cp() * ig) / makeSetWord,
  Block = (Cp() * S("[") * ig * Ct(V("Expr") ^ 0) * ig * S("]") * Cp() * ig) / makeBlock,
  Comment = S(";") * ((1 - S("\n")) ^ 0) * ig,
}


-- TODO: (https://www.rebol.com/r3/docs/guide/code-syntax.html)
-- Add parens for groupping
-- Words should allow symbols: ?, -, !, #, $, @, %, ^, &, +, `, ~, |, =, *
-- Set_Path (x/1: 10)
-- "/" powinno kończyć słowo - bo zaczyna ścieżkę
-- Bloki powinny mieć wskaźnik instrukcji (dla funkcji back, next, etc)

local testCode = [[
  ;Viro [Title: "Example"]
  ;myval: 10
  ;print {Hello}
  ;for name series [
  ;  print name
  ;]
  ;program: [print "Hello"]
  do program

  x: 1
  [ print "hello" world i costam ]
]]

function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return res
end

local viro = {}

function viro.parse(code)
  return grammar:match(code)
end

function viro.next(block)
  local index = block.index
  if index == nil then
    index = 1
  end
  local result = table.copy(block)
  result.index = index + 1
  return result
end

function viro.first(block)
  return block.value[block.index or 1]
end

function viro.eval(ast, ctx)
  if ast.type == NodeTypes.block then
    --return viro.evalBlock(ast, ctx)
    return ast
  elseif ast.type == NodeTypes.set_word then
    return viro.evalSetWord(ast, ctx)
  elseif ast.type == NodeTypes.number then
    return ast
  elseif ast.type == NodeTypes.string then
    return ast
  elseif ast.type == NodeTypes.word then
    return viro.evalWord(ast, ctx)
  else
    assert(false, "Unhandled node: " .. dump(ast))
  end
end

function viro.evalBlock(block, ctx)
  assert(block.type == NodeTypes.block, "Only accepts blocks!")
  local result = nil
  for _, v in ipairs(block.value) do
    result = viro.eval(v, ctx)
  end
  return result
end

function viro.evalSetWord(ast, ctx)
  local word_name = ast.word.name
  local value = viro.eval(ast.value, ctx)
  ctx[word_name] = value
  return value
end

function viro.evalWord(ast, ctx)
  -- TODO:
  -- based on the value from context it should do different things
  -- if that's a number/block/string - it should return it as value
  -- if type == set_word then it should evaluate it's value and return
  -- if type == function - it should gather and evaluate the arguments and call the function


  return ctx[ast.name]
end

local t = viro.parse(testCode)
--print(dump(t))


local ctx = {}
local result = viro.evalBlock(t, ctx)

-- print("Context: " .. dump(ctx))
-- print()
-- print("Result: " .. dump(result))

local foo = viro.next(result)
print("FOO: " .. dump(viro.first(foo)))

foo = viro.next(foo)
print("FOO: " .. dump(viro.first(foo)))
