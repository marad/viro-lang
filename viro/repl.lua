require "viro.util"
local process = require "viro.processor"
local parser = require "viro.parser"
local env = require "viro.env"


print("Viro REPL v0.0.1-alpha")

local root_ctx = env.new()
local repl_ctx = env.new(root_ctx)

while true do
  io.write("> ")
  local code = io.read()
  local ast = parser.parse(code)
  local result = process(ast, repl_ctx)
  print(table.dump(result))
end
