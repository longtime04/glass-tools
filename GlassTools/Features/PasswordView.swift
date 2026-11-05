import SwiftUI

/// 随机密码：长度、字符种类可调，一键复制。
struct PasswordView: View {
    @State private var length = 16.0
    @State private var useLetters = true
    @State private var useDigits = true
    @State private var useSymbols = true
    @State private var password = ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("生成的密码")
                                    .font(.headline)
                                Text(password.isEmpty ? "点下面生成一个" : password)
                                    .font(.system(.title3, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                HStack(spacing: 12) {
                                    Button("生成") {
                                        password = generate()
                                        copied = false
                                    }
                                    .buttonStyle(.glassProminent)
                                    .disabled(!useLetters && !useDigits && !useSymbols)
                                    Button("复制") {
                                        guard !password.isEmpty else { return }
                                        UIPasteboard.general.string = password
                                        copied = true
                                    }
                                    .buttonStyle(.glass)
                                    .disabled(password.isEmpty)
                                    if copied {
                                        Text("已复制")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("长度")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(length)) 位")
                                        .font(.headline.monospacedDigit())
                                }
                                Slider(value: $length, in: 8...32, step: 1)
                                Toggle("字母（去掉容易认错的 l、O、0）", isOn: $useLetters)
                                Toggle("数字", isOn: $useDigits)
                                Toggle("符号 !@#$%^&*?", isOn: $useSymbols)
                            }
                        }

                        Text("密码只在手机本地生成，不联网、不保存，复制完就忘。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
            .navigationTitle("密码")
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if password.isEmpty {
                    password = generate()
                }
            }
        }
    }

    private func generate() -> String {
        var chars = ""
        if useLetters { chars += "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ" }
        if useDigits { chars += "23456789" }
        if useSymbols { chars += "!@#$%^&*?" }
        guard !chars.isEmpty else { return "" }
        return String((0..<Int(length)).map { _ in chars.randomElement()! })
    }
}
