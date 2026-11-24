import ReplayKit
import UIKit
import SwiftUI

final class BroadcastStarter: NSObject {
    static let shared = BroadcastStarter()
    private weak var picker: RPSystemBroadcastPickerView?

    func bind(_ picker: RPSystemBroadcastPickerView) {
        self.picker = picker
        style(picker)
    }

    func askToStart() {
        guard let picker else { return }
        tap(picker)
    }

    func stop() {
        GameHzBus.publish(0)
    }

    static func extensionId() -> String {
        if let dir = Bundle.main.builtInPlugInsURL,
           let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for url in urls where url.pathExtension == "appex" {
                if let id = Bundle(url: url)?.bundleIdentifier, !id.isEmpty {
                    return id
                }
            }
        }
        return "com.by.sonic.gamehud.broadcast"
    }

    fileprivate func style(_ picker: RPSystemBroadcastPickerView) {
        picker.preferredExtension = Self.extensionId()
        picker.showsMicrophoneButton = false
        picker.backgroundColor = .clear
        let tint = UIColor(red: 0.18, green: 0.72, blue: 0.42, alpha: 1)
        picker.tintColor = tint
        for view in picker.subviews {
            view.tintColor = tint
            if let button = view as? UIButton {
                button.tintColor = tint
                button.imageView?.tintColor = tint
            }
        }
    }

    fileprivate func tap(_ picker: RPSystemBroadcastPickerView) {
        func buttons(in view: UIView) -> [UIButton] {
            var found = [UIButton]()
            if let button = view as? UIButton { found.append(button) }
            for child in view.subviews { found.append(contentsOf: buttons(in: child)) }
            return found
        }
        for button in buttons(in: picker) {
            button.sendActions(for: .touchUpInside)
        }
    }
}

struct BroadcastPickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        BroadcastStarter.shared.bind(picker)
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        BroadcastStarter.shared.bind(uiView)
    }
}
