import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "dockerBar"

    StyledText {
        width: parent.width
        text: "DockerBar Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Monitor Docker container health across local and remote hosts."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "dockerBarPath"
        label: "DockerBar Path"
        description: "Absolute path to the dockerbar-linux repo"
        placeholder: "/home/gabriel/Projects/Personal/dockerbar-linux"
        defaultValue: "/home/gabriel/Projects/Personal/dockerbar-linux"
    }

    SelectionSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "How often to fetch container status"
        options: [
            {label: "15 seconds", value: "15"},
            {label: "30 seconds", value: "30"},
            {label: "1 minute", value: "60"},
            {label: "5 minutes", value: "300"}
        ]
        defaultValue: "30"
    }

    ToggleSetting {
        settingKey: "showRemote"
        label: "Show Remote Host"
        description: "Fetch container status from the remote SSH host"
        defaultValue: true
    }

    StringSetting {
        settingKey: "remoteHost"
        label: "Remote Host"
        description: "SSH connection string for the remote Docker host"
        placeholder: "root@51.81.202.134"
        defaultValue: "root@51.81.202.134"
    }

    StringSetting {
        settingKey: "sshKey"
        label: "SSH Key Path"
        description: "Path to the SSH private key for the remote host"
        placeholder: "~/.ssh/kaia_ovh"
        defaultValue: "~/.ssh/kaia_ovh"
    }
}
