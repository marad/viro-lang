local types = require 'viro.types'

local function eval(node, ctx)
  if node.type == types.word then
    return ctx[node.name]
  elseif node.type == types.number then
    return node
  else
    error("Unsupported evaluation: " .. table.dump(node))
  end
end


-- TODO:
-- - Obsługa operatorów infix - działania matematyczne
-- - Podstawowe funkcje
--   - print
-- - Definicja funkcji przez 'fn'
-- - Refinementy funkcji
--   - Obsługa przy definiowaniu
--   - Obsługa przy wywołaniu

local function process(block, ctx)
  assert(block.type == types.block, "Only blocks are supported for processing")
  local content = block.value
  local blk_pos = 1
  local result = nil
  while blk_pos <= #content do
    local item = content[blk_pos]
    --print("Block pos: " .. blk_pos .. " " .. table.dump(item))

    if item.type == types.set_word then
      --
      -- Set Word instruction
      --
      local value = eval(content[blk_pos + 1])
      ctx[item.word.name] = value
      result = value
      blk_pos = blk_pos + 2
    elseif item.type == types.word then
      --
      -- Processing a word
      --
      local value = ctx[item.name]
      blk_pos = blk_pos + 1
      if value.type == types.fn then
        local args = { ctx }
        local argc = value.arg_count
        local index = 0
        while index < argc do
          table.insert(args, eval(content[blk_pos], ctx))
          index = index + 1
          blk_pos = blk_pos + 1
        end
        result = value.fn(table.unpack(args))
      else
        result = value
      end
    else
      --
      -- Other operations
      --
      result = eval(content[blk_pos])
      blk_pos = blk_pos + 1
    end
  end
  return result
end


local code = [[
  x: 10
  print x

  x
]]

--require 'viro.util'
--local env = require 'viro.env'
--local parser = require 'viro.parser'
--local ctx = env.new()
--
--ctx.print = { type = types.fn, fn = function(_, arg) print(table.dump(arg)) end, arg_count = 1 }
--
--
--local block = parser.parse(code)
--local result = process(block, ctx)
--
--print("Result: " .. table.dump(result))
--print("Ctx: " .. table.dump(ctx))




return process
