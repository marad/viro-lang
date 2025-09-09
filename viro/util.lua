function table.dump(o, indent)
  if indent == nil then
    indent = ""
  end
  local baseindent = indent
  indent = indent .. "  "

  if type(o) == 'table' then
    local result = {}
    for k, v in pairs(o) do
      --if type(k) ~= 'number' then k = '"' .. k .. '"' end
      table.insert(result, indent .. k .. ' = ' .. table.dump(v, indent))
    end
    return "{\n" .. table.concat(result, ",\n") .. "\n" .. baseindent .. "}"
  else
    return tostring(o)
  end
end
