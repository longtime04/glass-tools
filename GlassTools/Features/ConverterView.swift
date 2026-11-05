import SwiftUI

/// 单位换算：长度 / 重量 / 温度 / 数据大小，离线可用。
struct ConverterView: View {
    enum Category: String, CaseIterable, Identifiable {
        case length = "长度"
        case weight = "重量"
        case temperature = "温度"
        case data = "数据"
        var id: String { rawValue }
    }

    @State private var category: Category = .length
    @State private var amountText = "1"
    @State private var fromIndex = 0
    @State private var toIndex = 1

    private var units: [String] {
        switch category {
        case .length: ["米", "千米", "厘米", "毫米", "英里", "英尺", "英寸"]
        case .weight: ["千克", "克", "斤", "磅", "盎司"]
        case .temperature: ["摄氏度", "华氏度", "开尔文"]
        case .data: ["GB", "MB", "KB", "字节"]
        }
    }

    private var resultText: String {
        guard let value = Double(amountText) else { return "输入数字才能换算" }
        let from = units[safe: fromIndex] ?? units[0]
        let to = units[safe: toIndex] ?? units[1]
        let converted = convert(value, from: from, to: to)
        return String(format: "%g %@ = %@ %@", value, from, formatNumber(converted), to)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        Picker("类别", selection: $category) {
                            ForEach(Category.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: category) {
                            fromIndex = 0
                            toIndex = min(1, units.count - 1)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("数值")
                                    .font(.headline)
                                TextField("输入数字", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.title2.monospacedDigit())
                                    .padding(10)
                                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("从")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Picker("从", selection: $fromIndex) {
                                            ForEach(units.indices, id: \.self) { i in
                                                Text(units[i]).tag(i)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    Button {
                                        swap(&fromIndex, &toIndex)
                                    } label: {
                                        Image(systemName: "arrow.left.arrow.right")
                                    }
                                    .buttonStyle(.glass)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("到")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Picker("到", selection: $toIndex) {
                                            ForEach(units.indices, id: \.self) { i in
                                                Text(units[i]).tag(i)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            Text(resultText)
                                .font(.title3.monospacedDigit())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("换算用的是系统标准单位，斤按 500 克算。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
            .navigationTitle("换算")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1_000_000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.4g", value)
    }

    /// 先统一换算成基准单位（米 / 千克 / 摄氏度 / 字节），再换到目标单位。
    private func convert(_ value: Double, from: String, to: String) -> Double {
        let base: Double
        switch category {
        case .length:
            base = value * ["米": 1, "千米": 1_000, "厘米": 0.01, "毫米": 0.001,
                            "英里": 1_609.344, "英尺": 0.3048, "英寸": 0.0254][from, default: 1]
            return base / ["米": 1, "千米": 1_000, "厘米": 0.01, "毫米": 0.001,
                          "英里": 1_609.344, "英尺": 0.3048, "英寸": 0.0254][to, default: 1]
        case .weight:
            base = value * ["千克": 1, "克": 0.001, "斤": 0.5,
                            "磅": 0.45359237, "盎司": 0.028349523125][from, default: 1]
            return base / ["千克": 1, "克": 0.001, "斤": 0.5,
                          "磅": 0.45359237, "盎司": 0.028349523125][to, default: 1]
        case .temperature:
            switch from {
            case "摄氏度": base = value
            case "华氏度": base = (value - 32) * 5 / 9
            default: base = value - 273.15
            }
            switch to {
            case "摄氏度": return base
            case "华氏度": return base * 9 / 5 + 32
            default: return base + 273.15
            }
        case .data:
            base = value * ["GB": 1_073_741_824, "MB": 1_048_576, "KB": 1_024, "字节": 1][from, default: 1]
            return base / ["GB": 1_073_741_824, "MB": 1_048_576, "KB": 1_024, "字节": 1][to, default: 1]
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
