import AVFoundation
import SwiftUI

/// 扫码：相机识别二维码 / 条形码，显示结果，可复制或打开链接。
struct QRScanView: View {
    @State private var result: String?
    @State private var permissionDenied = false
    @State private var scanID = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        if let result {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("扫到啦")
                                        .font(.headline)
                                    Text(result)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack(spacing: 12) {
                                        Button("复制") {
                                            UIPasteboard.general.string = result
                                        }
                                        .buttonStyle(.glass)
                                        if let url = URL(string: result),
                                           url.scheme == "http" || url.scheme == "https" {
                                            Link("打开链接", destination: url)
                                                .buttonStyle(.glass)
                                        }
                                        Button("再扫一个") {
                                            self.result = nil
                                            scanID = UUID()
                                        }
                                        .buttonStyle(.glassProminent)
                                    }
                                }
                            }
                        } else if permissionDenied {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Text("相机没打开")
                                        .font(.headline)
                                    Text("扫码需要相机权限，去设置里打开“相机”再回来。")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Button("去设置打开") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.glassProminent)
                                }
                            }
                        } else {
                            ScannerView(
                                onFound: { code in result = code },
                                onDenied: { permissionDenied = true }
                            )
                            .id(scanID)
                            .frame(height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.5), lineWidth: 1)
                            )
                            Text("把二维码放进框里就行，支持二维码和常见条形码。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("扫码")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

/// 相机扫码的 UIKit 桥接：AVCaptureSession + 元数据输出。
private struct ScannerView: UIViewControllerRepresentable {
    var onFound: (String) -> Void
    var onDenied: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        ScannerViewController(onFound: onFound, onDenied: onDenied)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

private final class ScannerViewController: UIViewController {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.long.glasstools.camera", qos: .userInitiated)
    private var sessionConfigured = false
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let onFound: (String) -> Void
    private let onDenied: () -> Void
    private let metadataDelegate = MetadataDelegate()

    init(onFound: @escaping (String) -> Void, onDenied: @escaping () -> Void) {
        self.onFound = onFound
        self.onDenied = onDenied
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) 不可用")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 来电、锁屏等打断相机后，系统恢复时把会话重新跑起来。
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded, object: session
        )
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.onDenied()
                    }
                }
            }
        default:
            onDenied()
        }
    }

    // 切到别的标签再回来、扫完一张再回来，相机都要重新跑起来；
    // 之前只在 viewWillDisappear 里停，没在回来时启动，画面就定在上一帧不动了。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartSessionIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restartSessionIfNeeded()
        if let layer = previewLayer {
            layer.frame = view.bounds
        }
    }

    @objc private func sessionInterruptionEnded() {
        restartSessionIfNeeded()
    }

    private func restartSessionIfNeeded() {
        guard sessionConfigured, !session.isRunning else { return }
        metadataDelegate.reset()
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        metadataDelegate.onFound = { [weak self] code in
            Task { @MainActor in self?.handleFound(code) }
        }
        output.setMetadataObjectsDelegate(metadataDelegate, queue: .main)
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .code39, .upce]
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        sessionConfigured = true
        // startRunning 会堵主线程，放后台队列跑，切换标签不卡。
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let session = self?.session, session.isRunning else { return }
            session.stopRunning()
        }
    }

    @MainActor private func handleFound(_ code: String) {
        sessionQueue.async { [weak self] in
            guard let session = self?.session, session.isRunning else { return }
            session.stopRunning()
        }
        onFound(code)
    }
}

/// 元数据输出回调：单独的 NSObject，不带 @MainActor，避免 Swift 6 并发检查报错。
/// 回调本身跑在 .main 队列（setMetadataObjectsDelegate 时指定），只做找码和转发。
private final class MetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onFound: ((String) -> Void)?
    private var didFind = false

    /// 回到扫码页时清掉“已扫到”标记，不然回来后扫不到第二张。
    func reset() {
        didFind = false
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didFind,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue
        else { return }
        didFind = true
        onFound?(code)
    }
}
