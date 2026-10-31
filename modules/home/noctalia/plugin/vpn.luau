local common = require("./common.luau")
local generation, query, entry, exitCountry, errorText = 0, "", nil, nil, nil
local state = { countries = {}, state = "Loading…" }
local render

local function action(args)
    noctalia.runAsync(args, function(result)
        if result.exitCode ~= 0 then noctalia.notifyError("NymVPN", "The operation failed. Check the VPN connection.") end
    end)
    panel.close()
end

render = function()
    local rows = {}
    for _, country in ipairs(state.countries or {}) do
        if string.find(string.lower(country.name .. " " .. country.code), string.lower(query), 1, true) then
            table.insert(rows, ui.button({ key = country.code, text = country.name .. " (" .. country.code .. ")  ·  " .. tostring(country.servers),
                contentAlign = "start", selected = country.code == (entry and exitCountry or state.entry), onClick = function()
                    if not entry then entry = country.code; query = ""; render()
                    else action({ "toggle-nym", "set", entry, country.code }) end
                end }))
        end
    end
    panel.render(ui.column({ padding = 20, gap = 12 }, {
        common.header("NymVPN", entry and ("Choose exit country · Entry: " .. entry) or "Choose entry country"),
        ui.label({ text = errorText or ((state.state or "Unknown") .. "  ·  " .. (state.entry or "Random") .. " → " .. (state.exit or "Random")), color = "on_surface_variant" }),
        ui.input({ key = entry and "exit-search" or "entry-search", placeholder = "Search countries…", focus = true,
            onChange = function(text) query = text; render() end }),
        ui.scroll({ gap = 6, flexGrow = 1 }, rows),
        ui.row({ gap = 8 }, {
            ui.button({ text = "Back", enabled = entry ~= nil, onClick = function() entry = nil; query = ""; render() end }),
            ui.spacer({ flexGrow = 1 }),
            ui.button({ text = "Disconnect", variant = "destructive", onClick = function() action({ "toggle-nym", "off" }) end }),
        }),
    }))
end

function onOpen()
    generation += 1
    local request = generation
    query, entry, errorText = "", nil, nil
    state = { countries = {}, state = "Loading…" }
    render()
    common.run({ "nym-countries" }, function(data, err)
        if generation ~= request then return end
        errorText = err
        if data then state = data; exitCountry = data.exit end
        render()
    end)
end
function onClose() generation += 1 end
