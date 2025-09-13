function RunTests(t)
	local tests = 0
	local success = 0
	for name, test in pairs(t) do
		print("--- " .. name .. " ---")
		local ok, err = pcall(test)
		tests = tests + 1
		if ok then
			success = success + 1
		else
			print(err)
		end
	end

	print("========== Summary ==========")
	print("All: " .. tests .. " Success: " .. success .. " Failed: " .. (tests - success))
end
