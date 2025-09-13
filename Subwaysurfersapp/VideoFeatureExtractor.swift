import AVFoundation

class VideoFeatureExtractor {
    /// Extracts simple motion features from a video file
    func extractFeatures(from url: URL, frameCount: Int = 60) -> [[Double]] {
        var features: [[Double]] = []

        let asset = AVAsset(url: url)
        let reader = try! AVAssetReader(asset: asset)
        let track = asset.tracks(withMediaType: .video).first!

        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(output)
        reader.startReading()

        var lastFrame: CVPixelBuffer?

        while let sampleBuffer = output.copyNextSampleBuffer(), features.count < frameCount {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }

            if let last = lastFrame {
                let diff = frameDifference(last, pixelBuffer)
                features.append(diff)
            } else {
                features.append([0, 0, 0]) // first frame
            }

            lastFrame = pixelBuffer
        }

        while features.count < frameCount {
            features.append([0, 0, 0])
        }

        return features
    }

    private func frameDifference(_ a: CVPixelBuffer, _ b: CVPixelBuffer) -> [Double] {
        CVPixelBufferLockBaseAddress(a, .readOnly)
        CVPixelBufferLockBaseAddress(b, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(a, .readOnly)
            CVPixelBufferUnlockBaseAddress(b, .readOnly)
        }

        let width = min(CVPixelBufferGetWidth(a), CVPixelBufferGetWidth(b))
        let height = min(CVPixelBufferGetHeight(a), CVPixelBufferGetHeight(b))
        var sumR = 0.0, sumG = 0.0, sumB = 0.0

        let ptrA = CVPixelBufferGetBaseAddress(a)!.assumingMemoryBound(to: UInt8.self)
        let ptrB = CVPixelBufferGetBaseAddress(b)!.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(a)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * bytesPerRow + x * 4
                sumB += abs(Double(ptrA[idx]) - Double(ptrB[idx]))
                sumG += abs(Double(ptrA[idx+1]) - Double(ptrB[idx+1]))
                sumR += abs(Double(ptrA[idx+2]) - Double(ptrB[idx+2]))
            }
        }

        let count = Double(width * height)
        return [sumR/count, sumG/count, sumB/count]
    }
}
