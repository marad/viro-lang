require("viro.util")
local process = require("viro.processor")
local parser = require("viro.parser")
local env = require("viro.env")
local default_ctx = require("viro.default_ctx")

print("Viro REPL v0.0.1-alpha")

local repl_ctx = env.new(default_ctx)

while true do
	xpcall(function()
		io.write("> ")
		local code = io.read()
		local ast = parser.parse(code)
		local result = process(ast, repl_ctx)
		if result ~= default_ctx.none then
			print(default_ctx.form.fn(repl_ctx, result).value)
		end
	end, function (error)
		if error:match("interrupted") then
			os.exit(0, true)
		end
		print(table.dump(error))
		print(debug.traceback())
	end)
end

