#pragma once

#include <qimage.h>
#include <qmutex.h>
#include <qobject.h>
#include <qset.h>
#include <qsize.h>
#include <qstring.h>

namespace caelestia::images {

class ImageCacher : public QObject {
    Q_OBJECT

public:
    enum class FillMode : quint8 {
        Crop,
        Fit,
        Stretch,
    };

    static ImageCacher* instance();

    static const QString& cacheDir();
    static QString cachePathFor(const QString& sourcePath, const QSize& size, FillMode fillMode);

    // Not directly decodable as an image (e.g. a video wallpaper) - grab a frame with ffmpeg instead.
    static QImage grabVideoFrame(const QString& sourcePath);

    void schedule(const QString& sourcePath, const QSize& size, FillMode fillMode);
    // preloaded: an already-decoded frame, if the caller has one (avoids a second, expensive
    // ffmpeg decode racing the first when the source is a video).
    void schedule(const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode,
        const QImage& preloaded = {});

private:
    explicit ImageCacher(QObject* parent = nullptr);

    static void runJob(
        const QString& sourcePath, const QString& cachePath, const QSize& size, FillMode fillMode, QImage preloaded);

    QMutex m_mutex;
    QSet<QString> m_inflight;
};

} // namespace caelestia::images
