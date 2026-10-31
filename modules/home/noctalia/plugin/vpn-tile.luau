local function render(connected)
    shortcut.setLabel("NymVPN")
    shortcut.setIcon("shield")
    shortcut.setActive(connected == true)
end

render(noctalia.state.get("vpn-connected"))
noctalia.state.watch("vpn-connected", render)

function onClick()
    noctalia.runAsync({ "toggle-nym" }, function(result)
        if result.exitCode ~= 0 then noctalia.notifyError("NymVPN", "The operation failed. Check the VPN connection.") end
    end)
end

function onRightClick() noctalia.runAsync({ "noctalia", "msg", "panel-toggle", "local/desktop:vpn" }) end
