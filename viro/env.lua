local types = require("viro.types")
local env = {
	global_context = {},
}

function env.new(parent)
	local new_ctx = {}
	if parent == nil then
		parent = env.global_context
	end
	setmetatable(new_ctx, { __index = parent })
	return new_ctx
end

return env
