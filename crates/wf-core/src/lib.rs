//! Wayfarer shell engine.
//!
//! This crate is the only part of the project that talks to Win32. It exposes a
//! flat C ABI (see `include/wf_core.h`) that the Qt frontend consumes.
//!
//! Design rules, in order of importance:
//!
//! 1. **Never block the hook thread.** Low-level hooks get ~300 ms before Windows
//!    silently drops them. Anything slow is queued and handled off-thread.
//! 2. **The UI is optional.** If the Qt process dies, the engine must unhook and
//!    leave the desktop in a usable state.
//! 3. **No panics across the ABI.** `panic = "abort"` in release; every entry point
//!    is a plain `extern "C"` function with no unwinding.
//!
//! Module map:
//!
//! - [`ffi`] — the exported surface. Keep it small; it is an API contract.
//! - [`win`] — Windows internals (hooks, window enumeration, DWM, DPI).

mod ffi;

#[cfg(windows)]
mod win;

pub use ffi::*;
