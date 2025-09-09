require "spec"
local env = require "viro.env"

env.global_context.foo = "test"

RunTests {
    ["global context is the default parent"] = function()
        local ctx = env.new()
        assert(ctx.foo == "test", "Failed to retrieve a key from global context")
    end,

    ["parent context is reachable"] = function()
        local parent = env.new()
        parent.key = "test"

        local ctx = env.new(parent)
        assert(ctx.key == "test", "Failed to retrieve a test key from parent context")
        assert(ctx.foo == "test", "Global context is unreachable in subcontext")
    end
}
