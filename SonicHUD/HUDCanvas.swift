import UIKit

enum HUDCanvas {
    static let width = 520
    static let height = 72

    static func image(stats: DeviceStats) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let cg = ctx.cgContext
            cg.clear(rect)
            let bg = UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 0.32)
            cg.setFillColor(bg.cgColor)
            UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 6), cornerRadius: 16).fill()

            let hzText = stats.gameHz > 0 ? "\(stats.gameHz)Hz" : "--Hz"
            let cpu = String(format: "%.0f%%", stats.cpuPercent)
            let heat = stats.thermalArabic

            draw(hzText, x: 18, y: 18, size: 28, color: color(forHz: stats.gameHz), weight: .bold)
            draw(cpu, x: 150, y: 20, size: 24, color: color(forLoad: stats.cpuPercent), weight: .semibold)
            draw(heat, x: 250, y: 20, size: 24, color: color(forThermal: stats.thermal), weight: .semibold)
            draw("sonic", x: 420, y: 24, size: 16, color: UIColor(white: 1, alpha: 0.45), weight: .medium)
        }
    }

    private static func draw(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: UIColor, weight: UIFont.Weight) {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [
            .font: font,
            .foregroundColor: color
        ])
    }

    private static func color(forHz hz: Int) -> UIColor {
        if hz <= 0 { return UIColor(white: 1, alpha: 0.55) }
        if hz >= 110 { return UIColor(red: 0.35, green: 0.95, blue: 0.55, alpha: 1) }
        if hz >= 80 { return UIColor(red: 1, green: 0.82, blue: 0.28, alpha: 1) }
        return UIColor(red: 1, green: 0.38, blue: 0.38, alpha: 1)
    }

    private static func color(forLoad load: Double) -> UIColor {
        if load < 55 { return UIColor(red: 0.35, green: 0.95, blue: 0.55, alpha: 1) }
        if load < 80 { return UIColor(red: 1, green: 0.82, blue: 0.28, alpha: 1) }
        return UIColor(red: 1, green: 0.38, blue: 0.38, alpha: 1)
    }

    private static func color(forThermal thermal: ProcessInfo.ThermalState) -> UIColor {
        switch thermal {
        case .nominal: return UIColor(red: 0.35, green: 0.95, blue: 0.55, alpha: 1)
        case .fair: return UIColor(red: 1, green: 0.82, blue: 0.28, alpha: 1)
        default: return UIColor(red: 1, green: 0.38, blue: 0.38, alpha: 1)
        }
    }
}
