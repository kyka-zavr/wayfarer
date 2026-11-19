# Architecture

## Shape

```
                 +----------------------------------------------+
                 |  shell/  (Qt 6, QML)                          |
                 |  top bar - dock - borders - launcher          |
                 |  pure presentation: no Win32, no hooks        |
                 +---------------------+------------------------+
                                       |  C ABI: wf_core.h
                                       |  events out, commands in
                 +---------------------v------------------------+
                 |  crates/wf-core  (Rust)                       |
                 |  hooks - window registry - DWM - drag math    |
                 +---------------------+------------------------+
                                       |  Win32
                 +---------------------v------------------------+
                 |  Windows: DWM, user32, shell32                |
                 +----------------------------------------------+
```

The split is not cosmetic. It follows one question: **would a mistake here hang the
desktop?** If yes, it lives in Rust behind the ABI. If no, it is QML.

## Why Rust for the core

- A low-level mouse hook has a hard deadline enforced by Windows (~300 ms). A missed
  deadline silently removes the hook. That thread must be predictable: no GC, no
  allocations, no locks held across a call.
- We are injecting into the input path of every mouse event. Memory safety here is not
  a preference.
- `windows` crate gives us typed Win32 with explicit `unsafe` at the boundary, so the
  dangerous surface is greppable.

## Why Qt for the frontend

- Mature layered/transparent window support, animation, and text rendering on Windows.
- QML gets us 60 fps bars and a launcher with declarative, hot-reloadable layout.
- One UI toolkit for the future settings app instead of a bespoke renderer.

`Qt::Tool | FramelessWindowHint | WindowStaysOnTopHint` handles the window shape, but is
**not** enough: Qt still activates on click. `OverlayWindow` additionally sets
`WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW`, which is what actually keeps focus in the window
you are working in and keeps the overlay out of Alt+Tab.

## Why a plain C ABI instead of cxx-qt

- We need exactly ~15 functions and one callback. Codegen would add a build-time
  dependency and a second mental model for the same boundary.
- The ABI is stable and documented by a hand-written header (`wf_core.h`), so the core
  can later be driven by a different frontend (Qt Widgets, a tray app, a CLI) without
  touching Rust.
- Cost: two files to keep in sync (`ffi.rs` and `wf_core.h`). Accepted; the surface is
  small and both are covered by CI.

## Threading model

| Thread | Owns | Rules |
| --- | --- | --- |
| Qt main | Windows, QML, rendering | May block on UI work; never called from hooks |
| Engine hook | `WH_MOUSE_LL`, `WH_KEYBOARD_LL` | Allocation-free, no Qt, no locks; enqueue and return |
| Engine worker | Event queue, window registry, DWM queries | May allocate and call Win32 freely |
| WinEvent | Focus/foreground notifications | Short: translate + enqueue + return |

Crossing into Qt is always `QMetaObject::invokeMethod(..., Qt::QueuedConnection)`. A hook
thread that calls into QML directly is a bug even if it appears to work.

## Event flow: `Win` + drag

```
user: Win down, LMB down over window W
  |
mouse hook (engine thread)
  |-- is Win held? is LMB down? is W ours / elevated / fullscreen?   [~1 us]
  |-- capture: W, cursor origin, DWM frame bounds, original rect
  |-- enqueue DragStarted(W)
  v
worker thread
  |-- emit WF_EVENT_WINDOW_MOVED for the border overlay
  v
Qt thread
  |-- borders repaint around W
  v
user moves cursor -> mouse hook: SetWindowPos(W, origin + delta)  [inline, no Qt]
```

The expensive-looking part (UI) is off the critical path. The only work between the
mouse event and the window moving is arithmetic plus one `SetWindowPos`.

## Latency budgets

| Path | Budget | Rationale |
| --- | --- | --- |
| Hook callback | < 200 us | Windows drops a hook after ~300 ms of total delay |
| Drag move | 0 round-trips to Qt | Visual lag is immediately noticeable |
| Launcher open | < 50 ms | Below the "did I miss the key?" threshold |
| Search keystroke → results | < 16 ms | One frame at 60 Hz |
| Focus event → border repaint | < 34 ms | Two frames; invisibly fast |

## Geometry rules

- Never trust `GetWindowRect` for a window with a DWM frame: use
  `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)`. The difference is invisible
  window borders that make drags feel off by a few pixels.
- Work in physical pixels inside the core. Convert to logical only at the Qt boundary.
- Per-monitor DPI v2 awareness is set once at startup, before any window is created.

## Failure modes

| Failure | Behaviour |
| --- | --- |
| Qt process exits | Hooks die with the process; Windows restores normal input |
| Core panics | `panic = "abort"` in release — the process dies loudly, no UB across the ABI |
| Hook times out | Watchdog reinstalls it and logs; drag degrades, desktop keeps working |
| Overlay becomes click-blocking | Borders use `WS_EX_TRANSPARENT`; `Esc` hides every overlay |

The last one matters: a shell that blocks clicks is worse than no shell. There is always
a kill switch (`Ctrl+Alt+F12` by default) that hides all overlays for the session.

## Repository layout

```
Cargo.toml                  workspace
crates/wf-core/             Rust engine (cdylib + rlib for tests)
  include/wf_core.h         the C ABI contract
  src/ffi.rs                exported functions
  src/win/                  Win32 internals
shell/                      Qt frontend
  CMakeLists.txt            drives cargo, then Qt
  src/                      app entry, Engine wrapper, OverlayWindow
  qml/                      TopBar, Dock, Launcher, Theme
docs/                       this file, ROADMAP
```

## Decision log

| Date | Decision | Why |
| --- | --- | --- |
| 2026-11 | Rust core + Qt/QML frontend, C ABI between them | Latency-critical Win32 work in a safe language; UI in a mature toolkit; smallest possible contract |
| 2026-11 | Name **Wayfarer**, tagline "way forever" | Real word, reads as a Wayland cousin, 8 letters |
| 2026-11 | Compose with Explorer, never replace it | Replacing the shell means fighting the OS forever; overlays get 90% of the feel for 10% of the risk |
