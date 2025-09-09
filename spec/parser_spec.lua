require "spec"
require "viro.util"
local assert = require "luassert"
local parser = require "viro.parser"
local types = require "viro.types"


RunTests {
  ["parse basic number"] = function()
    local node = parser.parse [[10]].value[1]
    assert.are.same(node.type, types.number)
    assert.are.same(node.value, 10)
  end,

  ["parse string"] = function()
    local node = parser.parse [[ "hello world" ]].value[1]
    assert.are.same(node.type, types.string)
    assert.are.same(node.value, "hello world")
  end,

  ["parse a word"] = function()
    local node = parser.parse [[ hello-world? ]].value[1]
    assert.are.same(node.type, types.word)
    assert.are.same(node.name, "hello-world?")
  end,

  ["parse a block"] = function()
    local node = parser.parse [[ [ 1 ] ]].value[1]
    assert.are.same(node.type, types.block)
    assert.are.same(node.value, { types.makeNumber(4, 1, 5) })
  end,

  ["parse set-word"] = function()
    local block = parser.parse [[ x: 1 ]]
    local set_word = block.value[1]
    local one = block.value[2]
    assert.are.same(set_word.type, types.set_word)
    assert.are.same(set_word.word, types.makeWord(2, "x", 3))
    assert.are.same(one, types.makeNumber(5, 1, 6))
  end,

  ["parse set-path"] = function()
    local node = parser.parse [[ x/foo: 5 ]].value[1]
    assert.are.same(node.word, types.makeWord(2, "x/foo", 7))
    assert.are.same(node.type, types.set_word)
  end,

  ["parse symbols as words"] = function()
    local symbol = parser.parse [[ 1 + 2 ]].value[2]
    assert.are.same(symbol.type, types.word)
    assert.are.same(symbol.name, "+")
  end,


  ["bigger example test"] = function()
    local result = parser.parse [[
      x: 10
      double: fn [x] [ return 2 * x ]

      if double x = 20 [ print "Hello" ]
    ]].value

    assert.are.equal(#result, 12)
  end,
}
