//! Exported C ABI. Mirrored by `include/wf_core.h` — change both together.
//!
//! Everything here must be `#[no_mangle] extern "C"` and must not unwind.

use std::os::raw::{c_char, c_int};
use std::sync::atomic::{AtomicBool, AtomicPtr, Ordering};

#[cfg(windows)]
use crate::win;

/// Event kinds delivered to the frontend callback.
pub const WF_EVENT_WINDOW_FOCUSED: u32 = 1;
pub const WF_EVENT_WINDOW_MOVED: u32 = 2;
pub const WF_EVENT_LAUNCHER_TOGGLE: u32 = 3;

pub type WfEventFn = extern "C" fn(kind: u32, hwnd: u64, x: i32, y: i32);

/// NUL-terminated version string; lives for the whole process.
static VERSION: &[u8] = concat!(env!("CARGO_PKG_VERSION"), "\0").as_bytes();

static STARTED: AtomicBool = AtomicBool::new(false);
static CALLBACK: AtomicPtr<()> = AtomicPtr::new(std::ptr::null_mut());

/// Engine version, e.g. `"0.1.0"`.
#[no_mangle]
pub extern "C" fn wf_version() -> *const c_char {
    VERSION.as_ptr().cast()
}

/// Starts the engine and registers the event callback.
///
/// Idempotent: a second call while running returns 0 without re-hooking.
/// Returns 0 on success, non-zero on failure.
///
/// # Safety
/// `cb` may be null. If non-null it is called from an engine thread, never from
/// the caller's thread, and never re-entrantly.
#[no_mangle]
pub extern "C" fn wf_init(cb: Option<WfEventFn>) -> c_int {
    if STARTED.swap(true, Ordering::SeqCst) {
        return 0;
    }

    if let Some(cb) = cb {
        // fn pointers are not guaranteed to be *mut (), go through usize.
        CALLBACK.store(cb as usize as *mut (), Ordering::SeqCst);
    }

    #[cfg(windows)]
    {
        if let Err(err) = win::start() {
            STARTED.store(false, Ordering::SeqCst);
            eprintln!("wf-core: start failed: {err}");
            return 1;
        }
    }

    0
}

/// Stops the engine and removes every hook. Safe to call when not running.
#[no_mangle]
pub extern "C" fn wf_shutdown() {
    if !STARTED.swap(false, Ordering::SeqCst) {
        return;
    }

    CALLBACK.store(std::ptr::null_mut(), Ordering::SeqCst);

    #[cfg(windows)]
    win::stop();
}

/// HWND of the currently focused top-level window, or 0.
#[no_mangle]
pub extern "C" fn wf_foreground_window() -> u64 {
    #[cfg(windows)]
    {
        return win::foreground_window();
    }
    #[cfg(not(windows))]
    {
        0
    }
}

/// FFI-safe panic guard. Called on the way out of every entry point.
#[inline]
#[allow(dead_code)] // referenced once worker threads land
pub(crate) fn guard() {
    // Placeholder: release builds are `panic = "abort"`, debug builds unwind.
    // When we start using threads, wrap their bodies in `catch_unwind`.
}

/// Dispatches an event to the registered callback, if any.
#[allow(dead_code)] // wired up as soon as hooks land
pub(crate) fn emit(kind: u32, hwnd: u64, x: i32, y: i32) {
    let raw = CALLBACK.load(Ordering::SeqCst);

    if raw.is_null() {
        return;
    }

    // SAFETY: the only writer stores a `WfEventFn`; it is never cleared while an
    // event is in flight because shutdown drains hooks first.
    let cb: WfEventFn = unsafe { std::mem::transmute(raw) };
    cb(kind, hwnd, x, y);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_is_nul_terminated() {
        assert_eq!(*VERSION.last().unwrap(), 0);
        assert!(!VERSION.is_empty());
    }
}
