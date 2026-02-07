import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "dockerbar"

    property string dockerBarPath: pluginData.dockerBarPath || "/home/gabriel/Projects/Personal/dockerbar-linux"
    property int refreshInterval: parseInt(pluginData.refreshInterval) || 30
    property bool showRemote: pluginData.showRemote !== false
    property string remoteHost: pluginData.remoteHost || "root@51.81.202.134"
    property string sshKey: pluginData.sshKey || "~/.ssh/kaia_ovh"

    property var hosts: []
    property bool loading: true

    property int totalRunning: {
        var n = 0
        for (var i = 0; i < hosts.length; i++) n += hosts[i].running
        return n
    }
    property int totalContainers: {
        var n = 0
        for (var i = 0; i < hosts.length; i++) n += hosts[i].total
        return n
    }
    property int unhealthyCount: {
        var n = 0
        for (var i = 0; i < hosts.length; i++) {
            if (hosts[i].error) { n++; continue }
            for (var j = 0; j < hosts[i].containers.length; j++) {
                var h = hosts[i].containers[j].health
                if (h === "unhealthy" || h === "stopped") n++
            }
        }
        return n
    }
    property bool allHealthy: unhealthyCount === 0 && hosts.length > 0

    function healthColor(health) {
        if (health === "healthy") return Theme.primary
        if (health === "none") return Theme.surfaceVariantText
        if (health === "unhealthy") return "#E5A100"
        return Theme.error
    }

    function projectHealthColor(proj) {
        if (!proj.allHealthy) return "#E5A100"
        if (proj.running < proj.total) return Theme.error
        return Theme.primary
    }

    Timer {
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchContainers()
    }

    function fetchContainers() {
        var args = ["bun", "run", root.dockerBarPath + "/src/index.ts"]
        if (root.showRemote) {
            args.push("--all")
            args.push("--host")
            args.push(root.remoteHost)
            args.push("--key")
            args.push(root.sshKey)
        } else {
            args.push("--local")
        }
        Proc.runCommand(
            "dockerBar.fetch",
            args,
            (stdout, exitCode) => {
                if (exitCode === 0 && stdout.trim()) {
                    try {
                        var data = JSON.parse(stdout)
                        root.hosts = data.hosts || []
                        root.loading = false
                    } catch (e) {
                        console.error("DockerBar: Failed to parse JSON:", e)
                    }
                }
            },
            500
        )
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "dns"
                color: root.loading ? Theme.surfaceVariantText : (root.allHealthy ? Theme.primary : Theme.error)
                size: Theme.fontSizeLarge
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.loading ? "..." : (root.totalRunning + "/" + root.totalContainers)
                color: root.loading ? Theme.surfaceVariantText : (root.allHealthy ? Theme.primary : Theme.error)
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
            }

            // Unhealthy badge
            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                width: uhText.width + 8
                height: uhText.height + 2
                radius: height / 2
                color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
                visible: !root.loading && root.unhealthyCount > 0

                StyledText {
                    id: uhText
                    anchors.centerIn: parent
                    text: root.unhealthyCount.toString()
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.weight: Font.Bold
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "dns"
                color: root.loading ? Theme.surfaceVariantText : (root.allHealthy ? Theme.primary : Theme.error)
                size: Theme.fontSizeMedium
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.loading ? ".." : (root.totalRunning + "/" + root.totalContainers)
                color: root.loading ? Theme.surfaceVariantText : (root.allHealthy ? Theme.primary : Theme.error)
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: ""
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - Theme.spacingL

                Flickable {
                    anchors.fill: parent
                    contentHeight: mainCol.implicitHeight
                    clip: true

                    Column {
                        id: mainCol
                        width: parent.width
                        spacing: Theme.spacingM

                        Repeater {
                            model: root.hosts

                            Column {
                                width: mainCol.width
                                spacing: Theme.spacingS

                                property var hostData: modelData

                                // Host header row
                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: hostData.name === "Local" ? "computer" : "cloud"
                                        color: Theme.surfaceText
                                        size: Theme.fontSizeLarge
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter

                                        StyledText {
                                            text: hostData.name
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Bold
                                        }

                                        StyledText {
                                            text: hostData.error
                                                ? "Connection error"
                                                : (hostData.running + " running / " + hostData.total + " total")
                                            color: hostData.error ? Theme.error : Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall - 2
                                        }
                                    }
                                }

                                // Error detail
                                StyledRect {
                                    width: parent.width
                                    height: errText.implicitHeight + Theme.spacingS
                                    radius: Theme.cornerRadius
                                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08)
                                    visible: !!hostData.error

                                    StyledText {
                                        id: errText
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingXS
                                        text: hostData.error || ""
                                        color: Theme.error
                                        font.pixelSize: Theme.fontSizeSmall - 2
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                    }
                                }

                                // Projects grouped
                                Repeater {
                                    model: hostData.projects

                                    Column {
                                        width: mainCol.width
                                        spacing: 2

                                        property var proj: modelData

                                        // Project header
                                        Row {
                                            width: parent.width
                                            spacing: Theme.spacingXS
                                            height: 24

                                            Rectangle {
                                                width: 3
                                                height: 16
                                                radius: 1.5
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: root.projectHealthColor(proj)
                                            }

                                            StyledText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: proj.name
                                                color: Theme.surfaceText
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                            }

                                            StyledText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: proj.running + "/" + proj.total
                                                color: Theme.surfaceVariantText
                                                font.pixelSize: Theme.fontSizeSmall - 2
                                            }
                                        }

                                        // Services in this project
                                        Repeater {
                                            model: proj.containers

                                            Item {
                                                width: mainCol.width
                                                height: 28

                                                StyledRect {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    radius: Theme.cornerRadius
                                                    color: modelData.health === "stopped" || modelData.health === "unhealthy"
                                                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.06)
                                                        : "transparent"

                                                    Row {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: Theme.spacingXS
                                                        anchors.rightMargin: Theme.spacingXS
                                                        spacing: Theme.spacingS

                                                        // Health dot
                                                        Rectangle {
                                                            width: 6
                                                            height: 6
                                                            radius: 3
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: root.healthColor(modelData.health)
                                                        }

                                                        // Service name
                                                        StyledText {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            width: parent.width * 0.3
                                                            text: modelData.service
                                                            color: Theme.surfaceText
                                                            font.pixelSize: Theme.fontSizeSmall - 1
                                                            elide: Text.ElideRight
                                                        }

                                                        // Port
                                                        StyledText {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            width: parent.width * 0.2
                                                            text: modelData.ports || ""
                                                            color: Theme.primary
                                                            font.pixelSize: Theme.fontSizeSmall - 2
                                                            font.family: "monospace"
                                                            visible: text !== ""
                                                        }

                                                        // Uptime
                                                        StyledText {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.uptime || ""
                                                            color: Theme.surfaceContainerHighest
                                                            font.pixelSize: Theme.fontSizeSmall - 2
                                                            visible: text !== ""
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Separator between hosts
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Theme.surfaceContainerHighest
                                    visible: index < root.hosts.length - 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 500
}
