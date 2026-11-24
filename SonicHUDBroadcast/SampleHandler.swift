import ReplayKit
import CoreMedia
import QuartzCore

@_silgen_name("notify_register_check")
func notify_register_check(_ name: UnsafePointer<CChar>, _ outToken: UnsafeMutablePointer<Int32>) -> Int32
@_silgen_name("notify_set_state")
func notify_set_state(_ token: Int32, _ state: UInt64) -> Int32
@_silgen_name("notify_post")
func notify_post(_ name: UnsafePointer<CChar>) -> Int32

@objc(SampleHandler)
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
        "com.by.sonic.gamehud.hz".withCString { cName in
            var token: Int32 = 0
            _ = notify_register_check(cName, &token)
            _ = notify_set_state(token, UInt64(max(0, min(240, hz))))
            _ = notify_post(cName)
        }
    }
}
