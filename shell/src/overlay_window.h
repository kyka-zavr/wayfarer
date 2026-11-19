#pragma once

#include <QQuickView>

class QScreen;

/**
 * A frameless, always-on-top, never-activated surface: top bar, dock, borders.
 *
 * Two Win32 details matter here:
 *   - WS_EX_NOACTIVATE keeps the overlay from stealing focus from the window
 *     you are actually using (clicks still arrive).
 *   - WS_EX_TOOLWINDOW keeps it out of Alt+Tab and the taskbar.
 *
 * The Qt flags alone are not enough: Qt::Tool still activates on click.
 */
class OverlayWindow final : public QQuickView
{
    Q_OBJECT

public:
    enum class Placement {
        TopBar,   ///< full width, pinned to the top of the screen
        Dock,     ///< centered, pinned to the bottom
        Launcher, ///< centered, sized for search results
    };

    OverlayWindow(Placement placement, QScreen *screen, QWindow *parent = nullptr);

    Placement placement() const { return m_placement; }
    void relayout();

protected:
    void showEvent(QShowEvent *event) override;

private:
    void applyPlatformStyles();

    Placement m_placement;
    QScreen *m_screen;
    bool m_styled = false;
};
