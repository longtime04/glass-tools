# 璃光工具箱 GlassTools

iPhone / iPad 实用小工具合集，iOS 26 液态玻璃（Liquid Glass）界面。

## 功能

- **二维码**：生成文本 / 链接 / WiFi 二维码，可保存到相册、分享。WiFi 码用相机一扫就能连网，适合贴在店里。
- **扫码**：相机识别二维码和常见条形码，扫到后可复制、打开链接。
- **换算**：长度 / 重量 / 温度 / 数据大小，离线可用。
- **密码**：随机生成强密码，长度和字符种类可调，一键复制。

全部功能离线可用，不联网、不收集任何数据。

## 系统要求

- iOS 26 / iPadOS 26 及以上（液态玻璃效果需要 iOS 26；更低系统装不上）。

## 自己编译

```bash
xcodebuild archive \
  -project GlassTools.xcodeproj \
  -scheme GlassTools \
  -destination 'generic/platform=iOS' \
  -archivePath build/GlassTools.xcarchive \
  CODE_SIGNING_ALLOWED=NO
mkdir -p Payload
cp -r build/GlassTools.xcarchive/Products/Applications/GlassTools.app Payload/
zip -r GlassTools-1.0.0-unsigned.ipa Payload
```

也可以直接用仓库里的 GitHub Actions：每次推到 `main` 就会在云端 Mac 上自动编出未签名的 IPA，见 Actions 页面。

## 安装

这是未签名的 IPA，需要用自己的企业证书（或 AltStore / SideStore 等侧载工具）签名后安装。企业证书随时可能被苹果吊销，吊销后须等新证书重装。

## 署名

全程由 Muse 制作。
