local serialization = require("serialization")
local sides = require("sides")
local os = require("os")
local robot = require("robot")

local state = {
    x=0,
    y=0,
    z=0,
    facing=0
}

function getPosition()
    return state.x,state.y,state.z
end

function getFacing()
    return state.facing
end

function findWaypoints()
    return {}
end

--

function toNormal(facing)
    local lookup = {
        [sides.negy]={0,-1,0},
        [sides.posy]={0,1,0},
        [sides.negz]={0,0,-1},
        [sides.posz]={0,0,1},
        [sides.negx]={-1,0,0},
        [sides.posx]={1,0,0},
    }
    return table.unpack(lookup[facing])
end

function toSide(facing)
    if facing == toFacing(sides.up) then
        return sides.up
    elseif facing == toFacing(sides.down) then
        return sides.down
    elseif facing == toFacing(sides.forward) then
        return sides.forward
    elseif facing == toFacing(sides.left) then
        return sides.left
    elseif facing == toFacing(sides.right) then
        return sides.right
    elseif facing == toFacing(sides.back) then
        return sides.back
    else
        return nil
    end
end

function toFacing(side)
    if side == sides.up then
        return state.posy
    elseif side == sides.down then
        return state.negy 
    elseif side == sides.forward then
        return state.facing
    elseif side == sides.back then
        return ({
            [sides.negz]=sides.posz,
            [sides.posz]=sides.negz,
            [sides.negx]=sides.posx,
            [sides.posx]=sides.negx,
        })[state.facing]
    elseif side == sides.left then
        return ({
            [sides.negz]=sides.negx,
            [sides.negx]=sides.posz,
            [sides.posz]=sides.posx,
            [sides.posx]=sides.negz,
        })[state.facing]
    elseif side == sides.right then
        return ({
            [sides.negz]=sides.posx,
            [sides.posx]=sides.posz,
            [sides.posz]=sides.negx,
            [sides.negx]=sides.negz,
        })[state.facing]
    else
        return nil
    end
end

function turnSide(side)
    local success, err
    if side == sides.forward then
        return true, nil
    elseif side == sides.left then
        success, err = robot.turnLeft()
        if not success then
            return success, err
        end
        _turn(toFacing(sides.left))
    elseif side == sides.right then
        success, err = robot.turnRight()
        if not success then
            return success, err
        end
        _turn(toFacing(sides.right))
    elseif side == sides.back then
        success, err = robot.turnAround()
        if not success then
            return success, err
        end
        _turn(toFacing(sides.back))
    else
        return false, "illegal argument"
    end

    return true, nil
end

function turn(facing)
    return turnSide(toSide(facing))
end

function _turn(facing)
    state.facing = facing
end

function _move(facing)
    local nx,ny,nz = toNormal(facing)
    state.x = state.x+nx
    state.y = state.y+ny
    state.z = state.z+nz
end

function setState(x,y,z,facing)
    state.x = x
    state.y = y
    state.z = z
    state.facing = facing
end

function moveSide(side, preserve_facing)
    local preserve_facing = preserve_facing or false
    local success, err
    if side == sides.forward then
        success, err = robot.forward()
        if not success then 
            return success, err
        end
        _move(toFacing(sides.forward))
    elseif side == sides.back then
        success, err = robot.back()
        if not success then 
            return success, err
        end
        _move(toFacing(sides.back))
    elseif side == sides.up then
        success, err = robot.up()
        if not success then 
            return success, err
        end
        _move(toFacing(sides.up))
    elseif side == sides.down then
        success, err = robot.down()
        if not success then 
            return success, err
        end
        _move(toFacing(sides.down))
    elseif side == sides.left then
        success, err = turnSide(sides.left)
        if not success then 
            return success, err
        end
        success, err = robot.forward()
        _move(toFacing(sides.forward))
        if not success then 
            return success, err
        end
        if preserve_facing then
            success, err = turnSide(sides.right)
            if not success then 
                return success, err
            end
        end
    elseif side == sides.right then
        success, err = turnSide(sides.right)
        if not success then 
            return success, err
        end
        success, err = robot.forward()
        _move(toFacing(sides.forward))
        if not success then 
            return success, err
        end
        if preserve_facing then
            success, err = turnSide(sides.left)
            if not success then 
                return success, err
            end
        end
    else
        -- illegal argument
        return false, "illegal argument"
    end

    return true, nil
end

function move(facing, preserve_facing)
    return moveSide(toSide(facing), preserve_facing)
end

function wrapRepeat(cb, waittime)
    local waittime = waittime or 0.5
    return function(...)
        local success, err
        repeat
            success, err = cb(...)
            if not success then
                os.sleep(waittime)
            end
        until success
    end
end

return {
    getPosition=getPosition,
    getFacing=getFacing,
    findWaypoints=findWaypoints,

    move=move,
    moveSide=moveSide,
    turn=turn,
    turnSide=turnSide,

    toSide=toSide,
    toFacing=toFacing,
    toNormal=toNormal,

    wrapRepeat=wrapRepeat,

    _move=_move,
    _turn=_turn,
    setState=setState
}