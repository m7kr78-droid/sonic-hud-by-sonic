import Foundation
import Darwin
import Security
import Dispatch

enum GameHzBus {
    private static let darwin = "com.by.sonic.gamehud.hz"
    private static let fallbackGroup = "group.com.by.sonic.gamehud"
    private static let port: UInt16 = 47891
    private static let lock = NSLock()
    private static var cached = 0
    private static var cachedAt: CFAbsoluteTime = 0
    private static var hostReady = false

    static func publish(_ hz: Int) {
        let value = max(0, min(240, hz))
        remember(value)
        publishDarwin(value)
        publishUDP(value)
        publishDefaults(value)
    }

    static func current() -> Int {
        lock.lock()
        let value = cached
        let age = CFAbsoluteTimeGetCurrent() - cachedAt
        lock.unlock()
        if value > 0 && age < 2.5 { return value }
        if let stored = readDefaults(), stored > 0 { return stored }
        let darwinValue = darwinGet()
        if darwinValue > 0 { return darwinValue }
        return value > 0 && age < 4 ? value : 0
    }

    static func startHost() {
        lock.lock()
        if hostReady {
            lock.unlock()
            return
        }
        hostReady = true
        lock.unlock()
        listenDarwin()
        listenUDP()
        listenNamedHz()
    }

    private static func remember(_ hz: Int) {
        lock.lock()
        cached = hz
        cachedAt = CFAbsoluteTimeGetCurrent()
        lock.unlock()
    }

    private static func publishDarwin(_ hz: Int) {
        darwin.withCString { cName in
            var token: Int32 = 0
            _ = notify_register_check(cName, &token)
            _ = notify_set_state(token, UInt64(hz))
            _ = notify_post(cName)
        }
        "\(darwin).n.\(hz)".withCString { cName in
            _ = notify_post(cName)
        }
    }

    private static func darwinGet() -> Int {
        var state: UInt64 = 0
        darwin.withCString { cName in
            var token: Int32 = 0
            _ = notify_register_check(cName, &token)
            _ = notify_get_state(token, &state)
        }
        return Int(state)
    }

    private static func listenDarwin() {
        darwin.withCString { cName in
            var token: Int32 = 0
            _ = notify_register_dispatch(cName, &token, DispatchQueue.main) { tok in
                var state: UInt64 = 0
                _ = notify_get_state(tok, &state)
                remember(Int(state))
            }
        }
    }

    private static func listenNamedHz() {
        let queue = DispatchQueue(label: "com.by.sonic.gamehud.hz.names")
        for hz in 0...240 {
            let value = hz
            let name = "\(darwin).n.\(value)"
            name.withCString { cName in
                var token: Int32 = 0
                _ = notify_register_dispatch(cName, &token, queue) { _ in
                    remember(value)
                }
            }
        }
    }

    private static func publishUDP(_ hz: Int) {
        let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard sock >= 0 else { return }
        defer { close(sock) }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        var value = UInt32(hz).littleEndian
        _ = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sap in
                withUnsafeBytes(of: &value) { raw in
                    sendto(sock, raw.baseAddress, 4, 0, sap, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    private static func listenUDP() {
        DispatchQueue.global(qos: .userInteractive).async {
            let sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
            guard sock >= 0 else { return }
            var reuse: Int32 = 1
            setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
            var addr = sockaddr_in()
            addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = port.bigEndian
            addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
            let bound = withUnsafePointer(to: &addr) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sap in
                    bind(sock, sap, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard bound == 0 else {
                close(sock)
                return
            }
            var value = UInt32(0)
            while true {
                let n = recv(sock, &value, 4, 0)
                if n == 4 {
                    remember(Int(UInt32(littleEndian: value)))
                }
            }
        }
    }

    private static func groupId() -> String {
        if let task = SecTaskCreateFromSelf(nil) {
            var err: Unmanaged<CFError>?
            if let value = SecTaskCopyValueForEntitlement(task, "com.apple.security.application-groups" as CFString, &err) as? [String],
               let first = value.first, !first.isEmpty {
                return first
            }
        }
        return fallbackGroup
    }

    private static func defaults() -> UserDefaults? {
        UserDefaults(suiteName: groupId())
    }

    private static func publishDefaults(_ hz: Int) {
        let box = defaults()
        box?.set(hz, forKey: "hz")
        box?.set(Date().timeIntervalSince1970, forKey: "at")
        box?.synchronize()
    }

    private static func readDefaults() -> Int? {
        guard let box = defaults() else { return nil }
        let at = box.double(forKey: "at")
        guard at > 0, Date().timeIntervalSince1970 - at < 2.5 else { return nil }
        return box.integer(forKey: "hz")
    }
}
