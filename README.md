# quickshell

A [Quickshell](https://quickshell.org) desktop shell for the niri compositor.
It provides a top bar, an app launcher, a keybinds overlay, a logout menu,
notifications and the wallpaper.

Saving any file hot-reloads the running shell. Run `qs log -t 40` to see warnings.

## Layout

| Path | What lives there |
| --- | --- |
| `shell.qml` | Entry point. Instantiates the bar, wallpaper and logout menu, and the launcher and keybinds singletons. |
| `ShellGlobals.qml` | Config and theme: fonts, colours (`materialColors`), sizes, animation durations, search engine, world clocks. |
| `services/` | Singletons that own data and talk to the system: `Niri`, `Audio`, `Media`, `Notifications`, `SystemStats`. |
| `components/` | Reusable UI pieces with no data of their own: `BarPopup`, `OverlayController`, `TintedIcon`, `StyledText`, `Divider`, `Track`. |
| `bar/` | The bar (one per screen), its widgets, and the menus that drop from it. |
| `launcher/` | App launcher with inline calculator (`Calculator.js`), web search (`WebSearch.js`) and fuzzy matching (`Fuzzy.js`). |
| `keybinds/` | Searchable overlay of the binds in the niri config. |
| `logout/` | Full-screen lock/suspend/logout/reboot/shutdown menu. |
| `wallpaper/` | Background layer per screen. |

Import services and components with `import qs.services` and `import qs.components`.

## IPC

Bind these in niri with `spawn "qs" "ipc" "call" ...`:

```
qs ipc call launcher      toggle | open | close
qs ipc call keybinds      toggle | open | close
qs ipc call logout        toggle | open | close
qs ipc call notifications toggle | clear | toggleDnd | dndOn | dndOff
```

Run `qs ipc show` to list them all.

## Extending

**A bar widget.** Make a `BarWidget` in `bar/` and set `icon` (a file in
`bar/icons`; `.png` is assumed when there's no extension), `label`, `color` and
`foreground`. Set `interactive: true` to receive `clicked`, `rightClicked` and
`scrolled`. Then place it in one of the rows in `bar/Bar.qml`. Keep any polling
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
