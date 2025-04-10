-- A debug lua file

function info(t, e)
	for key, value in pairs(t) do
		print(key, e or "")
	end
end

print(_G.input.get())