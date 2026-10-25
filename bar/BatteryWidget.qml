import QtQuick
import Quickshell.Services.UPower
import qs
import qs.services

// Charge level of the laptop's battery, with a bolt while it charges. Hidden on
// machines without one, so the same shell runs on the desktop unchanged.
// Clicking cycles the power profile through power-profiles-daemon.
BarWidget {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    // UPower reports 0..100; Quickshell hands it over as 0..1.
    readonly property int percent: Math.round(root.device.percentage * 100)
    readonly property bool charging: root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: root.device.state === UPowerDeviceState.FullyCharged
    readonly property bool low: root.device.state === UPowerDeviceState.Discharging && root.percent <= 15

    present: root.device.ready && root.device.isLaptopBattery

    icon: {
        const p = root.percent;
        const level = p >= 90 ? "full" : p >= 60 ? "high" : p >= 35 ? "medium" : p >= 10 ? "low" : "empty";
        return `battery-${level}.svg`;
    }
    badge: root.charging ? "battery-charging.svg" : ""
    label: `${root.percent}%`

    color: root.low ? ShellGlobals.materialColors.error : ShellGlobals.materialColors.tertiarycontainer
    foreground: root.low ? ShellGlobals.materialColors.onerror : ShellGlobals.materialColors.ontertiarycontainer

    // `2 h 05 min`, or `35 min` under an hour. UPower gives seconds, 0 while
    // it is still estimating.
    function duration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        const h = Math.floor(minutes / 60);
        const m = minutes % 60;
        return h > 0 ? `${h} h ${String(m).padStart(2, "0")} min` : `${m} min`;
    }

    // Guarded by `present` so a machine without a battery (and likely without
    // power-profiles-daemon) never touches PowerProfiles.
    tooltip: {
        if (!root.present)
            return "";

        let status;
        if (root.full)
            status = "Fully charged";
        else if (root.charging)
            status = root.device.timeToFull > 0 ? `Charging, full in ${root.duration(root.device.timeToFull)}` : "Charging";
        else if (root.device.state === UPowerDeviceState.Discharging)
            status = root.device.timeToEmpty > 0 ? `${root.duration(root.device.timeToEmpty)} left` : "On battery";
        else
            status = "Plugged in";

        return `${status} · ${ControlCenter.profileName}`;
    }

    interactive: true
    onClicked: ControlCenter.cycleProfile()
}
