-- Function to place torches
local function placeTorches()
    local torchSlot = turtle.findSlot {torchName} 
    if torchSlot then
        local torchCount = turtle.getItemCount(torchSlot)
        if torchCount > 0 then
            turtle.select(torchSlot)
            turtle.rotate360(DUR_ROTATION, turtle.place)
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
local function mineTunnel(length, height, current_height)
    current_height = current_height or 0; current_height = current_height + 1;
    local torchInterval = config.torchPlacementInterval
    local new_length = length
    local turtle_step = 0
    local tunnel_done = false

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

        local slots, slots_count = turtle.findUnloadBlacklistedSlots()
        if slots_count >= config.itemThreshold then
            turtle.unloadItems()
        end
    end

    print(string.format("Height: %d, Current Height: %d", height, current_height))
    if height > 1 and current_height < height then

        turtle.rotate180()
        turtle.recurseUp()

        mineTunnel(length, height, current_height)
        return
    elseif height >1 and current_height >= height then
        if isEven(height) then 
            turtle.rotate180(POST_ROTATION, function() 
                while current_height > 1 do
                    if not turtle.down() then
                        turtle.digDown()
                        turtle.down()
                    end
                    current_height = current_height - 1
                    os.sleep(0.1)
                    print(string.format("Height: %d, Current Height: %d", height, current_height))
                end
            end)
        else
            --[[
            turtle.rotate360(DUR_ROTATION, function() 
                while current_height > 1 do
                    if not turtle.down() then
                        turtle.digDown()
                        turtle.down()
                    end
                    current_height = current_height - 1
                    os.sleep(0.1)
                    print(string.format("Height: %d, Current Height: %d", height, current_height))
                end
            end)
            ]]

            turtle.rotate180(POST_ROTATION, function() 
                while current_height > 1 do
                    if not turtle.down() then
                        turtle.digDown()
                        turtle.down()
                    end
                    current_height = current_height - 1
                    os.sleep(0.1)
                    print(string.format("Height: %d, Current Height: %d", height, current_height))
                end

                -- move to end of tunnel
                for i = 1, length do
                    turtle.recurseForward()

                    if i % torchInterval == 0 then
                        print(string.format("Placing torch. Distance from start: %d", i))
                        placeTorches()
                    end
                end

                turtle.rotate180()
            end)
        end
    end


    if new_length > 0 then
        mineTunnel(new_length, height, current_height)
    end
end

-- Function to mine a branch tunnel
local function mineBranchTunnel(data)
    local count, divider_length, height, direction, length = unpack(data)
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

print("Please provide the length of the tunnel(s):")
local tunnelLength = tonumber(read())

--[[
print("Please provide the direction of the tunnel(s) (left or right):")
local tunnelDirection =  string.lower(tostring(read()))
if not tunnelDirection or (string.lower(tunnelDirection) ~= "left" and string.lower(tunnelDirection) ~= "right") then
    print("Invalid input. Exiting.")
    return
end
tunnelDirection = string.lower(tunnelDirection)
]]
tunnelDirection = "left"

if not tunnelLength or tunnelLength <= 0 then
    print("Invalid input. Exiting.")
else
    turtle.doRefuel()
    mineBranchTunnel {tunnelCount, tunnelDivider, tunnelHeight, tunnelDirection, tunnelLength} 
end


print("Strip Mining Turtle has completed its task!")
