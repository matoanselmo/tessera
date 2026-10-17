import QtQuick
import qs
import qs.services

// Adapter state, plus how many devices are connected; opens the bluetooth panel.
BarWidget {
    id: root

    signal toggleRequested

    visible: BluetoothState.adapter !== null
    icon: BluetoothState.icon
    label: BluetoothState.connected.length > 0 ? `${BluetoothState.connected.length}` : ""
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    tooltip: BluetoothState.summary
    onClicked: root.toggleRequested()
}
