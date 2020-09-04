local nav = require("nav")

function freeform()
    return function(x1,y1,z1, x2,y2,z2)
        if y1 < y2 then
            return nav.posy
        elseif y1 > y2 then
            return nav.negy
        elseif x1 < x2 then
            return nav.posx
        elseif x1 > x2 then
            return nav.negx
        elseif z1 < z2 then
            return nav.posz
        elseif z1 > z2 then
            return nav.negz
        else
            return true
        end
    end
end

--- simple pathfinding algorithm
-- travel in the plane y=YT is freely possible
-- travel to/from the plane y=YT while keeping xz fixed is possible wherever needed
function planeY(YT)
    local YT = YT
    local ff = freeform()
    return function(x1,y1,z1, x2,y2,z2)
        if x1 ~= x2 or z1 ~=z2 then
            if y1 > YT then -- move to plane
                return nav.negy
            elseif y1 < YT then -- move to plane
                return nav.posy
            else -- xz navigation
                return ff(x1,YT,z1, x2,YT,z2)
            end
        else -- move to correct y
            return ff(x1,y1,z1, x1,y2,z1)
        end
    end
end

return {
    freeform = freeform,
    planeY = planeY
}

local component = require("component")
local geolyzer = component.geolyzer
 
local offsetx = -3
local offsetz = -5
local offsety = -2
 
local sizex = 6
local sizez = 10
local sizey = 4
 
local map = {}
local scanData = geolyzer.scan(offsetx, offsetz, offsety, sizex, sizez, sizey)
local i = 1
for y = 0, sizey - 1 do
    for z = 0, sizez - 1 do
        for x = 0, sizex - 1 do
            -- alternatively when thinking in terms of 3-dimensional table: map[offsety + y][offsetz + z][offsetx + x] = scanData[i]
            map[i] = {posx = offsetx + x, posy = offsety + y, posz = offsetz + z, hardness = scanData[i]}
            i = i + 1
        end
    end
end
 
for i = 1, sizex*sizez*sizey do
    print(map[i].posx, map[i].posy, map[i].posz, map[i].hardness)
end