local M = {}

function M.run(args, callback)
    local accepted = noctalia.runAsync(args, function(result)
        local data = noctalia.json.decode(result.stdout)
        if result.exitCode ~= 0 or not data or result.stdoutTruncated then
            callback(nil, (data and data.error) or "The application is unavailable.")
        else
            callback(data, nil)
        end
    end)
    if not accepted then callback(nil, "Could not start the helper.") end
end

function M.library(args, callback)
    local argv = { "noctalia-desktop-library" }
    for _, arg in ipairs(args) do table.insert(argv, tostring(arg)) end
    M.run(argv, callback)
end

function M.action(args, done)
    M.library(args, function(_, err)
        if err then noctalia.notifyError("Desktop", err)
        elseif done then done() end
    end)
end

function M.header(title, subtitle)
    return ui.row({ gap = 12, align = "center" }, {
        ui.column({ flexGrow = 1, gap = 3 }, {
            ui.label({ text = title, fontSize = 24, fontWeight = "bold" }),
            ui.label({ text = subtitle or "", color = "on_surface_variant", fontSize = 13 }),
        }),
        ui.button({ glyph = "x", variant = "ghost", tooltip = "Close", onClick = function() panel.close() end }),
    })
end

function M.pager(data, change)
    return ui.row({ gap = 12, align = "center", justify = "center" }, {
        ui.button({ glyph = "chevron-left", enabled = data.page > 0, onClick = function() change(data.page - 1) end }),
        ui.label({ text = tostring(data.page + 1) .. " / " .. tostring(data.pages) .. "  ·  " .. tostring(data.total) }),
        ui.button({ glyph = "chevron-right", enabled = data.page + 1 < data.pages, onClick = function() change(data.page + 1) end }),
    })
end

-- Moves the selection by delta; crossing an edge turns the page, whose load resets it.
function M.step(index, delta, data, change)
    local target = index + delta
    if target < 1 and data.page > 0 then
        change(data.page - 1)
    elseif target > #data.items and data.page + 1 < data.pages then
        change(data.page + 1)
    else
        index = math.clamp(target, 1, math.max(#data.items, 1))
    end
    return index
end

-- Only fetch the covers visible on this page, with at most three subprocesses.
-- Stale callbacks after a search or panel close cannot replace the new page.
function M.covers(items, valid, redraw)
    local index = 0
    local function nextCover()
        if not valid() then return end
        index += 1
        local item = items[index]
        if not item then return end
        if not item.art or item.art == "" then nextCover(); return end
        M.library({ "art", noctalia.json.encode(item.art) }, function(data)
            if not valid() then return end
            if data and data.path ~= "" then item.cover = data.path; redraw() end
            nextCover()
        end)
    end
    for _ = 1, 3 do nextCover() end
end

return M
