import Foundation
import Darwin

enum GameHzBus {
    static let name = "com.by.sonic.gamehud.hz" as CFString

    static func publish(_ hz: Int) {
        var token: Int32 = 0
        notify_register_check(name as String, &token)
        notify_set_state(token, UInt64(max(0, min(240, hz))))
        notify_post(name as String)
    }

    static func current() -> Int {
        var token: Int32 = 0
        notify_register_check(name as String, &token)
        var state: UInt64 = 0
        notify_get_state(token, &state)
        return Int(state)
    }
}
