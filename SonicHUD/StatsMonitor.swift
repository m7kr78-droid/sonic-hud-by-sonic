import Foundation
import UIKit
import Darwin

struct DeviceStats {
    var screenHz: Int
    var cpuPercent: Double
    var ramPercent: Double
    var thermal: ProcessInfo.ThermalState
    var batteryPercent: Int

    var thermalArabic: String {
        switch thermal {
        case .nominal: return "باردة"
        case .fair: return "دافئة"
        case .serious: return "مرتفعة"
        case .critical: return "حارة جداً"
        @unknown default: return "—"
        }
    }
}

final class StatsMonitor {
    static let shared = StatsMonitor()

    private var lastCpu = host_cpu_load_info()
    private var haveCpu = false
    private let lock = NSLock()

    func snapshot() -> DeviceStats {
        lock.lock()
        defer { lock.unlock() }
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        return DeviceStats(
            screenHz: max(UIScreen.main.maximumFramesPerSecond, 60),
            cpuPercent: cpuUsage(),
            ramPercent: ramUsage(),
            thermal: ProcessInfo.processInfo.thermalState,
            batteryPercent: level < 0 ? -1 : Int((level * 100).rounded())
        )
    }

    private func cpuUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        if !haveCpu {
            lastCpu = info
            haveCpu = true
            return 0
        }
        let u = Double(info.cpu_ticks.0 &- lastCpu.cpu_ticks.0)
        let s = Double(info.cpu_ticks.1 &- lastCpu.cpu_ticks.1)
        let i = Double(info.cpu_ticks.2 &- lastCpu.cpu_ticks.2)
        let n = Double(info.cpu_ticks.3 &- lastCpu.cpu_ticks.3)
        lastCpu = info
        let total = u + s + i + n
        guard total > 0 else { return 0 }
        return min(100, max(0, (u + s + n) / total * 100))
    }

    private func ramUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        let page = Double(vm_kernel_page_size)
        let used = (Double(stats.active_count) + Double(stats.wire_count) + Double(stats.compressor_page_count)) * page
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return 0 }
        return min(100, max(0, used / total * 100))
    }
}
