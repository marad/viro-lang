function RunTests(t)
	for name, test in pairs(t) do
		print("--- " .. name .. " ---")
		local ok, err = pcall(test)
		if not ok then
			print(err)
		end
	end
end
