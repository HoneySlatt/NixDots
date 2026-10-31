local common = require("./common.luau")
local generation, query, loading, errorText, selected = 0, "", false, nil, 1
local COLUMNS = 4
local data = { items = {}, page = 0, pages = 1, total = 0 }

local render, load
load = function(page, refresh)
    generation += 1
    local request = generation
    loading, errorText = true, nil
    render()
    common.library({ "list", "games", query, page, refresh and "refresh" or "cached" }, function(result, err)
        if request ~= generation then return end
        loading, errorText = false, err
        if result then data = result; selected = 1 end
        render()
        if result then common.covers(data.items, function() return request == generation end, render) end
    end)
end

local function launch(game)
    common.action({ "play", "games", game.id }, function() panel.close() end)
end

render = function()
    local rows = {}
    for first = 1, #data.items, COLUMNS do
        local cards = {}
        for index = first, math.min(first + COLUMNS - 1, #data.items) do
            local game = data.items[index]
            local art = game.cover and ui.image({ path = game.cover, height = 180, fit = "cover", radius = 12 })
                or ui.box({ height = 180, fill = "surface_container", radius = 12 }, { ui.glyph({ name = "device-gamepad", size = 48 }) })
            table.insert(cards, ui.column({ key = game.id, flexGrow = 1, width = 200, gap = 8, padding = 10,
                fill = "surface_container", radius = 16, border = "primary", borderWidth = index == selected and 2 or 0,
                onClick = function() launch(game) end }, { art, ui.label({ text = game.title, maxLines = 2, fontSize = 14 }),
                    ui.label({ text = game.subtitle, color = "on_surface_variant", fontSize = 12 }) }))
        end
        table.insert(rows, ui.row({ gap = 12 }, cards))
    end
    panel.render(ui.column({ gap = 14, padding = 20 }, {
        common.header("Games", "Installed Slatty and Steam games"),
        ui.input({ key = "search", placeholder = "Search games…", focus = true, onChange = function(text) query = text; load(0, false) end }),
        ui.label({ text = loading and "Loading…" or errorText or (data.total == 0 and "No installed games." or ""), color = "on_surface_variant" }),
        ui.scroll({ flexGrow = 1, gap = 12, revealKey = data.items[selected] and data.items[selected].id or nil }, rows),
        common.pager(data, function(page) load(page, false) end),
    }))
end

local moves = { Left = -1, Right = 1, Up = -COLUMNS, Down = COLUMNS }

function onKey(chord, pressed)
    if not pressed then return end
    if chord == "Return" then
        if data.items[selected] then launch(data.items[selected]) end
    else
        selected = common.step(selected, moves[chord], data, function(page) load(page, false) end)
        render()
    end
end

function onOpen() query = ""; data.items = {}; load(0, true) end
function onClose() generation += 1 end
