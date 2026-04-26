import SwiftUI
import ImageIO

struct ThumbnailView: View {
    let url: URL
    var height: CGFloat = 120
    @State private var image: NSImage?
    @State private var didFailLoad = false

    var body: some View {
        Group {
            if isVideo {
                ZStack {
                    Color.black.opacity(0.05)
                    Image(systemName: "film")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
            } else if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if didFailLoad {
                ZStack {
                    Color.black.opacity(0.05)
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
            } else {
                ZStack {
                    Color.black.opacity(0.05)
                    ProgressView().controlSize(.small)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: url) {
            await loadThumbnail()
        }
    }

    private var isVideo: Bool {
        ["mov", "mp4", "m4v"].contains(url.pathExtension.lowercased())
    }

    private func loadThumbnail() async {
        guard !isVideo else { return }
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let maxPixel = Int(height * scale * 2)  // 2x for headroom on wide thumbnails
        let url = self.url
        let result = await Task.detached(priority: .userInitiated) {
            ThumbnailView.downsample(url: url, maxPixelSize: maxPixel)
        }.value
        if let result {
            image = result
        } else {
            didFailLoad = true
        }
    }

    nonisolated static func downsample(url: URL, maxPixelSize: Int) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}
