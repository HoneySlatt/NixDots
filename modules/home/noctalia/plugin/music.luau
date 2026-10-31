local common = require("./common.luau")
local sections = { { "playlists", "Playlists" }, { "albums", "Albums" }, { "artists", "Artists" },
    { "songs", "Songs" }, { "favorites", "Favorites" } }
local generation, section, query, opened, loading = 0, "playlists", "", false, false
local data = { items = {}, page = 0, pages = 1, total = 0 }
local player, errorText, playerPending, selected = {}, nil, false, 1
local render, load

load = function(page, refresh)
    generation += 1
    local request = generation
    loading, errorText = true, nil
    render()
    common.library({ "list", section, query, page, refresh and "refresh" or "cached" }, function(result, err)
        if request ~= generation or not opened then return end
        loading, errorText = false, err
        if result then data = result; selected = 1 end
        render()
        if result then common.covers(data.items, function() return opened and request == generation end, render) end
    end)
end

local function play(item)
    common.action({ "play", section, item.id, query })
end

render = function()
    local tabs, rows = {}, {}
    for _, tab in ipairs(sections) do
        local id = tab[1]
        table.insert(tabs, ui.button({ text = tab[2], selected = section == id, controlSize = "sm", onClick = function()
            section = id; data.items = {}; load(0, false)
        end }))
    end
    for index, item in ipairs(data.items) do
        local art = item.cover and ui.image({ path = item.cover, width = 50, height = 50, radius = 8, fit = "cover" })
            or ui.glyph({ name = "music", size = 32, width = 50 })
        table.insert(rows, ui.row({ key = item.id, gap = 12, padding = 8, align = "center", radius = 12,
            fill = "surface_container", border = "primary", borderWidth = index == selected and 2 or 0,
            onClick = function() play(item) end }, {
            art, ui.column({ gap = 3, flexGrow = 1 }, {
                ui.label({ text = item.title, maxLines = 1, fontSize = 15 }),
                ui.label({ text = item.subtitle, maxLines = 1, color = "on_surface_variant", fontSize = 12 }),
            }), ui.glyph({ name = "player-play", size = 20 }),
        }))
    end
    local track = player.row or {}
    local playing = player.phase == "PHASE_PLAYING"
    local shuffled = player.queue and player.queue.shuffle or false
    local position = player.position or {}
    local elapsed = tonumber(position.ms) or 0
    if position.playing then elapsed += math.max(0, (tonumber(player.nowMs) or 0) - (tonumber(position.atMs) or 0)) end
    local duration = tonumber(track.durationMs) or 0
    local controls = ui.column({ gap = 8, padding = 12, fill = "surface_container", radius = 16 }, {
        ui.label({ text = track.title or "Kopuz", fontWeight = "bold", maxLines = 1 }),
        ui.label({ text = track.artist or "Open Kopuz to browse and play your library.", color = "on_surface_variant", maxLines = 1 }),
        ui.progress({ progress = duration > 0 and math.clamp(elapsed / duration, 0, 1) or 0, height = 4 }),
        ui.row({ gap = 8, align = "center" }, {
            ui.button({ glyph = "arrows-shuffle", selected = shuffled, tooltip = "Shuffle", onClick = function() common.action({ "shuffle", tostring(not shuffled) }) end }),
            ui.button({ glyph = "player-skip-back", tooltip = "Previous", onClick = function() common.action({ "control", "previous" }) end }),
            ui.button({ glyph = playing and "player-pause" or "player-play", variant = "primary", tooltip = "Play / Pause", onClick = function() common.action({ "control", "toggle" }) end }),
            ui.button({ glyph = "player-skip-forward", tooltip = "Next", onClick = function() common.action({ "control", "next" }) end }),
            ui.button({ glyph = "heart", selected = player.favorite == true, enabled = track.key ~= nil, tooltip = "Favorite", onClick = function()
                if track.key then common.action({ "favorite", track.key, tostring(not player.favorite) }, function() if section == "favorites" then load(data.page, true) end end) end
            end }),
            ui.slider({ key = "volume", min = 0, max = 1, step = 0.01, value = player.volume or 0, flexGrow = 1,
                onDragEnd = function(value) common.action({ "volume", value }) end }),
            ui.button({ glyph = "external-link", tooltip = "Open Kopuz", onClick = function() noctalia.runAsync({ "kopuz" }) end }),
        }),
    })
    panel.render(ui.column({ gap = 12, padding = 20 }, {
        common.header("Music", "Kopuz library"), ui.row({ gap = 6 }, tabs),
        ui.input({ key = "search", placeholder = "Search your library…", focus = true, onChange = function(text) query = text; load(0, false) end }),
        ui.label({ text = loading and "Loading…" or errorText or (data.total == 0 and "Nothing here yet." or ""), color = "on_surface_variant" }),
        ui.scroll({ flexGrow = 1, gap = 6, revealKey = data.items[selected] and data.items[selected].id or nil }, rows),
        common.pager(data, function(page) load(page, false) end), controls,
    }))
end

function onKey(chord, pressed)
    if not pressed then return end
    if chord == "Return" then
        if data.items[selected] then play(data.items[selected]) end
    else
        selected = common.step(selected, chord == "Up" and -1 or 1, data, function(page) load(page, false) end)
        render()
    end
end

function update()
    if not opened or playerPending then return end
    playerPending = true
    common.library({ "player" }, function(result)
        playerPending = false
        if not opened then return end
        player = result or {}
        render()
    end)
end

function onOpen()
    opened, query, section = true, "", "playlists"
    data.items = {}
    panel.setWantsSecondTicks(true)
    load(0, true)
    update()
end
function onClose() opened = false; generation += 1 end
