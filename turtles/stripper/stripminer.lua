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
local function handleObstacles(cur_height)
    local up_inspect, up_info = turtle.inspectUp()
    local down_inspect, down_info = turtle.inspectDown()
    local front_inspect, front_info = turtle.inspect()
    up_inspect = (up_inspect and up_info) and up_info.name or false
    down_inspect = (down_inspect and down_info) and down_info.name or false
    front_inspect = (front_inspect and front_info) and front_info.name or false

    if up_inspect and table.contains(config.obstacles.diggable, up_inspect) then
        turtle.recurseDigObstacle(1)
    end

    if front_inspect and table.contains(config.obstacles.diggable, front_inspect) then
        turtle.recurseDigObstacle(3)
    end

    if down_inspect and table.contains(config.obstacles.diggable, down_inspect) then
        turtle.recurseDigObstacle(2)
    end

    if not down_inspect and cur_height and cur_height <= 1 then
        os.sleep(0.2)
        turtle.placeMineFloor()
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
        handleObstacles(current_height)
        turtle_step = turtle_step + 1

        local slots, slots_count = turtle.findStripMinerUnloadSlots()
        slots_count = turtle.getItemsCount() - slots_count

        if slots_count <= 1 and current_height <= 1 then
            turtle.unloadItems()
        end

        turtle.recurseForward()

        new_length = math.max(0, new_length - 1)
    end

    if height > 1 and current_height < height then

        turtle.rotate180()
        turtle.recurseUp()

        mineTunnel(length, height, current_height)
        return
    elseif height >1 and current_height >= height then
        if isEven(height) then 
            turtle.rotate180(POST_ROTATION, function() 
                for _ = 1, current_height - 1 do
                    turtle.recurseDown(function()
                        current_height = current_height - 1
                    end)
                    
                    os.sleep(0.1)
                end
            end)
        else
            turtle.rotate180(POST_ROTATION, function() 
                for _ = 1, current_height - 1 do
                    turtle.recurseDown(function()
                        current_height = current_height - 1
                    end)
                
                    os.sleep(0.1)
                end

                for i = 1, length do
                    turtle.recurseForward()

                    if i % torchInterval == 0 and i % current_height == 0 then
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
    direction = (direction == "left") and -1 or 1
    divider_length = divider_length + 1

    turtle.doRefuel()
    mineTunnel(divider_length * count, height)
    os.sleep(0.5)
    turtle.rotate90(direction)

    for _ = 1, count do
        turtle.doRefuel()
        turtle.rotate90(direction * -1)

        for _ = 1, divider_length do
            turtle.recurseForward()
        end
        turtle.rotate90(direction)

        mineTunnel(length, height)
    end
    
end

-- Main script
print("Welcome to Strip Mining Turtle!")
print("Please provide the number of tunnel(s):")
local tunnelCount = tonumber(read())
if not tunnelCount or tunnelCount <= 0 then
    tunnelCount = 0
end

print("Please provide the number of blocks between the tunnel(s):")
local tunnelDivider = tonumber(read())
if not tunnelDivider or tunnelDivider <= 0 then
    tunnelDivider = 0
end

print("Please provide the height of the tunnel(s):")
local tunnelHeight = tonumber(read())
if not tunnelHeight or tunnelHeight <= 0 then
    tunnelHeight = 1
end

print("Please provide the length of the tunnel(s):")
local tunnelLength = tonumber(read())
if not tunnelLength or tunnelLength <= 0 then
    tunnelLength = 1
end

if isEven(tunnelLength) then
    tunnelLength = tunnelLength + 1
end

print("Please provide the direction of the tunnel(s) (left or right):")
local tunnelDirection =  string.lower(tostring(read()))
if not tunnelDirection or (tunnelDirection ~= "left" and tunnelDirection ~= "right") then
    print(string.format("Invalid direction provided: %s", tunnelDirection))
    return
end
tunnelDirection = string.lower(tunnelDirection)

turtle.doRefuel()
mineBranchTunnel {tunnelCount, tunnelDivider, tunnelHeight, tunnelDirection, tunnelLength} 


print("Strip Mining Turtle has completed its task!")