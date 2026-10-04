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
    property var savedConnections: []

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
                if (!found) { root.netType = "offline"; root.connectionName = ""; root.signalStrength = 0; }
            }
        }
    }

    readonly property var _signalProc: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let a = this.text.trim().split("\n").find(l => l.startsWith("*:"));
                if (a) { let v = parseInt(a.split(":")[1]); if (!isNaN(v)) root.signalStrength = v; }
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

    readonly property var _vpnIfaceProc: Process {
        command: ["sh", "-c", "/run/current-system/sw/bin/nym-vpnc status 2>/dev/null | grep -q '^State: Connected' && printf true || printf false"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: { root.vpnConnected = this.text.trim() === "true"; }
        }
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
                        saved.push(parts.slice(0, -1).join(":"));
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

    readonly property var _pollTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._netProc.running = true;
            root._wifiRadioProc.running = true;
        }
    }

    function _parseNetworks(text) {
        let lines = text.trim().split("\n");
        let networks = {};
        for (let i = 0; i < lines.length; i++) {
            let parts = lines[i].split(":");
            if (parts.length < 4) continue;
            let inUse = parts[0] === "*";
            let signal = parseInt(parts[1]);
            let security = parts[2];
            let ssid = parts.slice(3).join(":").replace(/\\:/g, ":");
            if (!ssid || ssid === "--") continue;
            let connected = inUse || ssid === root.connectionName;
            if (!networks[ssid]) {
                networks[ssid] = { ssid: ssid, signal: signal, security: security, connected: connected };
            } else {
                networks[ssid].connected = networks[ssid].connected || connected;
                if (signal > networks[ssid].signal) {
                    networks[ssid].signal = signal;
                    networks[ssid].security = security;
                }
            }
        }
        return Object.values(networks).sort((a, b) => b.signal - a.signal).slice(0, 8);
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
            onStreamFinished: root._refreshTimer.start()
        }
    }

    readonly property var _refreshTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: {
            root._netProc.running = true;
            root.scan();
        }
    }

    function scan() {
        root._wifiRadioProc.running = true;
        if (!root.wifiEnabled) { root.scanning = false; root.availableNetworks = []; return; }
        root.scanning = true;
        root._cachedScanProc.running = true;
    }

    function toggleWifi() {
        root._wifiToggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        root._wifiToggleProc.running = true;
    }

    function connectToNetwork(ssid, password, save) {
        root.connecting = true;
        let base = save ? ["nmcli", "dev", "wifi", "connect", ssid]
                        : ["nmcli", "--temporary", "dev", "wifi", "connect", ssid];
        root._connectProc.command = password ? base.concat(["password", password]) : base;
        root._connectProc.running = true;
    }

    function disconnectNetwork() {
        if (root.connectionName) {
            root._disconnectProc.command = ["nmcli", "con", "down", root.connectionName];
            root._disconnectProc.running = true;
        }
    }

    function refreshSavedConnections() {
        root._savedConnsProc.running = true;
    }
}
