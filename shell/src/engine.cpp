#include "engine.h"

#include <QMetaObject>
#include <QPointer>

#include <functional>
#include <utility>

Engine *Engine::s_instance = nullptr;

Engine::Engine(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
}

Engine::~Engine()
{
    stop();
    s_instance = nullptr;
}

bool Engine::start()
{
    if (m_running)
        return true;

    m_running = wf_init(&Engine::onEvent) == 0;
    return m_running;
}

void Engine::stop()
{
    if (!m_running)
        return;

    wf_shutdown();
    m_running = false;
}

QString Engine::version() const
{
    return QString::fromUtf8(wf_version());
}

void Engine::onEvent(uint32_t kind, uint64_t hwnd, int32_t /*x*/, int32_t /*y*/)
{
    switch (kind) {
    case WF_EVENT_LAUNCHER_TOGGLE:
        post([](Engine *e) { emit e->launcherToggled(); });
        break;
    case WF_EVENT_WINDOW_FOCUSED:
        post([hwnd](Engine *e) { emit e->windowFocused(static_cast<quintptr>(hwnd)); });
        break;
    default:
        break;
    }
}

void Engine::post(std::function<void(Engine *)> fn)
{
    Engine *instance = s_instance;
    if (!instance)
        return;

    // Queued: the callback thread is an engine thread, never the Qt thread.
    QMetaObject::invokeMethod(
        instance,
        [instance, fn = std::move(fn)] {
            if (s_instance)
                fn(instance);
        },
        Qt::QueuedConnection);
}
