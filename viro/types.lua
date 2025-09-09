local types = {
  word = 1,
  set_word = 2,
  set_path = 3,
  block = 4,
  string = 5,
  number = 6,
  fn = 7,
}



local function makePos(from, to)
  return { from = from, to = to }
end

function types.makeWord(from, word, to)
  return { type = types.word, name = word, srcPos = makePos(from, to) }
end

function types.makeSetWord(from, word, to)
  return { type = types.set_word, word = word, srcPos = makePos(from, to) }
end

function types.makeSetPath(from, word, path, to)
  return { type = types.set_path, word = word, path = path, srcPos = makePos(from, to) }
end

function types.makeBlock(from, content, to)
  return { type = types.block, value = content, srcPos = makePos(from, to) }
end

function types.makeString(from, content, to)
  return { type = types.string, value = content, srcPos = makePos(from, to) }
end

function types.makeNumber(from, value, to)
  return { type = types.number, value = tonumber(value), srcPos = makePos(from, to) }
end

function types.makeFn(from, fn, to)
  return { type = types.fn, value = fn, srcPos = makePos(from, to) }
end

return types
