# Roadmap

Wayfarer ships as a set of overlay surfaces plus a native engine. Each milestone is
independently shippable: if we stop after M4, the result is still a usable desktop
enhancement rather than a half-broken shell.

Legend: `[x]` done, `[~]` in progress, `[ ]` planned.

---

## Principles

1. **Nothing may break the desktop.** Every hook has an escape hatch, and killing the
   shell process must leave Windows fully usable. No persistent registry hacks.
2. **Fast is a feature.** The launcher opens in < 50 ms; drags stay at 60+ fps. If a
   feature cannot hit its latency budget, it gets cut, not shipped "close enough".
3. **Explorer stays.** We compose with the Windows shell, not against it. No patching
   system DLLs, no replacing `explorer.exe`, no hooking outside our own process tree
   where avoidable.
4. **One-way dependency.** `shell` depends on `wf-core`. The core never knows Qt exists.

---

## Milestones

| # | Milestone | Outcome | Status |
| --- | --- | --- | --- |
| M0 | Scaffold | Repo, build wiring, C ABI, CI | `[x]` |
| M1 | Engine foundation | Hooks, window tracking, event bus, top bar live | `[~]` |
| M2 | Dock | Pinned apps, running indicators, launch | `[ ]` |
| M3 | Window borders | Accent outline on the focused window | `[ ]` |
| M4 | `Win` + drag | Move any window from anywhere | `[ ]` |
| M5 | Launcher | Rofi-style fuzzy search, < 50 ms open | `[ ]` |
| M6 | Slash commands | `/run`, `/cmd`, extensible commands | `[ ]` |
| M7 | Workspaces | Virtual desktops with per-workspace docks | `[ ]` |
| M8 | Settings & themes | Live-reload config, theme editor | `[ ]` |
| M9 | Packaging | Installer, autostart, update check | `[ ]` |

---

## M0 — Scaffold

- [x] Rust workspace, `wf-core` crate, `cdylib` output
- [x] C ABI header (`wf_core.h`) + Qt wrapper (`Engine`)
- [x] Overlay window primitive (`WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW`)
- [x] CMake drives cargo; `wf_core.dll` copied next to the binary
- [x] CI: fmt, clippy, `cargo build`, CMake build with Qt

**Done when:** a clean clone builds on a machine with Rust + Qt, and running the shell
shows a bar and a dock that do not steal focus.

---

## M1 — Engine foundation

The boring milestone that everything else assumes.

- [ ] `start()` / `stop()` with strict reverse-order teardown
- [ ] WinEvent hook (`EVENT_OBJECT_FOCUS`, `EVENT_SYSTEM_FOREGROUND`) → `WF_EVENT_WINDOW_FOCUSED`
- [ ] Window registry: HWND → `{ title, class, pid, exe path, monitor, dpi, frame bounds }`
- [ ] Event queue drained by a dedicated worker thread; hooks only enqueue
- [ ] `wf_window_info()` and `wf_windows()` query calls
- [ ] Top bar binds to real data: focused title, clock, monitor count
- [ ] Watchdog: if the Qt process dies within 200 ms, unhook everything

**Acceptance:** focusing 10 different apps produces 10 correct, ordered events; no event
lost under a 60 Hz drag; `wf_shutdown()` leaves no hooks installed (verified in
Process Explorer).

**Notes:** WinEvent callbacks run on the thread that installed them and Windows gives us
a short budget. Never call into Qt from there — enqueue and return.

---

## M2 — Dock

- [ ] Pinned apps from `%APPDATA%/Wayfarer/dock.json` (id, label, exe, icon)
- [ ] Running indicator via window registry (`pid` match)
- [ ] Launch: `ShellExecuteW` with the app's working dir, no console flash
- [ ] Click on running app: focus its window, or minimize if already focused
- [ ] Hover scale, active-app dot, right-click menu (pin/unpin/close)
- [ ] Auto-hide with a 1 px activation strip

**Acceptance:** pinning survives restart; clicking a running app focuses instead of
launching a duplicate; dock never appears in Alt+Tab.

---

## M3 — Window borders

- [ ] One border overlay window per monitor, drawn *under* nothing and over everything
- [ ] Track focused window via `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)`
- [ ] Update on move/resize at 60 fps without flicker (`SetWindowPos` with `SWP_NOACTIVATE`)
- [ ] Ignore our own overlays, tool windows, and windows that opted out
- [ ] Configurable: width, color, radius, glow on focus

**Acceptance:** border follows a dragged window with no visible lag; no border on
maximized windows unless configured; overlay never blocks clicks (hit-test transparent).

---

## M4 — `Win` + drag

The headline feature.

- [ ] `WH_MOUSE_LL` hook: on `Win` down + LMB down over a window, take over the drag
- [ ] `SetWindowPos` per mouse delta, using DWM frame bounds so nothing jumps
- [ ] Skip: elevated windows (unless we run elevated), fullscreen, our overlays
- [ ] `Esc` cancels and restores the original position
- [ ] `Win` + RMB → resize from the nearest edge
- [ ] `Win` + LMB on empty desktop → drag to create a selection (later)

**Acceptance:** dragging a maximized window un-maximizes it and continues the drag under
the cursor (same feel as Windows' native title-bar drag); no cursor drift over a 4K
monitor; the hook returns in well under 300 ms even when the Qt process is busy.

**Notes:** the low-level hook has a hard timeout enforced by Windows, after which it is
silently removed. Do the math and `SetWindowPos` inline (single digits of microseconds),
never round-trip through Qt.

---

## M5 — Launcher

- [ ] Global hotkey (`Alt+Space`, configurable) via `RegisterHotKey` in the engine
- [ ] Open animation < 50 ms, from hotkey to first frame
- [ ] Index: Start Menu shortcuts, `PATH` executables, UWP apps, recent files
- [ ] Fuzzy match with ranking (prefix > word boundary > subsequence), 10 ms budget
- [ ] Keyboard only: `↑`/`↓`, `Enter`, `Esc`, `Tab` for actions
- [ ] Acrylic/DWM backdrop behind the panel

**Acceptance:** 20k indexed entries, keystroke-to-results under 16 ms; cold start of the
launcher window under 50 ms after the shell has been running.

---

## M6 — Slash commands

Rofi-style mode switching, with the Windows Run dialog as one mode among many.

- [ ] `/` opens a command palette instead of app search
- [ ] `/run <path>` — equivalent of Win+R, resolves `%VAR%`, URLs, shell folders
- [ ] `/cmd <command>` — runs through `cmd.exe /c`, output shown inline
- [ ] `/ps`, `/kill <pid>`, `/ws`, `/theme` as built-ins
- [ ] Command registry in Rust: name, description, arg hint, exec handler
- [ ] User commands from `commands.toml`

**Acceptance:** `/run notepad` behaves like Win+R; a bad command shows the error and does
not close the palette; unknown `/xyz` falls back to app search.

---

## M7 — Workspaces

- [ ] N virtual desktops backed by the native Windows Virtual Desktop API
- [ ] Top bar workspace pills reflect the active desktop
- [ ] `Win+1..9` switches, `Win+Shift+N` moves the focused window
- [ ] Dock per workspace (optional)

**Acceptance:** switching desktops does not flicker or lose focus; state survives a
shell restart.

---

## M8 — Settings & themes

- [ ] `%APPDATA%/Wayfarer/config.toml`, hot-reloaded
- [ ] QML theme tokens (`Theme.qml`) driven by config
- [ ] Settings window built with the same overlay primitives
- [ ] Per-monitor bar/dock placement, multi-monitor safe

---

## M9 — Packaging

- [ ] MSI or winget manifest
- [ ] Autostart entry (per-user, no service, no admin)
- [ ] Crash reporter that dumps the last 100 engine events
- [ ] Signed binaries

---

## Non-goals

- Replacing `explorer.exe` or the Windows taskbar process.
- Tiling window management (we are not a tiling WM; see "Window snapping" in the
  backlog for the nearest acceptable version).
- Cross-platform support. Linux is interesting, but Qt + Wayland is a different product.

---

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Low-level hook timeout (300 ms) silently unhooks us | Drag stops working | Keep hook body allocation-free and non-blocking; verify hook liveness every 5 s |
| Elevated windows ignore synthetic moves | Drag does nothing on admin apps | Detect and skip, show a hint; offer opt-in elevated mode |
| Per-monitor DPI changes mid-drag | Window jumps | Re-read DPI on `WM_DPICHANGED`, work in physical pixels |
| Explorer / Start menu conflicts | Shell looks broken | Overlays are `WS_EX_NOACTIVATE`; never suppress system UI |
| Anti-cheat / security software flags global hooks | App blocked | Document, ship signed builds, allow disabling features individually |
| Qt process crash leaves hooks installed | Desktop feels weird | Hooks are process-local: the OS removes them on exit; watchdog for graceful path |
