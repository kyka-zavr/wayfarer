#pragma once

#include <QObject>

#include <functional>

extern "C" {
#include "wf_core.h"
}

/**
 * Thin C++ wrapper over the Rust engine's C ABI.
 *
 * Responsibilities are deliberately boring: start, stop, translate the raw
 * callback into Qt signals. All shell logic lives in Rust; all presentation
 * lives in QML.
 */
class Engine final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit Engine(QObject *parent = nullptr);
    ~Engine() override;

    bool start();
    void stop();

    QString version() const;

signals:
    /// The launcher hotkey was pressed. Emitted on the Qt thread.
    void launcherToggled();
    /// A different top-level window became focused. Emitted on the Qt thread.
    void windowFocused(quintptr hwnd);

private:
    /// Called by the engine; must never block.
    static void onEvent(uint32_t kind, uint64_t hwnd, int32_t x, int32_t y);

    /// Queues `fn` onto the Qt thread. No-op if the engine is shutting down.
    static void post(std::function<void(Engine *)> fn);

    static Engine *s_instance;

    bool m_running = false;
};
