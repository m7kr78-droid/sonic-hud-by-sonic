import SwiftUI
import AVFoundation

@main
struct SonicHUDApp: App {
    init() {
        GameHzBus.startHost()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
