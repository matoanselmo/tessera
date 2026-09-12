pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: notif

    property NotificationServer notifServer: server
    property ScriptModel notifications: sList
    property int notifCount: server.trackedNotifications.values.length

    // Retention cap, so a chatty app cannot grow the tracked list forever.
    readonly property int maxTracked: 50

    // Menu visibility lives here, not in Menu.qml: the menu is instantiated once
    // per screen, and registering the same IPC target more than once conflicts.
    property bool menuOpen: false

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            notif.menuOpen = !notif.menuOpen;
        }

        function clear(): void {
            notif.clearNotifs();
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
            for (let i = 0; i < 16 && server.trackedNotifications.values.length > notif.maxTracked; i++) {
                server.trackedNotifications.values[0].dismiss();
            }
        }
    }

    ScriptModel {
        id: sList
        values: [...server.trackedNotifications.values]
    }

    function clearNotifs(): void {
        // Snapshot first. The old loop walked the live list forwards while
        // dismiss() shrank it, so indices shifted and every other one survived.
        for (const n of [...server.trackedNotifications.values]) {
            n.dismiss();
        }
    }
}
