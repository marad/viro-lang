require("spec")
require("viro.util")
local assert = require("luassert")
local types = require("viro.types")

local b = types.makeBlock
local w = types.makeWord
local s = types.makeString
local n = types.makeNumber


RunTests({
  ["[copy] should shallow-copy block contents"] = function()
    local block = b { w "print", s "hello" }
    local copy = block:copy()

    assert.is_not.equal(block, copy)                -- not the same object in memory
    assert.are.same(block, copy)                    -- but have the same structure/value
    assert.is_not.equal(block.value, copy.value)    -- not the same conent object
    assert.are.same(block.value, copy.value)        -- but the same structure/value
    assert.are.equal(block.value[1], copy.value[1]) -- same object in memory (shallow copy)
    assert.are.equal(block.value[2], copy.value[2]) -- same object in memory (shallow copy)
  end,

  ["[copy] should shallow-copy from given index"] = function()
    local block = b { n(1), n(2), n(3) }
    local copy = block:copy(2)

    assert.are.equal(block.value[2], copy.value[1])
    assert.are.equal(block.value[3], copy.value[2])
  end,

  ["[copy] should copy from current block index"] = function()
    local block = b { n(1), n(2), n(3) }
    block.index = 2
    local copy = block:copy()

    assert.are.equal(block.value[2], copy.value[1])
    assert.are.equal(block.value[3], copy.value[2])
  end,

  ["[next] should return new block with next index selected"] = function()
    local block = b { n(1), n(2), n(3) }
    local next = block:next()

    assert.is_not.equal(block, next)
    assert.are.same(block.value, next.value)
    assert.is.same(block.index, 1)
    assert.is.same(next.index, 2)
  end,

  ["[next] should allow going one position past the last element"] = function()
    local block = b { n(1) }

    local next = block:next()
    assert.is.same(next.index, 2)

    next = block:next() -- and should not move more
    assert.is.same(next.index, 2)
  end,

  ["[back] should return new block with previous index selected"] = function()
    local block = b { n(1), n(2), n(3) }
    block.index = 2
    local prev = block:back()

    assert.is.same(2, block.index)
    assert.is.same(1, prev.index)
  end,

  ["[back] should not allow going before the first block element"] = function()
    local block = b { n(1), n(2), n(3) }
    local prev = block:back()

    assert.is.same(1, block.index)
    assert.is.same(1, prev.index)
  end,

  ["[head] should set index to first element"] = function()
    local block = b { n(1), n(2) }
    block.index = 2
    local head = block:head()

    assert.is.same(2, block.index)
    assert.is.same(1, head.index)
    assert.are.same(head.value, block.value)
  end,

  ["[is_head] should return true if block is at it's first element"] = function()
    local block = b { n(1), n(2) }
    assert.is_true(block:is_head())
    assert.is_false(block:next():is_head())
  end,

  ["[tail] should set index past the last element of the block"] = function()
    local block = b { n(1) }
    local tail = block:tail()

    assert.is.same(1, block.index)
    assert.is.same(2, tail.index)
    assert.are.same(block.value, tail.value)
  end,

  ["[is_tail] should return true if block is after it's last element"] = function()
    local block = b { n(1) }
    assert.is_false(block:is_tail())
    assert.is_true(block:next():is_tail())
  end,

  ["[length] should return block selement count"] = function()
    local block = b { n(1), n(2), n(3) }
    assert.is.same(3, block:length())
  end,

})
