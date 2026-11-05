import CoreImage.CIFilterBuiltins
import SwiftUI

/// 二维码生成：文本 / 链接 / WiFi，可保存到相册、分享。
struct QRGenerateView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case text = "文本"
        case link = "链接"
        case wifi = "WiFi"
        var id: String { rawValue }
    }

    @State private var kind: Kind = .text
    @State private var text = ""
    @State private var urlText = "https://"
    @State private var ssid = ""
    @State private var wifiPassword = ""
    @State private var wifiSecurity = "WPA"
    @State private var qrImage: UIImage?
    @State private var savedMessage: String?

    private var payload: String {
        switch kind {
        case .text:
            text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .link:
            urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .wifi:
            "WIFI:T:\(wifiSecurity);S:\(ssid);P:\(wifiPassword);H:false;;"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        Picker("类型", selection: $kind) {
                            ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                switch kind {
                                case .text:
                                    Text("要编码的文字")
                                        .font(.headline)
                                    TextEditor(text: $text)
                                        .frame(minHeight: 90)
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                case .link:
                                    Text("链接地址")
                                        .font(.headline)
                                    TextField("https://…", text: $urlText)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .padding(10)
                                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                case .wifi:
                                    Text("WiFi 名称")
                                        .font(.headline)
                                    TextField("路由器名称", text: $ssid)
                                        .autocorrectionDisabled()
                                        .padding(10)
                                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                    Text("WiFi 密码")
                                        .font(.headline)
                                    SecureField("密码", text: $wifiPassword)
                                        .padding(10)
                                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                    Picker("加密方式", selection: $wifiSecurity) {
                                        Text("WPA/WPA2").tag("WPA")
                                        Text("WEP").tag("WEP")
                                        Text("无密码").tag("nopass")
                                    }
                                    .pickerStyle(.segmented)
                                }

                                Button("生成二维码") {
                                    qrImage = makeQRCode(from: payload)
                                    savedMessage = nil
                                }
                                .buttonStyle(.glassProminent)
                                .disabled(payload.isEmpty || (kind == .wifi && ssid.isEmpty))
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        if let qrImage {
                            GlassCard {
                                VStack(spacing: 14) {
                                    Image(uiImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 220, height: 220)
                                        .padding(12)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                                    HStack(spacing: 12) {
                                        Button("保存到相册") {
                                            UIImageWriteToSavedPhotosAlbum(
                                                qrImage, nil, nil, nil)
                                            savedMessage = "已保存到相册"
                                        }
                                        .buttonStyle(.glass)
                                        ShareLink("分享", item: Image(uiImage: qrImage),
                                                  preview: SharePreview("二维码"))
                                        .buttonStyle(.glass)
                                    }
                                    if let savedMessage {
                                        Text(savedMessage)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        Text("WiFi 二维码用手机相机一扫就能连网，适合贴在店里给顾客用。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
            .navigationTitle("二维码")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    /// 用 CoreImage 生成二维码，放大到 300 点宽，保证清晰可扫。
    private func makeQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8), !data.isEmpty else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = 300 / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
