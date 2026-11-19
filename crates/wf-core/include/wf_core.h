/*
 * Wayfarer engine — public C ABI.
 *
 * This header is the contract between the Rust core and the Qt frontend.
 * It is hand-maintained; keep it in sync with crates/wf-core/src/ffi.rs.
 *
 * Rules:
 *   - All strings are UTF-8, NUL-terminated, and owned by the engine.
 *   - All functions are thread-safe unless stated otherwise.
 *   - Callbacks fire on an engine thread. Do not block them: hand work to the
 *     Qt event loop and return immediately.
 */

#ifndef WF_CORE_H
#define WF_CORE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Event kinds. Mirrors WF_EVENT_* in ffi.rs. */
#define WF_EVENT_WINDOW_FOCUSED   1u
#define WF_EVENT_WINDOW_MOVED     2u
#define WF_EVENT_LAUNCHER_TOGGLE  3u

/* kind, hwnd (0 when not applicable), x, y */
typedef void (*wf_event_fn)(uint32_t kind, uint64_t hwnd, int32_t x, int32_t y);

/* Engine version, e.g. "0.1.0". Never NULL. */
const char *wf_version(void);

/*
 * Starts the engine and registers a callback (may be NULL).
 * Idempotent. Returns 0 on success, non-zero on failure.
 */
int32_t wf_init(wf_event_fn cb);

/* Removes every hook. Safe when not running. */
void wf_shutdown(void);

/* HWND of the focused top-level window, or 0. */
uint64_t wf_foreground_window(void);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* WF_CORE_H */
