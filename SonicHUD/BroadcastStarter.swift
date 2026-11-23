import ReplayKit
import UIKit

final class BroadcastStarter: NSObject, RPBroadcastActivityViewControllerDelegate {
    static let shared = BroadcastStarter()
    private var controller: RPBroadcastController?

    func askToStart() {
        guard let host = topController() else { return }
        RPBroadcastActivityViewController.load { [weak self] picker, _ in
            guard let self, let picker else { return }
            picker.delegate = self
            if let pop = picker.popoverPresentationController {
                pop.sourceView = host.view
                pop.sourceRect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
            }
            host.present(picker, animated: true)
        }
    }

    func stop() {
        controller?.finishBroadcast { _ in }
        controller = nil
        GameHzBus.publish(0)
    }

    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController, didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
        broadcastActivityViewController.dismiss(animated: true)
        guard let broadcastController, error == nil else { return }
        self.controller = broadcastController
        broadcastController.startBroadcast { _ in }
    }

    private func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var vc = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
