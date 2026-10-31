local common = require("./common.luau")
local themes = { { "carbonfox", "Carbonfox" }, { "everforest", "Everforest" },
    { "rosepine", "Rosé Pine" }, { "pastelglow", "Pastel Glow" },
    { "gruvbox", "Gruvbox Dark" }, { "gruvbox-light", "Gruvbox Light" } }

function onOpen()
    local current = noctalia.getSetting("theme.custom_palette")
    local rows = { common.header("Themes", "Desktop and application colors") }
    for _, theme in ipairs(themes) do
        local key, name = theme[1], theme[2]
        table.insert(rows, ui.button({ text = name, glyph = "palette", selected = key == current,
            contentAlign = "start", onClick = function()
                noctalia.runAsync({ "bash", noctalia.expandPath("~/.config/amane/themes/switch-theme.sh"), key }, function(result)
                    if result.exitCode ~= 0 then noctalia.notifyError("Theme", "The theme could not be fully applied.") end
                end)
                panel.close()
            end }))
    end
    panel.render(ui.column({ gap = 12, padding = 20 }, rows))
end
