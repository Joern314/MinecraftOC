local robot = require("robot")
local sides = require("sides")
local component = require("component")
local computer = require("computer")
local math = require("math")

--local _geolyzer_name = component.list("geolizer")()
--local geolyzer = component.proxy(geolyzer)

-- load config variables
dofile("conf.lua")

function farm_single()
    --obstacle: true or false
    --type: entity, solid, replaceable, liquid, passable or air
    obstacle, type = robot.detectDown()
    is_hemp = obstacle and type == "passable"
    if is_hemp then
        robot.swingDown()
    end
end

function force_forward()
    local success = false
    repeat
        success = robot.forward()
        if not success then
            os.sleep(1)
        end
    until success
end
function force_back()
    local success = false
    repeat
        success = robot.back()
        if not success then
            os.sleep(1)
        end
    until success
end


function farm_field()
    for iy=1, field_h do
        for ix=1, field_w do
            farm_single()
            if ix < field_w then
                force_forward()
            end
        end
    
        if iy < field_h then
            if iy % 2 == 1 then
                robot.turnLeft()
                force_forward()
                robot.turnLeft()
            else
                robot.turnRight()
                force_forward()
                robot.turnRight()
            end
        end
    end
    robot.turnAround()
end

function needs_charging()
    return computer.maxEnergy() * charger_treshhold > computer.energy()
end
function charge()
    print(string.format("%f: charging initiated", computer.uptime()))
    while needs_charging() do
        os.sleep(1)
    end
    print(string.format("%f: charging completed", computer.uptime()))
end

function move(tx, ty)
    for ix=1, math.abs(tx-1) do
        if tx >= 1 then force_forward() else force_back() end
    end
    robot.turnLeft()
    for iy=1, math.abs(ty-1) do
        if ty >= 1 then force_forward() else force_back() end
    end
    robot.turnLeft()
end

function place_in_chest()
    local count = 0
    for slot=1, robot.inventorySize() do
        robot.select(slot)
        count = count + robot.count()
        robot.dropDown()
        count = count - robot.count()
    end
    print(string.format("%f: deposited %d items in chest", computer.uptime(), count))
end

function idle_at_home(waittime)
    if waittime > 0 then
        print(string.format("%f: delaying next roundtrip", computer.uptime()))
        os.sleep(waittime)
    end
end

function full_cycle()
    local begin = computer.uptime()
    print(string.format("%f: starting new roundtrip", computer.uptime()))

    farm_field()
    move(field_w, field_h)

    move(chest_x, chest_y)
    place_in_chest()
    move(chest_x, chest_y)

    if needs_charging() then
        move(charger_x, charger_y)
        charge()
        move(charger_x, charger_y)
    end

    local waittime = math.max(0, minimum_trip_time - (computer.uptime() - begin))
    idle_at_home(waittime)
end

function full_loop()
    while true do
        full_cycle()
    end
end

full_loop()