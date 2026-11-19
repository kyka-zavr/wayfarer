#include <QGuiApplication>
#include <QQmlContext>
#include <QScreen>

#include "engine.h"
#include "overlay_window.h"

namespace {

void loadInto(OverlayWindow &window, const char *qml)
{
    window.setSource(QUrl(QStringLiteral("qrc:/qml/%1").arg(QLatin1String(qml))));
    window.show();
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Wayfarer"));
    QGuiApplication::setApplicationVersion(QStringLiteral(WF_VERSION_STRING));
    QGuiApplication::setOrganizationName(QStringLiteral("Wayfarer"));

    // One Qt process per desktop session. A second launch should hand off to the
    // running instance once we have IPC; for now, just don't fight ourselves.
    Engine engine;
    if (!engine.start()) {
        qCritical("wf-core failed to start");
        return 1;
    }

    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen) {
        qCritical("no screen available");
        return 1;
    }

    OverlayWindow topBar(OverlayWindow::Placement::TopBar, screen);
    topBar.rootContext()->setContextProperty(QStringLiteral("engine"), &engine);
    loadInto(topBar, "TopBar.qml");

    OverlayWindow dock(OverlayWindow::Placement::Dock, screen);
    loadInto(dock, "Dock.qml");

    OverlayWindow launcher(OverlayWindow::Placement::Launcher, screen);
    launcher.rootContext()->setContextProperty(QStringLiteral("engine"), &engine);
    launcher.setSource(QUrl(QStringLiteral("qrc:/qml/Launcher.qml")));

    QObject::connect(&engine, &Engine::launcherToggled, &launcher, [&launcher] {
        if (launcher.isVisible())
            launcher.hide();
        else
            launcher.show();
    });

    // Re-pin overlays when the desktop layout changes (resolution, taskbar, DPI).
    QObject::connect(screen, &QScreen::geometryChanged, &topBar, &OverlayWindow::relayout);
    QObject::connect(screen, &QScreen::geometryChanged, &dock, &OverlayWindow::relayout);
    QObject::connect(screen, &QScreen::geometryChanged, &launcher, &OverlayWindow::relayout);

    return app.exec();
}
