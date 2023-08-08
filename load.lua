local content = http.get("https://raw.githubusercontent.com/Regen1337/misclua/main/stripminer.lua").readAll()

local file = fs.open("stripminer.lua", "w")
file.write(content)
file.close()

print("Loaded stripminer.lua\n")

shell.run("stripminer.lua")
