local helper = http.get("https://raw.githubusercontent.com/Regen1337/misclua/main/turtles/helper/helper.lua").readAll()
local miner = http.get("https://raw.githubusercontent.com/Regen1337/misclua/main/turtles/stripper/stripminer.lua").readAll()

local stripminer_file = fs.open("stripminer.lua", "w")
stripminer_file.write(helper .. miner)
stripminer_file.close()

shell.run("stripminer.lua")

print("Loaded stripminer.lua\n")