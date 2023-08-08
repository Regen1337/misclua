local url = "https://example.com/mycode.lua"
local response = http.get(url)
local content = response.readAll()
response.close()

local file = fs.open("mycode.lua", "w")
file.write(content)
file.close()