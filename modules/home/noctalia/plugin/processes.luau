local common = require("./common.luau")
local LIMIT = 80
local opened, pending, processes, errorText = false, false, {}, nil
local render

local function parse(stdout)
    local list = {}
    for line in string.gmatch(stdout, "[^\n]+") do
        local pid, name, cpu, memory = string.match(line, "^%s*(%d+)%s+(.-)%s+([%d.]+)%s+([%d.]+)%s*$")
        if pid then table.insert(list, { pid = pid, name = name, cpu = cpu, memory = memory }) end
        if #list == LIMIT then break end
    end
    return list
end

local function refresh()
    if pending or not opened then return end
    pending = true
    local accepted = noctalia.runAsync({ "ps", "-eo", "pid=,comm=,pcpu=,pmem=", "--sort=-pcpu" }, function(result)
        pending = false
        if not opened then return end
        errorText = result.exitCode ~= 0 and "Could not read the processes." or nil
        if result.exitCode == 0 then processes = parse(result.stdout) end
        render()
    end)
    if not accepted then pending = false end
end

local function terminate(process)
    noctalia.runAsync({ "kill", process.pid }, function(result)
        if result.exitCode ~= 0 then noctalia.notifyError("Processes", "Could not stop " .. process.name .. ".") end
        refresh()
    end)
end

local function cell(text)
    return ui.row({ minWidth = 64, justify = "end" }, { ui.label({ text = text, color = "on_surface_variant" }) })
end

render = function()
    local rows = {}
    for _, process in ipairs(processes) do
        table.insert(rows, ui.row({ key = process.pid, gap = 12, align = "center" }, {
            ui.row({ flexGrow = 1 }, { ui.label({ text = process.name, maxLines = 1 }) }),
            cell(process.cpu .. "%"),
            cell(process.memory .. "%"),
            ui.button({ glyph = "x", variant = "ghost", tooltip = "Stop " .. process.name, onClick = function() terminate(process) end }),
        }))
    end
    panel.render(ui.column({ padding = 20, gap = 12 }, {
        common.header("Processes", errorText or "Busiest first"),
        ui.row({ gap = 12 }, {
            ui.row({ flexGrow = 1 }, { ui.label({ text = "Name", color = "on_surface_variant" }) }),
            cell("CPU"),
            cell("RAM"),
            ui.box({ width = 32, height = 1 }),
        }),
        ui.scroll({ gap = 4, flexGrow = 1 }, rows),
    }))
end

noctalia.setUpdateInterval(3000)
function update() refresh() end

function onOpen()
    opened = true
    render()
    refresh()
end
function onClose() opened = false end
