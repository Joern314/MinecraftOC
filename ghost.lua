-- Library which helps with navigation by keeping track of the robot's state

-- the robot's position takes the form X,Y,Z with some arbitrary reference point
-- the robot's orientation takes the form D=0,...,3 where 0=positive X, 1=positive Z, 2=negative X, 3=negative Z, 4=positive Y, 5=negative Y

Ghost = {x=0,y=0,z=0,d=0,  real=false, file=nil}

-- constructor
function Ghost:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- suggested constructor for the _one_ real ghost
local _real = Ghost:new({real=true, file="/home/state_ghost.txt"})
_real:load()

-- dot notation
Real = {}
function Real.sideToDir(S) 
    return _real:sideToDir(S)
end

function Real.dirToSide(D)
    return _real:dirToSide(D)
end

function 


-- convert side, direction, normal 
function Ghost:sideToDir(S)
    _lookup = {
        [sides.up]= 4,
        [sides.down] = 5,
        [sides.front] = (self.d),
        [sides.back] = (self.d+2)%4,
        [sides.left] = (self.d+1)%4,
        [sides.right] = (self.d+1)%4,
    }
    return _lookup[S]
end

function Ghost:dirToSide(D)
    if D == 4 then 
        return sides.up
    elseif D == 5 then 
        return sides.down
    else
        dd = (D-self.d+4)%4
        _lookup = {
            [0] = sides.front,
            [1] = sides.left,
            [2] = sides.back,
            [3] = sides.right
        }
        return _lookup[dd]
    end
end

_lookup_normal = {
    [0]= {1,0,0},
    [1]= {0,0,1},
    [2]= {-1,0,0},
    [3]= {0,0,-1},
    [4]= {0,1,0},
    [5]= {0,-1,0},
}
function Ghost:dirToNormal(D)
    return unpack(_lookup_normal(D))
end

function Ghost:sideToNormal(S)
    return self:dirToNormal(self:sideToDir(S))
end

-- HELPER functions for movement

function Ghost:_moveBy(dx, dy, dz)
    self.x = self.x + dx
    self.y = self.y + dy
    self.z = self.z + dz
end

function Ghost:_moveToDir(D)
    nx,ny,nz = self:dirToNormal(D)
    self:_moveBy(nx,ny,nz)
end

function Ghost:_moveToSide(S)
    self:_moveToDir(self:sideToDir(S))
end

-- NEW functions for serialization
function Ghost:serialize()
    return string.format("{%d,%d,%d,%d}", self.x, self.y, self.z, self.d)
end
function Ghost:deserialize(str)
    x,y,z,d = str:match("{%d+,%d+,%d+,%d+}")
    self.x = tonumber(x)
    self.y = tonumber(y)
    self.z = tonumber(z)
    self.d = tonumber(d)
end

function Ghost:save(file)
    file = file or self.file
    if file ~= nil then
        f = assert(io.open(file, "w"))
        f:write(self:serialize())
        f.close()
    end
end

function Ghost:load(file)
    file = file or self.file
    if file ~= nil then
        f = assert(io.open(file, "r"))
        str = f:read("*all")
        self:deserialize(str)
        f.close()
    end
end

-- OVERRIDE of movement functions

function Ghost:turnLeft()
    self.d = (self.d+1) % 4
    if self.real then robot.turnLeft() end
    if self.file then self:save() end
end

function Ghost:turnRight()
    self.d = (self.d+3) % 4
    if self.real then robot.turnRight() end
    if self.file then self:save() end
end

function Ghost:turnAround()
    self.d = (self.d+2) % 2
    if self.real then robot.turnAround() end
    if self.file then self:save() end
end

function Ghost:forward()
    self:_moveToSide(sides.forward)
    if self.real then robot.forward() end
    if self.file then self:save() end
end

function Ghost:back()
    self:_moveToSide(sides.back)
    if self.real then robot.back() end
    if self.file then self:save() end
end

function Ghost:up()
    self:_moveToSide(sides.up)
    if self.real then robot.up() end
    if self.file then self:save() end
end

function Ghost:down()
    self:_moveToSide(sides.down)
    if self.real then robot.down() end
    if self.file then self:save() end
end

-- NEW movement functions
-- preferably use these functions from now on!
function Ghost:turnToDir(D)
    S = self:dirToSide(D)
    if S == sides.left then 
        self:turnLeft()
    elseif S == sides.right then 
        self:turnRight()
    elseif S == sides.forward then 
        return -- nothing to then
    elseif S == sides.back then
        self:turnAround()
    else
        return -- unsupported direction
    end
end

-- Note: thenes not necessarily preserve direction
function Ghost:moveToDir(D, preserve_dir)
    preserve_dir = preserve_dir or false

    S = self:dirToSide(D)
    if S == sides:forward() then
        self:forward()
    elseif S == sides.back then
        self:back()
    elseif S == sides.up then
        self:up()
    elseif S == sides.down then
        self:down()
    elseif S == sides.left then
        self:turnLeft()
        self:forward()
        if preserve_dir then 
            self:turnRight() 
        end
    elseif S == sides.right then
        self:turnRight()
        self:forward()
        if preserve_dir then 
            self:turnLeft() 
        end
    end
end

real = {}
function real.sideToDir(S)
    return _uniqsideToDir(S)

module = {
    Ghost=Ghost,
    real=real
}

return Ghost