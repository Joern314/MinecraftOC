-- Library which helps with navigation by keeping track of the robot's state

-- the robot's position takes the form X,Y,Z with some arbitrary reference point
-- the robot's orientation takes the form D=0,...,3 where 0=positive X, 1=positive Z, 2=negative X, 3=negative Z, 4=positive Y, 5=negative Y

local obj = {x=0,y=0,z=0,d=0, real=true, file="/home/state_txt"}

-- convert side, direction, normal 
local function sideToDir(S)
    _lookup = {
        [sides.up]= 4,
        [sides.down] = 5,
        [sides.front] = (obj.d),
        [sides.back] = (obj.d+2)%4,
        [sides.left] = (obj.d+1)%4,
        [sides.right] = (obj.d+1)%4,
    }
    return _lookup[S]
end

local function dirToSide(D)
    if D == 4 then 
        return sides.up
    elseif D == 5 then 
        return sides.down
    else
        dd = (D-obj.d+4)%4
        _lookup = {
            [0] = sides.front,
            [1] = sides.left,
            [2] = sides.back,
            [3] = sides.right
        }
        return _lookup[dd]
    end
end

local function dirToNormal(D)
    local _lookup_normal = {
        [0]= {1,0,0},
        [1]= {0,0,1},
        [2]= {-1,0,0},
        [3]= {0,0,-1},
        [4]= {0,1,0},
        [5]= {0,-1,0},
    }
    local x,y,z = table.unpack(_lookup_normal[D])
    return x,y,z
end

local function sideToNormal(S)
    return dirToNormal(sideToDir(S))
end

-- HELPER local functions for movement

local function _moveBy(dx, dy, dz)
    obj.x = obj.x + dx
    obj.y = obj.y + dy
    obj.z = obj.z + dz
end

local function _moveTo(x, y, z)
    obj.x = x
    obj.y = y
    obj.z = z
end

local function _moveToDir(D)
    local nx,ny,nz = dirToNormal(D)
    _moveBy(nx,ny,nz)
end

local function _moveToSide(S)
    _moveToDir(sideToDir(S))
end

-- NEW local functions for serialization
local function serialize()
    return string.format("{%d,%d,%d,%d}", obj.x, obj.y, obj.z, obj.d)
end
local function deserialize(str)
    local x,y,z,d = str:match("{%d+,%d+,%d+,%d+}")
    obj.x = tonumber(x)
    obj.y = tonumber(y)
    obj.z = tonumber(z)
    obj.d = tonumber(d)
end

local function save(file)
    local file = file or obj.file
    if file ~= nil then
        f = assert(io.open(file, "w"))
        f:write(serialize())
        f:close()
    end
end

local function load(file)
    local file = file or obj.file
    if file ~= nil then
        f = assert(io.open(file, "r"))
        str = f:read("*all")
        deserialize(str)
        f:close()
    end
end

-- OVERRIDE of movement local functions

local function turnLeft()
    obj.d = (obj.d+1) % 4
    if obj.real then robot.turnLeft() end
    if file then save() end
end

local function turnRight()
    obj.d = (obj.d+3) % 4
    if obj.real then robot.turnRight() end
    if file then save() end
end

local function turnAround()
    obj.d = (obj.d+2) % 2
    if obj.real then robot.turnAround() end
    if file then save() end
end

local function forward()
    _moveToSide(sides.forward)
    if obj.real then robot.forward() end
    if file then save() end
end

local function back()
    _moveToSide(sides.back)
    if obj.real then robot.back() end
    if file then save() end
end

local function up()
    _moveToSide(sides.up)
    if obj.real then robot.up() end
    if file then save() end
end

local function down()
    _moveToSide(sides.down)
    if obj.real then robot.down() end
    if file then save() end
end

-- NEW movement local functions
-- preferably use these local functions from now on!
local function turnToDir(D)
    local S = dirToSide(D)
    if S == sides.left then 
        turnLeft()
    elseif S == sides.right then 
        turnRight()
    elseif S == sides.forward then 
        return -- nothing to then
    elseif S == sides.back then
        turnAround()
    else
        return -- unsupported direction
    end
end

-- Note: thenes not necessarily preserve direction
local function moveToDir(D, preserve_dir)
    preserve_dir = preserve_dir or false

    local S = dirToSide(D)
    if S == sides:forward() then
        forward()
    elseif S == sides.back then
        back()
    elseif S == sides.up then
        up()
    elseif S == sides.down then
        down()
    elseif S == sides.left then
        turnLeft()
        forward()
        if preserve_dir then 
            turnRight() 
        end
    elseif S == sides.right then
        turnRight()
        forward()
        if preserve_dir then 
            turnLeft() 
        end
    end
end

local function xyzd()
    return obj.x, obj.y, obj.z, obj.d
end

return {
    obj=obj,
    xyzd=xyzd,

    sideToDir=sideToDir,
    dirToSide=dirToSide,
    dirToNormal=dirToNormal,
    sideToNormal=sideToNormal,

    serialize=serialize,
    deserialize=deserialize,
    save=save,
    load=load,

    turnLeft=turnLeft,
    turnRight=turnRight,
    turnAround=turnAround,
    forward=forward,
    back=back,
    up=up,
    down=down,
    turnToDir=turnToDir,
    moveToDir=moveToDir
}