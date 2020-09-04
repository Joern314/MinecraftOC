-- library to print tables
local math = require("math")
local text = require("text")
local term = require("term")

function pretty_print_row(columns, row, max, options, linewidth, tab)
    local j,c 
    local output = ""
    local linex = 0
    for j,c in ipairs(columns) do
        local r = row[c] or ""
        if linex + max[c] <= linewidth then --column still fits
            output = output .. text.padRight(r, max[c])
            linex = linex+max[c]
        elseif max[c] <= linewidth-tab then --column fits into next line
            output = output .. "\n" .. text.padRight("", tab)
            linex = tab

            output = output .. text.padRight(r, max[c])
            linex = linex+max[c]
        elseif row[c] ~= nil then --column spans several lines and exists
            output = output .. "\n" .. text.padRight("", tab)
            linex = tab

            -- write row to a single line, the PAGER will wrap the words along several lines then
            output = output .. row[c]
            linex = linex+string.len(row[c])

            if j < #columns then --linebreak before next column
                output = output .. "\n"
                linex = 0
            end
        else --empty multiline row can be left out?
            if options[c].optional then
                output = output .. "\n" .. text.padRight("", tab)
                linex = tab
            else --error: row should not contain empty entry
                error("non-optinal row is empty")
            end
        end

        if j < #columns and linex ~= 0 then -- add space before next column
            if linex < linewidth then
                output = output .. " "
                linex = linex+1
            else
                output = output .. "\n"
                linex = 0
            end
        end
    end

    return output
end

function pretty_print(columns, rows, options, linewidth, tab)
    local max = {}
    local i,j,c,row

    local tab = tab or 3
    local linewidth = linewidth or term.gpu().getViewport()

    for j,c in ipairs(columns) do
        max[c] = 0
    end

    for i, row in ipairs(rows) do
        for j, c in ipairs(columns) do
            local l = string.len(row[c])
            if string.find(row[c], "\n") then
                l = linewidth+1
            end
            max[c] = math.max(max[c], l)
        end
    end

    local output = ""
    
    for i, row in ipairs(rows) do
        if i > 0 then
            output = output .. "\n"
        end
        output = output .. pretty_print_row(columns, row, max, linewidth, tab)
    end
    return output
end

return {
    pretty_print = pretty_print,
    pretty_print_row = pretty_print_row
}