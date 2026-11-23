import Foundation

@_silgen_name("notify_register_check")
func notify_register_check(_ name: UnsafePointer<CChar>, _ outToken: UnsafeMutablePointer<Int32>) -> Int32
@_silgen_name("notify_set_state")
func notify_set_state(_ token: Int32, _ state: UInt64) -> Int32
@_silgen_name("notify_get_state")
func notify_get_state(_ token: Int32, _ state: UnsafeMutablePointer<UInt64>) -> Int32
@_silgen_name("notify_post")
func notify_post(_ name: UnsafePointer<CChar>) -> Int32

enum GameHzBus {
    static let name = "com.by.sonic.gamehud.hz"

    static func publish(_ hz: Int) {
        name.withCString { cName in
            var token: Int32 = 0
            _ = notify_register_check(cName, &token)
            _ = notify_set_state(token, UInt64(max(0, min(240, hz))))
            _ = notify_post(cName)
        }
    }

    static func current() -> Int {
        var state: UInt64 = 0
        name.withCString { cName in
            var token: Int32 = 0
            _ = notify_register_check(cName, &token)
            _ = notify_get_state(token, &state)
        }
        return Int(state)
    }
}
