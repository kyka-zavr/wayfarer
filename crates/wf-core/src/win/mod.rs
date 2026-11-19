//! Windows internals: hooks, window enumeration, DWM, DPI.
//!
//! Kept behind `#[cfg(windows)]` so the crate still builds (and tests) on other
//! hosts. Nothing in here is public outside the crate.

use windows::Win32::UI::WindowsAndMessaging::GetForegroundWindow;

/// Starts every subsystem. Returns an error message on failure so `wf_init`
/// can fail loudly instead of half-hooking the desktop.
pub fn start() -> Result<(), &'static str> {
    // TODO(M1): set DPI awareness before creating any window-adjacent state.
    // TODO(M4): install WH_MOUSE_LL for `Win` + drag.
    // TODO(M5): RegisterHotKey for the launcher.
    Ok(())
}

/// Tears down in reverse order. Must be safe to call after a partial `start`.
pub fn stop() {
    // TODO: unhook and unregister in reverse order of `start`.
}

/// HWND of the foreground window, or 0 if there is none.
pub fn foreground_window() -> u64 {
    // SAFETY: no arguments, no ownership transferred.
    unsafe { GetForegroundWindow().0 as u64 }
}
