#include "overlay_window.h"

#include <QScreen>
#include <QShowEvent>

#ifdef Q_OS_WIN
#  define WIN32_LEAN_AND_MEAN
#  define NOMINMAX
#  include <windows.h>
#  include <dwmapi.h>
#
#  pragma comment(lib, "dwmapi.lib")
#endif

namespace {
// Logical sizes. DPI scaling is applied by Qt before we hit Win32.
constexpr int kTopBarHeight = 34;
constexpr int kDockWidth = 720;
constexpr int kDockHeight = 72;
constexpr int kLauncherWidth = 720;
constexpr int kLauncherHeight = 440;
} // namespace

OverlayWindow::OverlayWindow(Placement placement, QScreen *screen, QWindow *parent)
    : QQuickView(parent)
    , m_placement(placement)
    , m_screen(screen)
{
    setColor(Qt::transparent);
    setResizeMode(QQuickView::SizeRootObjectToView);
    setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint | Qt::Tool);

    relayout();
}

void OverlayWindow::relayout()
{
    if (!m_screen)
        return;

    const QRect area = m_screen->geometry();

    switch (m_placement) {
    case Placement::TopBar:
        setGeometry(area.x(), area.y(), area.width(), kTopBarHeight);
        break;
    case Placement::Dock:
        setGeometry(area.x() + (area.width() - kDockWidth) / 2,
                    area.y() + area.height() - kDockHeight - 8,
                    kDockWidth,
                    kDockHeight);
        break;
    case Placement::Launcher:
        setGeometry(area.x() + (area.width() - kLauncherWidth) / 2,
                    area.y() + (area.height() - kLauncherHeight) / 3,
                    kLauncherWidth,
                    kLauncherHeight);
        break;
    }
}

void OverlayWindow::showEvent(QShowEvent *event)
{
    QQuickView::showEvent(event);

    if (!m_styled) {
        m_styled = true;
        applyPlatformStyles();
    }
}

void OverlayWindow::applyPlatformStyles()
{
#ifdef Q_OS_WIN
    const auto hwnd = reinterpret_cast<HWND>(winId());

    LONG_PTR exStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    exStyle |= WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW;
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exStyle);

    // Qt already gave us WS_POPUP without WS_CAPTION. DWM still draws a shadow
    // for it; ask for none so the bar does not tint the window behind it.
    const MARGINS noMargins{0, 0, 0, 0};
    DwmExtendFrameIntoClientArea(hwnd, &noMargins);
#endif
}
