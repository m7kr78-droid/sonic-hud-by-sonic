import UIKit

enum HUDCanvas {
    static let width = 800
    static let height = 220

    static func image(stats: DeviceStats) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let cg = ctx.cgContext
            let bg = UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 0.88)
            cg.setFillColor(bg.cgColor)
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), cornerRadius: 28)
            path.fill()

            let hz = "\(stats.screenHz) Hz"
            let cpu = String(format: "استخدام %.0f%%  RAM %.0f%%", stats.cpuPercent, stats.ramPercent)
            let heat = "حرارة \(stats.thermalArabic)"

            let hzColor = color(forHz: stats.screenHz)
            let useColor = color(forLoad: stats.cpuPercent)
            let heatColor = color(forThermal: stats.thermal)

            draw(hz, x: 40, y: 38, size: 52, color: hzColor, weight: .bold)
            draw(cpu, x: 40, y: 108, size: 34, color: useColor, weight: .semibold)
            draw(heat, x: 430, y: 108, size: 34, color: heatColor, weight: .semibold)
            draw("sonic hud  ·  by sonic", x: 40, y: 164, size: 20, color: UIColor(white: 0.7, alpha: 1), weight: .regular)
        }
    }

    private static func draw(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, color: UIColor, weight: UIFont.Weight) {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }

    private static func color(forHz hz: Int) -> UIColor {
        hz >= 120 ? UIColor(red: 0.35, green: 0.95, blue: 0.55, alpha: 1) : UIColor(red: 1, green: 0.82, blue: 0.28, alpha: 1)
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
