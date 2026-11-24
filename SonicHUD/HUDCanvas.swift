import UIKit

enum HUDCanvas {
    static let width = 168
    static let height = 24

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
            let bg = UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 0.12)
            cg.setFillColor(bg.cgColor)
            UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 2), cornerRadius: 7).fill()

            let hzText = stats.gameHz > 0 ? "\(stats.gameHz)Hz" : "--Hz"
            let cpu = String(format: "%.0f%%", stats.cpuPercent)
            let heat = stats.thermalArabic

            draw(hzText, x: 8, y: 4, size: 13, color: color(forHz: stats.gameHz), weight: .bold)
            draw(cpu, x: 68, y: 4, size: 12, color: color(forLoad: stats.cpuPercent), weight: .semibold)
            draw(heat, x: 110, y: 4, size: 12, color: color(forThermal: stats.thermal), weight: .semibold)
        }
    }

    private static func draw(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: UIColor, weight: UIFont.Weight) {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(white: 0, alpha: 0.75)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        shadow.shadowBlurRadius = 2
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [
            .font: font,
            .foregroundColor: color,
            .shadow: shadow
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
