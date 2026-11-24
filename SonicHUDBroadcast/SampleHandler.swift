import ReplayKit
import CoreMedia
import QuartzCore

@objc(SampleHandler)
final class SampleHandler: RPBroadcastSampleHandler {
    private var frames = 0
    private var last = CACurrentMediaTime()

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        frames = 0
        last = CACurrentMediaTime()
    }

    override func broadcastFinished() {
        GameHzBus.publish(0)
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        frames += 1
        let now = CACurrentMediaTime()
        let dt = now - last
        if dt >= 0.25 {
            let hz = Int((Double(frames) / dt).rounded())
            GameHzBus.publish(max(1, hz))
            frames = 0
            last = now
        }
    }
}
