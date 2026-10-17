pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs

// Whether the session is locked, and the password check that unlocks it.
//
//     qs ipc call lock lock
//     qs ipc call lock preview|closePreview
//
// The preview shows the same lock screen in an ordinary window without
// locking anything, so it can be looked at and tried with a wrong password
// safely; a correct password simply closes it.
Singleton {
    id: root

    // Kept across config reloads: a reload while locked must not unlock.
    readonly property bool locked: persist.locked
    property bool previewing: false

    PersistentProperties {
        id: persist
        reloadableId: "lock"
        property bool locked: false
    }

    // The lock screen's content. Cleared first on success so it can fade out,
    // and only then is the session actually unlocked.
    property bool contentShown: persist.locked

    // Shown under the password field: "Checking…", "Wrong password", or a
    // PAM error.
    property string status: ""
    // Bumped on every rejected password; the field shakes when it changes.
    property int failures: 0

    readonly property bool checking: pam.active

    // Held only between submit() and PAM asking for it.
    property string pending: ""

    function lock(): void {
        if (root.locked)
            return;
        root.reset();
        persist.locked = true;
    }

    function preview(): void {
        root.reset();
        root.previewing = true;
    }

    function closePreview(): void {
        root.previewing = false;
    }

    function reset(): void {
        root.status = "";
        root.pending = "";
        root.contentShown = true;
    }

    function submit(password: string): void {
        if (pam.active || password === "")
            return;
        root.pending = password;
        root.status = "Checking…";
        pam.start();
    }

    function succeeded(): void {
        root.status = "";
        root.contentShown = false;
        unlockAfterFade.restart();
    }

    function failed(message: string): void {
        root.status = message;
        root.failures++;
        clearStatus.restart();
    }

    PamContext {
        id: pam
        config: ShellGlobals.lockPamConfig
        configDirectory: ShellGlobals.lockPamDir

        // PAM asks for the password once the conversation starts; answer
        // with the one being checked and forget it.
        onResponseRequiredChanged: {
            if (!pam.responseRequired)
                return;
            pam.respond(root.pending);
            root.pending = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success)
                root.succeeded();
            else
                root.failed("Wrong password");
        }

        onError: error => root.failed(`Authentication error: ${PamError.toString(error)}`)
    }

    // Lets the content's exit animation play before the lock goes away.
    Timer {
        id: unlockAfterFade
        interval: ShellGlobals.animNormal * 0.7 * ShellGlobals.motionScale + 50
        onTriggered: {
            persist.locked = false;
            root.previewing = false;
        }
    }

    Timer {
        id: clearStatus
        interval: 3000
        onTriggered: {
            if (!pam.active)
                root.status = "";
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function preview(): void {
            root.preview();
        }

        function closePreview(): void {
            root.closePreview();
        }
    }
}
