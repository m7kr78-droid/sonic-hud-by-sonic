import SwiftUI
import Combine

final class HUDModel: ObservableObject {
    @Published var stats = DeviceStats(
        gameHz: 0, cpuPercent: 0, ramPercent: 0,
        thermal: .nominal, batteryPercent: -1
    )
    @Published var pipOn = false
    private var timer: Timer?

    func start() {
        UIApplication.shared.isIdleTimerDisabled = true
        GameHzBus.startHost()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func tick() {
        stats = StatsMonitor.shared.snapshot()
        pipOn = PiPController.shared.isRunning
    }
}

struct ContentView: View {
    @StateObject private var model = HUDModel()

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("sonic hud")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text("by sonic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))

                HStack(spacing: 12) {
                    card("هيرتز اللعبة", model.stats.gameHz > 0 ? "\(model.stats.gameHz)" : "--", "Hz")
                    card("استخدام", String(format: "%.0f", model.stats.cpuPercent), "%")
                    card("حرارة", model.stats.thermalArabic, "")
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("الهيرتز يبقى -- لين يبدأ البث. شغّل العرض، بعدين من قائمة التسجيل اختر sonic hud. الشريط الأحمر لازم يبقى وأنت بلعبة.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.78))
                    Text("إذا طلعت صفحة Live Stream من آب ستور، ارجع واضغط الدائرة الخضراء. لا تختار شيء من المتجر.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(.horizontal, 22)

                Button(action: togglePiP) {
                    Text(model.pipOn ? "وقف العرض" : "شغّل فوق اللعبة")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(model.pipOn ? Color.red.opacity(0.85) : Color(red: 0.18, green: 0.72, blue: 0.42))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 22)

                HStack(spacing: 12) {
                    BroadcastPickerView()
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("هيرتز اللعبة")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text("اضغط الدائرة واختر sonic hud")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.55))
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 22)

                Spacer()
            }
            .padding(.top, 40)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .background(HostView().frame(width: 1, height: 1))
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func card(_ title: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.system(size: 14)).foregroundColor(Color.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text(unit).font(.system(size: 14)).foregroundColor(Color.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func togglePiP() {
        if PiPController.shared.isRunning {
            BroadcastStarter.shared.stop()
            PiPController.shared.stop()
        } else {
            PiPController.shared.start()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                BroadcastStarter.shared.askToStart()
            }
        }
        model.objectWillChange.send()
    }
}

private struct HostView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.isUserInteractionEnabled = false
        PiPController.shared.attach(to: v)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
