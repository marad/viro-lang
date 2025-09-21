--
-- This file contains a Lua runtime functions
--
require("viro.util")
local env = require("viro.env")
local types = require("viro.types")

local code = [[
content = read(to("file!", "01.txt"))
floor = 0
pos = 1
basement = 0

for c in iterate(content) do
  if c == "(" then floor = floor + 1 end
  if c == ")" then floor = floor - 1 end
  if (floor == -1) and (basement == 0) then basement = pos end
  pos = pos + 1
end


print(viro.block("Part 1:", floor))
print(viro.block("Part 2:", basement))
]]

local root = env.new()

function root.read(_)
	return "()(()"
end

function root.print(arg)
	print(table.dump(arg))
end

function root.to(type, value)
	if type == types.file then
		local result = types.makeString(value)
		result.type = types.file
		return result
	end
end

function root.iterate(value)
	-- abstrakcja na series
	print(table.dump(value))

	if type(value == "string") then
		function generator()
			for _, code in utf8.codes(value) do
				coroutine.yield(utf8.char(code))
			end
		end

		local co = coroutine.create(generator)

		return function()
			local ok, value = coroutine.resume(co)
			if ok then
				return value
			else
				coroutine.close(co)
				return nil
			end
		end
	end
end

local viro = {}
root.viro = viro

function viro.block(...)
	return types.makeBlock(table.pack(...))
end

local ctx = env.new(root)
local f = load(code, "code", "bt", ctx)
f()

-- s = "hello"
-- for _, c in utf8.codes(s) do
-- 	print(utf8.char(c))
-- end
