pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string netType: "offline"
    property int signalStrength: 0
    property string connectionName: ""
    property bool vpnConnected: false
    property bool wifiEnabled: true

    property var availableNetworks: []
    property bool scanning: false
    property bool connecting: false

    // SSIDs with a saved NM connection profile
    property var savedConnections: []

    // ── Current connection polling ──

    readonly property var _netProc: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let found = false;

                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 3 && parts[1] === "connected") {
                        if (!found && parts[0] === "wifi") {
                            root.netType = "wifi";
                            root.connectionName = parts[2];
                            found = true;
                            root._signalProc.running = true;
                        } else if (!found && parts[0] === "ethernet") {
                            root.netType = "ethernet";
                            root.connectionName = parts[2];
                            found = true;
                        }
                    }
                }

                root._vpnIfaceProc.running = true;

                if (!found) {
                    root.netType = "offline";
                    root.connectionName = "";
                    root.signalStrength = 0;
                }
            }
        }
    }

    readonly property var _signalProc: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let active = lines.find(l => l.startsWith("*:"));
                if (active) {
                    let val = parseInt(active.split(":")[1]);
                    if (!isNaN(val)) root.signalStrength = val;
                }
            }
        }
    }

    readonly property var _wifiRadioProc: Process {
        command: ["nmcli", "radio", "wifi"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
    }

    readonly property var _wifiToggleProc: Process {
        command: ["true"]
        running: false
        onExited: {
            root._wifiRadioProc.running = true;
            root._refreshTimer.start();
        }
    }

    // Treat VPN as active only when the NymVPN tunnel is connected.
    readonly property var _vpnIfaceProc: Process {
        command: ["sh", "-c", "/run/current-system/sw/bin/nym-vpnc status 2>/dev/null | sed -n 's/^State: \\([A-Za-z]*\\).*/\\1/p'"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const state = this.text.trim();
                root.vpnConnected = state === "Connected";
                // Connecting, Disconnecting...: follow the transition until it settles
                if (state.endsWith("ing")) root._vpnRecheckTimer.start();
            }
        }
    }

    readonly property var _vpnRecheckTimer: Timer {
        interval: 1000
        onTriggered: root._vpnIfaceProc.running = true
    }

    readonly property var _savedConnsProc: Process {
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let saved = [];
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 2 && parts[parts.length - 1] === "802-11-wireless") {
                        let name = parts.slice(0, -1).join(":");
                        saved.push(name);
                    }
                }
                root.savedConnections = saved;
            }
        }
    }

    Component.onCompleted: {
        root._savedConnsProc.running = true;
        root.scan();
    }

    function _refreshStatus() {
        root._netProc.running = true;
        root._wifiRadioProc.running = true;
    }

    // One line per device, connectivity or VPN tunnel change (radio toggles change the device state)
    readonly property var _monitorProc: Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: root._changeTimer.restart()
        }
        onRunningChanged: if (!running) root._monitorRestartTimer.start()
    }

    readonly property var _monitorRestartTimer: Timer {
        interval: 1000
        onTriggered: root._monitorProc.running = true
    }

    // Coalesce bursts of events into a single refresh
    readonly property var _changeTimer: Timer {
        interval: 200
        onTriggered: root._refreshStatus()
    }

    // Signal strength and the Nym connection state emit no events
    readonly property var _pollTimer: Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._refreshStatus()
    }

    // ── Network scanning ──

    function _parseNetworks(text) {
        let lines = text.trim().split("\n");
        let networks = {};

        for (let i = 0; i < lines.length; i++) {
            let parts = lines[i].split(":");
            if (parts.length < 4) continue;

            let inUse = parts[0] === "*";
            let signal = parseInt(parts[1]);
            let security = parts[2];
            // SSID is last field, rejoin in case it contains colons
            let ssid = parts.slice(3).join(":").replace(/\\:/g, ":");

            if (!ssid || ssid === "--") continue;

            let connected = inUse || ssid === root.connectionName;

            // Deduplicate by SSID while preserving active state from weaker duplicates.
            if (!networks[ssid]) {
                networks[ssid] = {
                    ssid: ssid,
                    signal: signal,
                    security: security,
                    connected: connected
                };
            } else {
                networks[ssid].connected = networks[ssid].connected || connected;
                if (signal > networks[ssid].signal) {
                    networks[ssid].signal = signal;
                    networks[ssid].security = security;
                }
            }
        }

        return Object.values(networks)
            .sort((a, b) => b.signal - a.signal)
            .slice(0, 8);
    }

    readonly property var _cachedScanProc: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "no"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.availableNetworks = root._parseNetworks(this.text);
                root._scanProc.running = true;
            }
        }
    }

    readonly property var _scanProc: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "yes"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                root.availableNetworks = root._parseNetworks(this.text);
            }
        }
    }

    // ── Connect / Disconnect ──

    readonly property var _connectProc: Process {
        command: ["true"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false;
                root._refreshTimer.start();
                root._savedConnsProc.running = true;
            }
        }
    }

    readonly property var _disconnectProc: Process {
        command: ["true"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root._refreshTimer.start();
            }
        }
    }

    // Delay refresh to let NetworkManager stabilize
    readonly property var _refreshTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: {
            root._netProc.running = true;
            root.scan();
        }
    }

    // ── Public API ──

    function scan() {
        root._wifiRadioProc.running = true;
        if (!root.wifiEnabled) {
            root.scanning = false;
            root.availableNetworks = [];
            return;
        }
        root.scanning = true;
        root._cachedScanProc.running = true;
    }

    function toggleWifi() {
        root._wifiToggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        root._wifiToggleProc.running = true;
    }

    function connectToNetwork(ssid: string, password: string, save: bool) {
        root.connecting = true;
        let base = save ? ["nmcli", "dev", "wifi", "connect", ssid]
                        : ["nmcli", "--temporary", "dev", "wifi", "connect", ssid];
        root._connectProc.command = password ? base.concat(["password", password]) : base;
        root._connectProc.running = true;
    }

    function refreshSavedConnections() {
        root._savedConnsProc.running = true;
    }

    function disconnectNetwork() {
        if (root.connectionName) {
            root._disconnectProc.command = ["nmcli", "con", "down", root.connectionName];
            root._disconnectProc.running = true;
        }
    }
}
