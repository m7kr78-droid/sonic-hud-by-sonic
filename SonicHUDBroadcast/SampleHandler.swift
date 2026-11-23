import ReplayKit
import CoreMedia
import Darwin

final class SampleHandler: RPBroadcastSampleHandler {
    private var frames = 0
    private var last = CACurrentMediaTime()

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        frames = 0
        last = CACurrentMediaTime()
        publish(0)
    }

    override func broadcastFinished() {
        publish(0)
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        frames += 1
        let now = CACurrentMediaTime()
        let dt = now - last
        if dt >= 0.4 {
            let hz = Int((Double(frames) / dt).rounded())
            publish(hz)
            frames = 0
            last = now
        }
    }

    private func publish(_ hz: Int) {
        var token: Int32 = 0
        notify_register_check("com.by.sonic.gamehud.hz", &token)
        notify_set_state(token, UInt64(max(0, min(240, hz))))
        notify_post("com.by.sonic.gamehud.hz")
    }
}
