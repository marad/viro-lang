require("viro.util")

---@class Type
---@field type String
---@field kind String

---@class String : Type
---@field v string

---@class Block : Type
---@field v table

---@class Word : Type
---@field v string

---@class SetWord : Type
---@field v string

---@class GetWord : Type
---@field v string

---@class LitWord : Type
---@field v string

---@class Number : Type
---@field v number

---@class Fn : Type
---@field body Block
---@field arg_def Block
---@field fn function
---@field args FnArg[]

---@class FnArg
---@field name string
---@field eval boolean?

---@class NativeFn : Type
---@field fn function
---@field args FnArg[]

---@class Action : Type
---@field name String
---@field args FnArg[]

---@class Bool : Type
---@field v boolean

---@class None : Type

---@alias Value String | Block | Word | SetWord | GetWord | LitWord | Number | Fn | NativeFn | Action | None

--------------------------------------------------------------------------------
--- Type definitions
--------------------------------------------------------------------------------

local types = {}

--- Constructs a value with given prototype
---@return Value
local function make_with_prototype(prototype, lua_value)
    local viro_value = { v = lua_value }
    setmetatable(viro_value, { __index = prototype })
    return viro_value
end

--- Constructs a value of given type
---@return Value
local function make(type_name, lua_value)
    local prototype = types[type_name]
    assert(prototype ~= nil, "Type " .. type_name .. " is undefined!")

    return make_with_prototype(prototype.v, lua_value)
end

-- For bootstraping we need to first "manually" setup the String and Object types

local Object = {}
local String = {}
local Word = {}
local SetWord = {}
local GetWord = {}
local LitWord = {}
local Number = {}
local Block = {}
local Fn = {}
local NativeFn = {}
local Action = {}
local Type = {}
local Bool = {}
local None = {}

---@return String
local function s(value)
    ---@diagnostic disable-next-line
    return make_with_prototype(String, value)
end

-- When String and Object types are properly set up we can register remaining types
---@param definition table
---@param type string
---@param kind string
---@param prototype any?
local function register_type(definition, type, kind, prototype)
    prototype = prototype or Object
    types[type] = make_with_prototype(prototype, definition)
    definition.type = s(type)
    definition.kind = s(kind)
end

register_type(Object, "object!", "object!")
register_type(Block, "block!", "block!")
register_type(String, "string!", "string!")
register_type(Word, "word!", "string!")
register_type(SetWord, "set-word!", "string!")
register_type(GetWord, "get-word!", "string!")
register_type(LitWord, "lit-word!", "string!")
register_type(Number, "number!", "number!")
register_type(Fn, "fn!", "fn!")
register_type(NativeFn, "native!", "native!")
register_type(Action, "action!", "action!")
register_type(Type, "type!", "type!")
register_type(Bool, "bool!", "bool!")
register_type(None, "none!", "none!")

---@param arg_block Block
---@param body_block Block
---@return Fn
local function make_fn(arg_block, body_block)
    ---@type Fn
    ---@diagnostic disable-next-line
    local fn = make("fn!")
    fn.body = body_block
    fn.args = arg_block
    return fn
end

---Creates a native function
---@param args ArgSpec[]
---@param fn function
---@return NativeFn
local function make_native_fn(args, fn)
    local value = {
        args = args,
        fn = fn,
    }
    setmetatable(value, { __index = NativeFn })
    return value
end

local function make_action(args, name)
    local value = {
        args = args,
        name = name,
        fn = function(_, value, ...)
            local method = value[name]
            if method ~= nil then
                return method.fn(value, ...)
            else
                error("'" .. name .. "' not supported for " .. value.type.v .. " type")
            end
        end,
    }
    setmetatable(value, { __index = Action })
    return value
end

local vtrue = make("bool!", true)
local vfalse = make("bool!", false)
local none = make("none!", "none")

--------------------------------------------------------------------------------
--- Reader
--------------------------------------------------------------------------------

local lpeg = require("lpeg")
lpeg.locale(lpeg)

local P, V, S, C, Ct, B = lpeg.P, lpeg.V, lpeg.S, lpeg.C, lpeg.Ct, lpeg.B

local ig = lpeg.space ^ 0 -- ignore whitespace
local digit, graph = lpeg.digit, lpeg.graph
local period, colon, semicolon, newline, excl = S("."), S(":"), S(";"), S("\n"), S("!")
local quote, dbquote = S("'"), S('"')
local lbrace, rbrace = S("{"), S("}")
local lparen, rparen = S("("), S(")")
local lbracket, rbracket = S("["), S("]")
local string_content = (1 - dbquote) ^ 0
local braced_string_content = (1 - rbrace) ^ 0
local non_word_content = lbrace + rbrace + lparen + rparen + lbracket + rbracket + colon
local word_content = (graph - non_word_content - digit) * (graph - non_word_content) ^ 0

---@param type_name string
---@param transform function?
---@return function
local function capture(type_name, transform)
    if not transform then
        transform = function(x)
            return x
        end
    end
    return function(value)
        return make(type_name, transform(value))
    end
end

local grammar = P({
    "Viro",
    Viro = ig * Ct(V("Expr") ^ 0) * ig / capture("block!"),
    Expr = (V("Comment") + V("Paren") + V("Block") + V("Number") + V("Strings") + V("Words")) * ig,
    Comment = semicolon * ((1 - newline) ^ 0) * ig,
    Paren = lparen * ig * Ct(V("Expr") ^ 0) * ig * rparen / capture("block!"),
    Block = lbracket * ig * Ct(V("Expr") ^ 0) * ig * rbracket / capture("block!"),
    Number = C(digit ^ 1 * (period * digit ^ 1) ^ -1) / capture("number!", tonumber),
    Words = V("Type") + V("Lit_Word") + V("Set_Word") + V("Get_Word") + V("Word"),
    Type = C(word_content) * B(excl) * ig / capture("type!"),
    Lit_Word = quote * C(word_content) * ig / capture("lit-word!"),
    Set_Word = C(word_content) * colon * ig / capture("set-word!"),
    Get_Word = colon * C(word_content) * ig / capture("get-word!"),
    Word = C(word_content) * ig / capture("word!"),
    Strings = V("String") + V("Braced_String"),
    String = dbquote * C(string_content) * dbquote / capture("string!"),
    Braced_String = lbrace * C(braced_string_content) * rbrace / capture("string!"),
})

---@param code string
---@return Block
local function read_block(code)
    return grammar:match(code)
end

local val = read_block([[
    string!
    qw!er
]])

print(table.dumpf(val))

for _, v in pairs(val.v) do
    print(table.dumpf(v), v.type.v)
end

--------------------------------------------------------------------------------
--- Context / Environment
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--- Evaluator
--------------------------------------------------------------------------------

---@param block Block
---@param from_pos integer
---@return integer, Value
local function eval_expr(scope, block, from_pos, last_value)
    local pos = from_pos or 1
    local element = block.v[pos]
    if not element then
        error("Cannot read element #" .. pos .. " of block " .. table.dumpf(block))
    end

    local type = element.type.v

    if type == "lit-word!" then
        ---@cast element LitWord
        return pos + 1, make("word!", element.v)
    elseif type == "get-word!" then
        ---@cast element GetWord
        return pos + 1, scope[element.v]
    elseif type == "set-word!" then
        ---@cast element SetWord
        local new_pos, value = eval_expr(scope, block, pos + 1, last_value)
        scope[element.v] = value
        return new_pos, value
    elseif type == "word!" then
        ---@cast element Word
        local value = scope[element.v]
        assert(value ~= nil, element.v .. " has no value")
        if value.fn ~= nil and value.args ~= nil then
            local args = {}
            pos = pos + 1
            for _, arg_spec in ipairs(value.args) do
                local new_pos, arg_value
                if arg_spec.eval or arg_spec.eval == nil then
                    new_pos, arg_value = eval_expr(scope, block, pos)
                else
                    new_pos, arg_value = pos + 1, block.v[pos]
                end
                table.insert(args, arg_value)
                pos = new_pos
            end
            return pos, value.fn(scope, table.unpack(args))
        else
            return pos + 1, value
        end
    else
        -- TODO: handling infix functions
        -- Other values evaluate to themselves
        return pos + 1, element
    end
end

---@param scope any
---@param block Block
---@return Value
local function eval_block(scope, block)
    local pos = 1
    local last_value = make("word!", "none")

    while pos <= #block.v do
        pos, last_value = eval_expr(scope, block, pos, last_value)
    end
    return last_value
end

String.mold = make_native_fn({
    {},
}, function(_, value)
    return make_with_prototype(String, '"' .. value.v .. '"')
end)

local function repl()
    local scope = env.new()

    scope.hello = make_native_fn({
        { name = "value" },
    }, function(_, value)
        print("Hello " .. value.v)
        return none
    end)

    scope["get-type"] = make_native_fn({
        { name = "name" },
    }, function(_, value)
        return types[value.v]
    end)

    scope["type?"] = make_native_fn({ { name = "value" } }, function(_, value)
        return value.type
    end)

    scope["print-meta"] = make_native_fn({ {} }, function(_, value)
        local meta = getmetatable(value)
        print(table.dumpf(meta))
        return none
    end)

    scope["mold"] = make_action({ {} }, "mold")

    scope["show"] = make_native_fn({ { eval = false } }, function(_, value)
        print(table.dumpf(value))
        return none
    end)

    local function step()
        io.write("> ")
        local code = io.read()
        local block = read_block(code)
        local value = eval_block(scope, block)

        if value ~= nil and value ~= none then
            print(table.dump(value.v))
        end
    end

    local function handle_error(error)
        if error:match("interrupted") then
            os.exit(0, true)
        end
        print(table.dump(error))
        print(debug.traceback())
    end

    while true do
        xpcall(step, handle_error)
    end
end

--repl()

-- TESTS

local code = [[

]]
