-- Graphics.lua

-- Objects are identified based on Graphics!
-- A thing that could be made is save somewhere (maybe a text file instead variables) all the objects
-- and after anyobject.graphics is changed, it will fire an event to not make the object name to change... ect
-- (the hard part is: make the events work correctly with debounecs and also making the game not lag too much)

-- That's the reason I added a variable "isMario" to Object.lua,
-- it will return true if object relative address - 0xB110 equals 0x8033B1F8, that is the N64 Address of Mario itself (*not only)
-- Update: nevermind, value 0xB110 depends on slot index, it's always different, now Mario will just be an object with mario graphic and same position
-- If an Object has Mario's graphics and object.isMario is false, its name will not change
-- The reason of all this is because when you get the object you don't know what is it, but you can understand what is it
-- by its graphics, but objectmanager.getObjects() recalculates all the objects, so if I change an object's graphics and the next
-- frame I call the function again, that object name will depend on graphics, the save object thing could be useful

-- Update: it may be easier and more optimized to just update the function getObjects() to understand what objects are different
-- this way you just need to save the objects only one time, and the next time it gets overwritten and so on

-- Address, Name, Behaviour Script, custom properties (name = {offset, defaultValue, type})
return {
    null = {0x0, "Unknown"},
    mario = {0x800F0860, "Fake Mario"},
    doorwood = {0x8018ECD8, "Wooden Door"},
    doorkey = {0x8018F198, "3 Star Door"},
    doorstar0 = {0x8018EDE4, "0 Star Door"},
    doorstar1 = {0x8018EF20, "1 Star Door"},
    doorstar3 = {0x8018F05C, "3 Star Door"},
    door = {0x8018E8A8, "Standard Door"},
    doorbowser = {0x8018F304, "Star Door"},
    toad = {0x8018E208, "Toad"},
    sign = {0x800F8C4C, "Sign"},
    floatplatform = {0x801949F4, "Floating Island"},
    coin = {0x800F8AA4, "Coin", 0x800EBA9C, {
		shadow = {0x16, 37744, "int"},
		disapbhv = {0x1D4, 0x800EBAB4, "uint"},
		value = {0x180, 1, "int"},
		collctbl = {0x9C, 0, "int"},
	}},
    star = {0x800F8B9C, "Star"},
    starblue = {0x800F8C00, "Blue Star"}
}

-- (*not only): 0x8033B1F8 equals to 2151026312 in decimal, I found this value in multiple places, as said in the N64 address of Mario,
-- but also in the property "Parent obj" of objects that got it set to "(unused object)" in STROOP, and if it's not set to "unused", then
-- it will increase by 0x260 each slot, just like object address (see ObjectManager.lua)