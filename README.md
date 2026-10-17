# quickshell

A [Quickshell](https://quickshell.org) desktop shell for the niri compositor.
It provides a top bar, an app launcher, a keybinds overlay, a power menu,
notifications and the wallpaper.

Saving any file hot-reloads the running shell. Run `qs log -t 40` to see warnings.

## Layout

| Path | What lives there |
| --- | --- |
| `shell.qml` | Entry point. Instantiates the bar and wallpaper, and the launcher and keybinds singletons. |
| `ShellGlobals.qml` | Config and theme: fonts, colours (`materialColors`), sizes, motion (durations, easing curves, and `motionScale`, one multiplier for the whole shell's pace), search engine, world clocks. |
| `services/` | Singletons that own data and talk to the system: `Niri`, `Audio`, `Media`, `Notifications`, `SystemStats`, `Internet` (nmcli + Wi-Fi), `BluetoothState`, `Clipboard` (runs the cliphist recorder). |
| `components/` | Reusable UI pieces with no data of their own: `Anim`/`CAnim` (animations on the motion tokens), `Reveal` (shared entrance/exit), `FadeCard`, `BarPopup`, `BarPanel` (a dropdown that can take the keyboard), `OverlayController`, `Tooltip`, `TintedIcon`, `StyledText`, `Divider`, `Track`, and the terminal-styled `TuiPane`, `TuiTable`, `TuiFooter`. |
| `bar/` | The bar (one per screen), its widgets including the system tray, and the menus that drop from it. |
| `osd/` | On-screen displays: the volume OSD shown on the focused output. |
| `launcher/` | App launcher with inline calculator (`Calculator.js`), web search (`WebSearch.js`), fuzzy matching (`Fuzzy.js`) and usage history (`History.qml`). Start a query with `;` for clipboard history: Enter copies an entry back, Shift+Delete forgets it. |
| `keybinds/` | Searchable overlay of the binds in the niri config. |
| `logout/` | The power actions (lock, suspend, log out, reboot, shutdown) and the power menu's open state, in `LogoutState`. `bar/PowerMenu.qml` draws them. |
| `lock/` | Lock screen: `WlSessionLock` with a blurred wallpaper, clock and password field, checked through PAM (`ShellGlobals.lockPamConfig`/`lockPamDir`). `preview` shows it in a normal window without locking. |
| `wallpaper/` | Background layer per screen. |

Import services and components with `import qs.services` and `import qs.components`.

## Locking on idle

swayidle is started from the niri config (`spawn-at-startup "swayidle" …`) and
calls `qs ipc call lock lock` after 10 minutes idle, before suspend, and on
`loginctl lock-session`. Media playback holds the idle timer off. Change the
`600` there to adjust it.

## If the lock screen ever gets stuck

Should the shell crash while the session is locked, niri keeps the screen
locked (blank) until a lock client unlocks it. Switch to a TTY
(Ctrl+Alt+F2), log in, and run `WAYLAND_DISPLAY=wayland-1 swaylock`, then
switch back and unlock with your password.

## Tests

`./tests/run.sh` runs the unit tests for the pure-JS logic (calculator, fuzzy
ranking, web search, keybind parsing, nmcli parsing) headlessly and exits
non-zero on failure. Add cases to `tests/shell.qml`; new JS files under test
also need copying in `tests/run.sh`.

## IPC

Bind these in niri with `spawn "qs" "ipc" "call" ...`:

```
qs ipc call launcher      toggle | open | close
qs ipc call clipboard     toggle | open          # the launcher, in clipboard mode
qs ipc call keybinds      toggle | open | close
qs ipc call logout        toggle | open | close
qs ipc call lock          lock | preview | closePreview
qs ipc call volume        toggle | open | close
qs ipc call network       toggle | open | close
qs ipc call bluetooth     toggle | open | close
qs ipc call notifications toggle | clear | toggleDnd | dndOn | dndOff
```

Run `qs ipc show` to list them all.

## Extending

**A bar widget.** Make a `BarWidget` in `bar/` and set `icon` (a file in
`bar/icons`; `.png` is assumed when there's no extension), `label`, `color` and
`foreground`. Set `interactive: true` to receive `clicked`, `rightClicked` and
`scrolled`, and `tooltip` for a hover label. Then place it in one of the rows in `bar/Bar.qml`. Keep any polling
or system access in a `services/` singleton, so that a second monitor doesn't
double the work.

**A bar menu.** Subclass `BarPopup` and set its anchor, size and content. It
provides `open()`, `close()` and `toggle()`, fades in and out, and emits
`opened` and `hidden`. Declare it in `bar/Bar.qml` and add it to `popups` there.
That list is what makes clicking outside dismiss it.

**A keyboard overlay.** Like the launcher, put an `OverlayController` in a
singleton. Give it an `ipcTarget`, a layer-shell `namespace`, and a `content`
component that emits `closeRequested`. Then call the singleton's `init()` from
`shell.qml` so its IPC target is registered.

**A service.** Add a `pragma Singleton` file under `services/`. Singletons
instantiate on first use, so register IPC handlers in a singleton that
`shell.qml` touches.

**A world clock.** Add `{ name, offsetMinutes }` to
`ShellGlobals.worldClocks`. Offsets are fixed, so this is exact only for zones
without daylight saving.

**Motion.** Animate with `Anim` and `CAnim` rather than raw `NumberAnimation`
and `ColorAnimation`, and set `time`/`curve` instead of `duration`, so
`ShellGlobals.motionScale` keeps applying. Things that appear should use
`Reveal`, which plays the exit before anything unmaps.
