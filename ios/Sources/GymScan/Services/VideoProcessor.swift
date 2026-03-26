import AVFoundation
import UIKit

struct VideoProcessor {
    static let targetFrameCount = 12
    static let jpegQuality: CGFloat = 0.7
    static let maxFrameWidth: CGFloat = 1024

    static func extractFrames(from videoURL: URL) async throws -> [Data] {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds > 0 else {
            throw VideoProcessingError.invalidVideo
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxFrameWidth, height: maxFrameWidth)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        let interval = durationSeconds / Double(targetFrameCount)
        var times: [CMTime] = []
        for i in 0..<targetFrameCount {
            let seconds = Double(i) * interval + (interval / 2.0)
            times.append(CMTime(seconds: min(seconds, durationSeconds - 0.1), preferredTimescale: 600))
        }

        var frames: [Data] = []

        for time in times {
            do {
                let (image, _) = try await generator.image(at: time)
                let uiImage = UIImage(cgImage: image)
                if let jpegData = uiImage.jpegData(compressionQuality: jpegQuality) {
                    frames.append(jpegData)
                }
            } catch {
                // Skip frames that fail to extract
                continue
            }
        }

        guard !frames.isEmpty else {
            throw VideoProcessingError.noFramesExtracted
        }

        return frames
    }
}

enum VideoProcessingError: LocalizedError {
    case invalidVideo
    case noFramesExtracted

    var errorDescription: String? {
        switch self {
        case .invalidVideo: return "The recorded video is invalid"
        case .noFramesExtracted: return "Could not extract frames from video"
        }
    }
}
