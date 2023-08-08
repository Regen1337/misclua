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

local function exec_callback(callback, ...)
    if callback and type(callback) == "function" then
        callback(...)
    end
end

-- function to check if a number is divisible by 2
local function isEven(num)
    return num % 2 == 0
end

local table_insert = table.insert
local table_contains = table.contains
local table_indexed_contains = table.indexed_contains
local table_count = table.count
local table_indexed_count = table.indexed_count

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
            return cache, table_indexed_count(cache)
        else
            return false, 0
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
    end
    
    function turtle.cachePos()
        local x, y, z = gps.locate()
        turtle.position = {x = x, y = y, z = z}

        return turtle.position
    end

    function turtle.getPos()
        return turtle.position
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

