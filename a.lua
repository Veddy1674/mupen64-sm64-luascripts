local file = "savestate"

-- Verifica se _G[file] esiste ed è una tabella
if type(_G[file]) ~= "table" then
    error(file .. " non è una tabella globale o non esiste.")
end

print("global record " .. file)
print("\t-- in-built")
for b, a in pairs(_G[file]) do
    if type(a) == "function" then
        -- Non chiamare la funzione, ma stampa solo la sua firma
        print("\t" .. b .. ": function()")
    else
        -- Gestione di tipi complessi (come tabelle)
        if type(a) == "table" then
            print("\t" .. b .. ": table")
        else
            print("\t" .. b .. " = " .. tostring(a))
        end
    end
end
print("end")
local a = emu.set_ff()
print(a)
--_G.savestate.loadfile()

--local a = _G.emu.inputcount()
--print(a)

-- for a, b in pairs(joypad.get()) do
	-- print("\t" .. a .. ": " .. type(b))
-- end