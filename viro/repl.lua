require("viro.util")
local eval_block = require("viro.processor").eval_block
local parser = require("viro.parser")
local env = require("viro.env")
local default_ctx = require("viro.default_ctx")

print("Viro REPL v0.0.1-alpha")

local repl_ctx = env.new(default_ctx)

eval_block(parser.parse[[ do %boot.vro ]], repl_ctx)

while true do
	xpcall(function()
		io.write("> ")
		local code = io.read()
		local ast = parser.parse(code)
		local result = eval_block(ast, repl_ctx)
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

