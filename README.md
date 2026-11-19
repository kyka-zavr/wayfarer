<div align="center">

# Wayfarer

**A fast, keyboard-first desktop shell for Windows.**
The feel of a Linux tiling WM, without leaving Win32.

*way forever.*

</div>

> **Status:** pre-alpha scaffolding. Nothing is wired up yet — see [ROADMAP](docs/ROADMAP.md).

## What it is

Wayfarer does not replace Explorer. It dresses it: overlays drawn on top of your desktop,
plus a Rust engine that hooks the parts of Win32 the shell normally decides for you.

| Feature | What you get |
| --- | --- |
| **Top bar** | workspaces, focused window title, clock, tray — all QML |
| **Dock** | pinned apps, instant launch, auto-hide |
| **Window borders** | a thin accent outline on the focused window |
| **`Win` + drag** | move *any* window from *any* point inside it, no title bar needed |
| **Launcher** | Rofi-style, opens in under 50 ms, fuzzy search over apps and files |
| **`/` commands** | `/cmd`, `/run` — the Win+R dialog, built in and scriptable |

## Architecture in one paragraph

A Rust core (`wf-core`) owns everything latency-critical and everything dangerous: low-level
mouse/keyboard hooks, window tracking, DWM composition, drag math. It exposes a flat C ABI
(`crates/wf-core/include/wf_core.h`). A Qt 6 / QML frontend (`shell`) draws the bars, dock,
borders and launcher and stays ignorant of Win32. The core never blocks on the UI; the UI never
touches a hook. Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

```
+---------------------------+
|  shell/   Qt6 + QML       |  drawing, input, animations
+-------------+-------------+
              |  C ABI (wf_core.h)
+-------------+-------------+
|  crates/wf-core   Rust    |  hooks, window state, DWM, drag
+---------------------------+
```

## Layout

```
crates/wf-core/     Rust engine  -> wf_core.dll, consumed through wf_core.h
shell/              Qt 6 / QML frontend (CMake)
docs/               architecture and roadmap
```

## Build

Requirements: Windows 10/11, Rust stable (MSVC toolchain), Qt 6.5+ for MSVC 2022 x64, CMake 3.21+.

```powershell
winget install --id Rustlang.Rustup
rustup default stable-msvc

# Qt: online installer, or aqtinstall:
#   pip install aqtinstall
#   aqt install-qt windows desktop 6.8.0 win64_msvc2022_64

cmake -S shell -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.8.0/msvc2022_64"
cmake --build build --config Release
```

The engine alone builds without Qt:

```powershell
cargo build --release -p wf-core
```

## License

MIT for Wayfarer itself. Qt is linked dynamically under LGPLv3.
