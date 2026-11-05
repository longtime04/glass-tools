import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("二维码", systemImage: "qrcode") {
                QRGenerateView()
            }
            Tab("扫码", systemImage: "barcode.viewfinder") {
                QRScanView()
            }
            Tab("换算", systemImage: "arrow.left.arrow.right") {
                ConverterView()
            }
            Tab("密码", systemImage: "key.fill") {
                PasswordView()
            }
        }
        .tint(.white)
    }
}
