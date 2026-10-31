local pending = false
noctalia.setUpdateInterval(5000)
barWidget.setGlyph("shield")

function update()
    if pending then return end
    pending = true
    noctalia.runAsync({ "nym-vpnc", "status" }, function(result)
        pending = false
        local connected = result.exitCode == 0 and string.find(result.stdout, "State: Connected", 1, true) ~= nil
        noctalia.state.set("vpn-connected", connected)
        barWidget.setText(connected and "VPN" or "")
        barWidget.setTooltip(connected and "NymVPN connected" or "NymVPN disconnected · Click to choose countries")
    end)
end
