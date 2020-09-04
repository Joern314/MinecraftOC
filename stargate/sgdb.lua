-- command line utility to manipulate the stargate database

local io = require("io")
local fs = require("filesystem")
local shell = require("shell")
local term = require("term")
local component = require("component")
local serialization = require("serialization")
local uuid = require("uuid")
local text = require("text")

local args, ops = shell.parse(...)

if #args == 0 or ops['h']==true then
    io.write('Usage:\n')
    io.write(' sgdb list\n')
    io.write(' sgdb insert <address> <name> [<description>]\n')
    io.write('options: --db="db-file"\n')
    return 1
end

local database_file = ops['db'] or os.getenv('STARGATE_DB') or "/home/.stargate.db"
database_file = shell.resolve(database_file)
if not database_file or not fs.exists(database_file) or fs.isDirectory(database_file) then
    io.write("error: could not open database file.")
    return 1
end

local function readDB()
    local file = assert(io.open(database_file, "r"))
    local database = serialization.unserialize(file:read("*all"))
    file:close()
    return database
end
local function writeDB(database)
    local file = assert(io.open(database_file, "w"))
    file:write(serialization.serialize(database))
    file:close()
end

local function pretty_print_db()
    local db = readDB()

    local path = "/tmp/stargate_db_pretty.txt"
    local file = assert(io.open(path, "w"))

    local display_rows = {}
    local max_len = {addr=11, name=0, desc=0}
    local addr, row
    for addr,row in pairs(db) do
        table.insert(display_rows, {
            addr=addr,
            name=row.name,
            desc=row.description
        })
        max_len.addr = math.max(max_len.addr, string.len(addr))
        max_len.name = math.max(max_len.name, string.len(row.name))
        max_len.desc = math.max(max_len.desc, string.len(row.description or ""))
    end
    table.sort(display_rows, function(a,b)
        return a.name < b.name
    end)

    local term_w, term_h = term.gpu().getViewport()

    file:write("-- ADDRESS NAME DESCRIPTION\n")
    local i,row
    for i,row in ipairs(db) do
        local frag=string.format("%2d %11s ", i, row.addr)
        frag = frag .. text.padRight(row.name, max_len.name)
        local rem = term_w - string.len(frag)
        if row.desc == nil then
            frag = frag .. "\n"
        elseif string.len(row.desc) <= rem then
            frag = frag .. " " .. row.desc .. "\n"
        else
            frag = frag .. "\n   " .. row.desc .. "\n"
        end
        file:write(frag)
    end

    file:close()
    return path
end


if args[1] == "list" then
    local path = pretty_print_db()
    os.execute(os.getenv("PAGER") .. " " .. path)
    return 1
elseif args[1] == "insert" and #args>=3 then
    local addr, name, desc
    addr = args[2]
    name = args[3]
    if #args==4 then
        desc=args[4]
    else
        desc=nil
    end

    local db = readDB()
    if db[addr] ~= nil then
        io.write('Error: Gate entry already exists!')
        return 1
    end
    db[addr] = {
        name = name,
        desc = desc
    }

    io.write(string.format("inserted: %s %s %s", addr, name, desc or ""))
    writeDB(db)
    return 1
else
    io.write("error")
    os.exit()
end