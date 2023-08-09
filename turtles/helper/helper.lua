local torchName = "minecraft:torch"
local chestName = "minecraft:chest"
local coalName, coalBlockName = "minecraft:coal", "minecraft:coal_block"
local sandName, gravelName = "minecraft:sand", "minecraft:gravel"
local lavaName, waterName = "minecraft:lava", "minecraft:water"
local lavaFlowName, waterFlowName = "minecraft:flowing_lava", "minecraft:flowing_water"
local cobblestoneName, andesiteName, dioriteName, graniteName = "minecraft:cobblestone", "minecraft:andesite", "minecraft:diorite", "minecraft:granite"

local config = {
    torchPlacementInterval = 5,
    fuelThreshold = 500,
    obstacles = {
        diggable = {
            sandName, gravelName
        },
        undiggable = {
            lavaName, waterName, lavaFlowName, waterFlowName
        }
        floorable = {
            cobblestoneName, andesiteName, dioriteName, graniteName
        }
    }
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

    function turtle.recurseUp()
        if turtle.digUp() then
            if not turtle.up() then
                os.sleep(0.2)
                turtle.recurseUp()
            else
                os.sleep(0.1)
            end
        elseif turtle.detectUp() then
            os.sleep(0.2)
            turtle.recurseUp()
        else
            if not turtle.up() then
                os.sleep(0.2)
                turtle.recurseUp()
            else
                os.sleep(0.1)
            end
        end
    end

    function turtle.recurseForward()
        if not turtle.forward() then
            turtle.dig()
            turtle.recurseForward()
        end
    end

    function turtle.recurseDigObstacle(direction)
        local dig = direction == 1 and turtle.digUp or direction == 2 and turtle.digDown or turtle.dig
        local inspect, info = direction == 1 and turtle.inspectUp or direction == 2 and turtle.inspectDown or turtle.inspect

        if inspect and info and table_contains(config.obstacles.diggable, info.name) then
            os.sleep(0.2)
            dig()
            turtle.recurseDigObstacle(direction)
        end

    end

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

    function turtle.getItemsCount()
        local space = 0
        for slot = 1, 16 do
            if not turtle.getItemDetail(slot) then
                space = space + 1
            end
        end
        return space
    end

    function turtle.findSlot(itemNames)
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and table_indexed_contains(itemNames, item.name) then
                return slot
            end
        end
        return nil
    end

    function turtle.findStripMinerUnloadSlots(bWhitelist)
        local cache = {}
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and (bWhitelist and not table_indexed_contains(unload.blacklist, item.name) or not bWhitelist and table_indexed_contains(unload.blacklist, item.name)) then
                table_insert(cache, slot)
            end
        end
        
        if table_indexed_count(cache) > 0 then
            return cache, table_indexed_count(cache)
        else
            return false, 0
        end
    end

    function turtle.placeMineFloor()
        local floorableSlot = turtle.findSlot(config.obstacles.floorable)
        if floorableSlot then
            turtle.select(floorableSlot)
            turtle.placeDown()
        end
    end

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

    function turtle.unloadItems()
        local chestSlot = turtle.findSlot {chestName}
        if chestSlot then
            turtle.select(chestSlot)
            turtle.digDown()

            if not turtle.placeDown() then
                print("Unable to place chest. Please make sure there's a chest in the turtle's inventory.")
                os.pullEvent("turtle_inventory")
            end

            local slots, count = turtle.findStripMinerUnloadSlots(true)
            if slots then
                for i = 1, count do
                    turtle.select(slots[i])
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

    function turtle.rotate360(method, callback, ...)
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

    function turtle.rotate180(method, callback, ...)        
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

    -- rotates 90 degrees based on -1 (left) or 1 (right) input and executes a callback
    function turtle.rotate90(direction, method, callback, ...)
        if method == PRE_ROTATION then
            exec_callback(callback, ...)
        end
        if method == DUR_ROTATION then
            exec_callback(callback, ...)
        end
        if direction == -1 then
            turtle.turnLeft()
        elseif direction == 1 then
            turtle.turnRight()
        end
        if method == POST_ROTATION then
            exec_callback(callback, ...)
        end
    end

end

local PRE_ROTATION = turtle.rotation_states.PRE_ROTATION
local DUR_ROTATION = turtle.rotation_states.DUR_ROTATION
local POST_ROTATION = turtle.rotation_states.POST_ROTATION