local torchName = "minecraft:torch"
local chestName = "minecraft:chest"
local coalName, coalBlockName = "minecraft:coal", "minecraft:coal_block"


local config = {
    torchPlacementInterval = 5,
    fuelThreshold = 500,
    itemThreshold = 10
}

local unload = {
    blacklist = {
        torchName, chestName, coalName, coalBlockName
    }
}

do
    function table.contains(table, element)
        for _, value in next, (table) do
            if value == element then
                return true
            end
        end
        return false
    end

    function table.indexed_contains(table, element)
        for _, value in ipairs(table) do
            if value == element then
                return true
            end
        end
        return false
    end

    function table.count(table)
        local count = 0
        for _ in next, (table) do
            count = count + 1
        end
        return count
    end

    function table.indexed_count(table)
        local count = 0
        for _ in ipairs(table) do
            count = count + 1
        end
        return count
    end
end

local table_insert = table.insert
local table_contains = table.contains
local table_indexed_contains = table.indexed_contains
local table_count = table.count
local table_indexed_count = table.indexed_count

local function exec_callback(callback, ...)
    if callback and type(callback) == "function" then
        callback(...)
    end
end

do
    turtle.rotation_states = {
        PRE_ROTATION = 1,
        DUR_ROTATION = 2,
        POST_ROTATION = 3
    }

    -- Function to get the turtle's inventory
    function turtle.getItems()
        local items = {}
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item then
                table_insert(items, item)
            end
        end
        return items
    end

    -- Function to get the number of empty slots in the turtle's inventory
    function turtle.getItemsCount()
        local space = 0
        for slot = 1, 16 do
            if not turtle.getItemDetail(slot) then
                space = space + 1
            end
        end
        return space
    end

    -- Find slot number of an item by a array of names
    function turtle.findSlot(itemNames)
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and table_indexed_contains(itemNames, item.name) then
                return slot
            end
        end
        return nil
    end

    -- Find unloading blacklisted slots
    function turtle.findUnloadBlacklistedSlots()
        local cache = {}
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and table_indexed_contains(unload.blacklist, item.name) then
                table_insert(cache, slot)
            end
        end
        
        if table_indexed_count(cache) > 0 then
            return cache
        else
            return nil
        end
    end

    -- Function to refuel the turtle
    function turtle.doRefuel()
        while turtle.getFuelLevel() < config.fuelThreshold do
            local refueled = false
            local fuelSlot = turtle.findSlot {coalName, coalBlockName}
            if fuelSlot then
                turtle.select(fuelSlot)
                if turtle.refuel(1) then
                    refueled = true
                end
            end
            if not refueled then
                print("Out of fuel. Please provide more fuel in the turtle's inventory.")
                os.pullEvent("turtle_inventory")
            end
        end
    end

    -- Function to unload valuable items
    function turtle.unloadItems()
        local chestSlot = turtle.findSlot {chestName}
        if chestSlot then
            turtle.select(chestSlot)
            turtle.digDown()

            if not turtle.placeDown() then
                print("Unable to place chest. Please make sure there's a chest in the turtle's inventory.")
                os.pullEvent("turtle_inventory")
            end

            for slot = 1, 16 do
                if not table_indexed_contains(unload.blacklist, turtle.getItemDetail(slot).name) then
                    turtle.select(slot)
                    turtle.dropDown()
                end
            end
        end

        function turtle.cachePos()
            local x, y, z = gps.locate()
            turtle.position = {x = x, y = y, z = z}

            return turtle.position
        end

        function turtle.getPos()
            return turtle.position
        end
    end

    local PRE_ROTATION = turtle.rotation_states.PRE_ROTATION
    local DUR_ROTATION = turtle.rotation_states.DUR_ROTATION
    local POST_ROTATION = turtle.rotation_states.POST_ROTATION

    -- Function to rotate the turtle 360 degrees and execute a callback
    function turtle.rotate360(method, callback, ...)
        if callback and not type(callback) == "function" then return end
        if method <= 0 or method > table_indexed_count(turtle.rotation_states) then return end

        if method == PRE_ROTATION then
            exec_callback(callback, ...)
        end
        turtle.turnLeft()
        turtle.turnLeft()
        if method == DUR_ROTATION then
            exec_callback(callback, ...)
        end
        turtle.turnLeft()
        turtle.turnLeft()
        if method == POST_ROTATION then
            exec_callback(callback, ...)
        end
    end

    -- Function to rotate the turtle 180 degrees and execute a callback
    function turtle.rotate180(method, callback, ...)
        if callback and not type(callback) == "function" then return end
        if method <= 0 or method > table_indexed_count(turtle.rotation_states) then return end

        if method == PRE_ROTATION then
            exec_callback(callback, ...)
        end
        turtle.turnLeft()
        if method == DUR_ROTATION then
            exec_callback(callback, ...)
        end
        turtle.turnLeft()
        if method == POST_ROTATION then
            exec_callback(callback, ...)
        end        
    end
end

local PRE_ROTATION = turtle.rotation_states.PRE_ROTATION
local DUR_ROTATION = turtle.rotation_states.DUR_ROTATION
local POST_ROTATION = turtle.rotation_states.POST_ROTATION

-- Function to place torches
local function placeTorches()
    local torchSlot = turtle.findSlot {torchName} 
    if torchSlot then
        local torchCount = turtle.getItemCount(torchSlot)
        if torchCount > 0 then
            turtle.select(torchSlot)
            turtle.rotate360(PRE_ROTATION, turtle.place)
        end
    end
end

-- Function to handle obstacles
local function handleObstacles()
    local success = false
    while not success do
        local blockDetected, blockData = turtle.inspect()
        if blockDetected then
            local blockName = blockData.name
            if blockName == "minecraft:lava" or blockName == "minecraft:flowing_lava" or
               blockName == "minecraft:water" or blockName == "minecraft:flowing_water" then
                turtle.dig()
            elseif blockName == "minecraft:sand" or blockName == "minecraft:gravel" then
                turtle.dig()
                turtle.place()
            else
                success = true
            end
        else
            success = true
        end
    end
end

-- Function to mine a tunnel
local function mineTunnel(length, height)
    local new_length = length
    local torchInterval = config.torchPlacementInterval
    local turtle_start_pos = turtle.cachePos()
    local start_height_y = turtle_start_pos.y
    local turtle_step = 0

    for i = 1, new_length do
        handleObstacles()
        turtle_step = turtle_step + 1

        if not turtle.forward() then
            turtle.dig()
            turtle.forward()
        end

        new_length = math.max(0, new_length - 1)

        if i % torchInterval == 0 then
            print(string.format("Placing torch. Distance from start: %d", i))
            placeTorches()
        end

        if height > 1 then
            for x = 1, height - 1 do
                if not turtle.up() then
                    turtle.digUp()
                    turtle.up() 
                end
            end

            while turtle.cachePos().y > start_height_y do
                turtle.down()
            end

            if turtle_step == length then
                turtle.forward()
            end 
        end    
    end

    print(string.format("Tunnel mined. Length: %d", length - new_length))
    if new_length > 0 then
        mineTunnel(new_length, height)
    end
end

-- Function to mine a branch tunnel
local function mineBranchTunnel(data)
    local count, length, height, divider_length, direction = unpack(data)
    local direction = (direction == "left") and -1 or 1

    for i = 1, count do
        mineTunnel(length, height)

        --[[
        Return to the main tunnel and move forward by divider length
        
        turtle.turnLeft()
        for _ = 1, divider_length do
            if not turtle.forward() then
                turtle.dig()
                turtle.forward()
            end
        end
        turtle.turnRight()

        Move to the new branch tunnel position
        
        for _ = 1, (i == count and 0 or 1) do
            turtle.forward()
        end
        turtle.turnRight(direction)
        ]]
        -- Refuel and continue to the next branch
        turtle.doRefuel()
    end
end

-- Main script
print("Welcome to Strip Mining Turtle!")
print("Please provide the number of tunnel(s):")
local tunnelCount = tonumber(read())
if not tunnelCount or tunnelCount <= 0 then
    print("Invalid input. Exiting.")
    return
end

print("Please provide the number of blocks between the tunnel(s):")
local tunnelDivider = tonumber(read())
if not tunnelDivider or tunnelDivider <= 0 then
    print("Invalid input. Exiting.")
    return
end

print("Please provide the height of the tunnel(s):")
local tunnelHeight = tonumber(read())
if not tunnelHeight or tunnelHeight <= 0 then
    print("Invalid input. Exiting.")
    return
end

print("Please provide the direction of the tunnel(s) (left or right):")
local tunnelDirection =  string.lower(tostring(read()))
if not tunnelDirection or (tunnelDirection ~= "left" and tunnelDirection ~= "right") then
    print("Invalid input. Exiting.")
    return
end

print("Please provide the length of the tunnel(s):")
local tunnelLength = tonumber(read())
if not tunnelLength or tunnelLength <= 0 then
    print("Invalid input. Exiting.")
else
    turtle.doRefuel()
    mineBranchTunnel {tunnelCount, tunnelLength, tunnelHeight, tunnelDivider} 
end


print("Strip Mining Turtle has completed its task!")
