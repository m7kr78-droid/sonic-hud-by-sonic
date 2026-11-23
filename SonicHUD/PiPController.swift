import AVFoundation
import AVKit
import CoreMedia
import CoreVideo
import UIKit

final class PiPController: NSObject, AVPictureInPictureSampleBufferPlaybackDelegate {
    static let shared = PiPController()

    private let displayLayer = AVSampleBufferDisplayLayer()
    private var pip: AVPictureInPictureController?
    private var timer: DispatchSourceTimer?
    private var timebase: CMTimebase?
    private var startedAt = CACurrentMediaTime()
    private weak var hostView: UIView?

    var isRunning: Bool { pip?.isPictureInPictureActive == true }

    func attach(to view: UIView) {
        hostView = view
        displayLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        displayLayer.videoGravity = .resizeAspect
        displayLayer.isOpaque = false
        displayLayer.backgroundColor = UIColor.clear.cgColor
        if displayLayer.superlayer == nil {
            view.layer.addSublayer(displayLayer)
        }
        if timebase == nil {
            var tb: CMTimebase?
            CMTimebaseCreateWithSourceClock(allocator: kCFAllocatorDefault, sourceClock: CMClockGetHostTimeClock(), timebaseOut: &tb)
            if let tb {
                CMTimebaseSetRate(tb, rate: 1)
                displayLayer.controlTimebase = tb
                timebase = tb
            }
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func start() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        attach(to: hostView ?? UIView())
        if pip == nil {
            if #available(iOS 15.0, *) {
                let source = AVPictureInPictureController.ContentSource(
                    sampleBufferDisplayLayer: displayLayer,
                    playbackDelegate: self
                )
                pip = AVPictureInPictureController(contentSource: source)
                pip?.canStartPictureInPictureAutomaticallyFromInline = true
            }
        }
        pushFrame()
        pip?.startPictureInPicture()
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        pip?.stopPictureInPicture()
    }

    private func startTimer() {
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .milliseconds(200))
        t.setEventHandler { [weak self] in self?.pushFrame() }
        t.resume()
        timer = t
    }

    private func pushFrame() {
        let stats = StatsMonitor.shared.snapshot()
        let image = HUDCanvas.image(stats: stats)
        guard let buffer = pixelBuffer(from: image) else { return }
        var format: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescriptionOut: &format)
        guard let format else { return }
        let now = CACurrentMediaTime() - startedAt
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 5),
            presentationTimeStamp: CMTime(seconds: now, preferredTimescale: 600),
            decodeTimeStamp: .invalid
        )
        var sample: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sample
        )
        if let sample {
            if displayLayer.status == .failed {
                displayLayer.flush()
            }
            displayLayer.enqueue(sample)
        }
    }

    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width
        let h = cg.height
        var buffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [String: Any]
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buffer)
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let dest = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        guard let ctx = CGContext(
            data: dest,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return buffer
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        false
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
