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

private final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let onFound: (String) -> Void
    private let onDenied: () -> Void
    private var didFind = false

    init(onFound: @escaping (String) -> Void, onDenied: @escaping (String) -> Void) {
        self.onFound = onFound
        self.onDenied = onDenied
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) 不可用")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .code39, .upce]
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
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
        session.stopRunning()
        onFound(code)
    }
}
