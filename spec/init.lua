function RunTests(t)
  for name, test in pairs(t) do
    print("--- " .. name .. " ---")
    test()
  end
end
