pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification daemon, its history and do-not-disturb.
//
//     qs ipc call notifications toggle|clear
//     qs ipc call notifications toggleDnd|dndOn|dndOff
Singleton {
    id: root

    // Every tracked notification, oldest first.
    property ScriptModel notifications: list

    // Retention cap, so a chatty app cannot grow the tracked list forever.
    readonly property int maxTracked: 50

    // Menu visibility lives here, not in Menu.qml: the menu is instantiated once
    // per screen, and registering the same IPC target more than once conflicts.
    property bool menuOpen: false

    // Kept in PersistentProperties so editing the shell does not silently turn
    // do-not-disturb back off.
    readonly property bool dnd: persist.dnd

    // Notifications currently shown as toasts, oldest first. Every incoming
    // notification is tracked in the history; it only toasts when
    // do-not-disturb is off and the history is not already open.
    property var toasts: []
    readonly property int maxToasts: 4

    // How long a toast stays up, in ms; 0 means until dismissed. Critical
    // ones stay, otherwise the sender's timeout wins (the spec gives it in
    // ms), falling back to 5s when it leaves the choice to us.
    function toastTimeout(n: Notification): int {
        if (!n || n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout : 5000;
    }

    function dropToast(n: Notification): void {
        root.toasts = root.toasts.filter(t => t !== n);
    }

    // The history shows everything the toasts would, so opening it clears them.
    onMenuOpenChanged: {
        if (root.menuOpen)
            root.toasts = [];
    }

    function setDnd(on: bool): void {
        persist.dnd = on;
    }

    function clearNotifs(): void {
        // Snapshot first. The old loop walked the live list forwards while
        // dismiss() shrank it, so indices shifted and every other one survived.
        for (const n of [...server.trackedNotifications.values]) {
            n.dismiss();
        }
    }

    PersistentProperties {
        id: persist
        reloadableId: "notifications"
        property bool dnd: false
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.menuOpen = !root.menuOpen;
        }

        function clear(): void {
            root.clearNotifs();
        }

        function toggleDnd(): void {
            root.setDnd(!root.dnd);
        }

        function dndOn(): void {
            root.setDnd(true);
        }

        function dndOff(): void {
            root.setDnd(false);
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: false

        // Only advertise what NotificationEntry actually renders. Claiming
        // support made senders ship payloads that were silently dropped.
        actionIconsSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false

        onNotification: n => {
            n.tracked = true;

            // Re-read the list each pass; dismiss() mutates it. Bounded so a
            // dismissal that does not take effect cannot spin forever.
            for (let i = 0; i < 16 && server.trackedNotifications.values.length > root.maxTracked; i++) {
                server.trackedNotifications.values[0].dismiss();
            }

            // Gone from the toasts the moment it closes, however that happens.
            n.closed.connect(() => root.dropToast(n));

            if (!root.dnd && !root.menuOpen)
                root.toasts = [...root.toasts, n].slice(-root.maxToasts);
        }
    }

    ScriptModel {
        id: list
        values: [...server.trackedNotifications.values]
    }
}
