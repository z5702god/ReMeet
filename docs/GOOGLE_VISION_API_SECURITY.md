# Google Cloud Vision API 安全設定指南

## 問題背景

目前 Re:Meet App 直接在 iOS 客戶端調用 Google Cloud Vision API 進行 OCR 辨識。這種做法存在以下風險：

1. **API Key 暴露**: iOS App 可被反編譯，API Key 可能被取得
2. **濫用風險**: 攻擊者可使用取得的 API Key 進行大量請求
3. **帳單風險**: 可能產生非預期的高額帳單

## 短期解決方案：API 限制設定

在 Google Cloud Console 設定 API Key 限制：

### 步驟 1: 進入 Google Cloud Console

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 選擇專案
3. 導航到 **APIs & Services > Credentials**

### 步驟 2: 設定 API Key 限制

點擊您的 API Key，設定以下限制：

#### 應用程式限制 (Application Restrictions)

選擇 **iOS apps** 並添加您的 Bundle ID：
```
com.remeet.app  (或您實際的 Bundle ID)
```

#### API 限制 (API Restrictions)

選擇 **Restrict key**，只允許以下 API：
- Cloud Vision API

#### 配額限制 (Quotas)

1. 導航到 **APIs & Services > Cloud Vision API > Quotas**
2. 設定每日請求限制（建議: 1000 requests/day）
3. 設定每分鐘請求限制（建議: 60 requests/minute）

### 步驟 3: 設定帳單警報

1. 導航到 **Billing > Budgets & alerts**
2. 建立預算，例如 $10/month
3. 設定 50%, 90%, 100% 的警報通知

## 長期解決方案：移至後端處理

建議將 OCR 處理移至後端以提高安全性：

### 方案 A: 使用 Supabase Edge Function

```typescript
// supabase/functions/ocr-scan/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // 1. 驗證用戶 JWT
  const authHeader = req.headers.get('Authorization')
  // ... 驗證邏輯

  // 2. 接收圖片
  const { image_base64 } = await req.json()

  // 3. 調用 Google Vision API (使用環境變數中的 API Key)
  const apiKey = Deno.env.get('GOOGLE_CLOUD_VISION_API_KEY')

  // 4. 返回 OCR 結果
  // ...
})
```

### 方案 B: 使用 n8n Workflow

建立新的 n8n Workflow 處理 OCR：

1. Webhook 接收圖片
2. 驗證 JWT Token
3. 調用 Google Vision API
4. 返回解析結果

### 方案 C: 使用 iOS 內建 Vision Framework

完全不使用 Google Cloud Vision，改用 Apple 的 Vision Framework：

```swift
import Vision

func performLocalOCR(image: UIImage) async throws -> String {
    guard let cgImage = image.cgImage else {
        throw NSError(domain: "OCR", code: 0)
    }

    return await withCheckedContinuation { continuation in
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                continuation.resume(returning: "")
                return
            }

            let text = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: "\n")

            continuation.resume(returning: text)
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en"]

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
}
```

**優點**:
- 無 API 費用
- 離線可用
- 無安全風險

**缺點**:
- 辨識準確度可能略低於 Google Vision
- 不支援某些特殊格式

## 實施優先順序

| 優先順序 | 方案 | 複雜度 | 安全性提升 |
|---------|------|--------|-----------|
| 1 | API Key 限制 + 配額 | 低 | 中 |
| 2 | iOS Vision Framework | 中 | 高 |
| 3 | Edge Function | 高 | 高 |

## 當前狀態

- [x] API Key 已移至 Config.xcconfig（不進入版控）
- [ ] Google Cloud Console API 限制設定
- [ ] 配額限制設定
- [ ] 帳單警報設定
- [ ] 考慮移至後端或使用本地 OCR

## 參考資源

- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Cloud Vision API Quotas](https://cloud.google.com/vision/quotas)
- [Apple Vision Framework Documentation](https://developer.apple.com/documentation/vision)

---

*最後更新: 2026-01-15*
