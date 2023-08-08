local helper = http.get("https://raw.githubusercontent.com/Regen1337/misclua/main/turtles/helper/helper.lua").readAll()
local miner = http.get("https://raw.githubusercontent.com/Regen1337/misclua/main/turtles/stripper/stripminer.lua").readAll()

local helper_file = fs.open("turtle_helper.lua", "w")
helper_file.write(helper)
helper_file.close()

local stripminer_file = fs.open("stripminer.lua", "w")
stripminer_file.write(miner)
stripminer_file.close()

shell.run("turtle_helper.lua")
shell.run("stripminer.lua")

print("Loaded turtle_helper.lua")
print("Loaded stripminer.lua\n")