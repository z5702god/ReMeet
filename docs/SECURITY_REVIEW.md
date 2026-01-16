# Re:Meet 產品資安審查報告

**審查日期**: 2026-01-15  
**審查範圍**: 整體專案架構、iOS App、後端服務、資料庫設計  
**審查人員**: 產品資安人員

---

## 📊 執行摘要

Re:Meet 是一個商務名片管理 iOS 應用程式，整合了 Supabase 後端、Google Cloud Vision OCR、以及 n8n AI 聊天功能。整體而言，專案在基礎安全架構上做得不錯，但仍有若干需要改進的安全問題。

| 風險等級 | 問題數量 |
|---------|---------|
| 🔴 高風險 | 4 |
| 🟠 中風險 | 6 |
| 🟡 低風險 | 5 |

---

## 🔴 高風險問題

### 1. API Key 暴露在客戶端 (Google Cloud Vision)

**位置**: [BusinessCardScanner.swift](file:///Users/luke/Desktop/ReMeet/ios/ReMeet/ReMeet/Core/Services/BusinessCardScanner.swift#L19-L23)

**問題描述**:  
Google Cloud Vision API Key 直接在 iOS App 中使用，並透過 URL 參數傳送：

```swift
guard let url = URL(string: "\(visionAPIURL)?key=\(apiKey)") else {
    throw ScanError.invalidURL
}
```

**風險**:
- API Key 可被反編譯或透過網路抓包取得
- 攻擊者可濫用 API Key 進行大量 OCR 請求，產生高額帳單
- 無法有效限制 API 使用量

**建議**:
1. **將 OCR 處理移至後端** - 透過 n8n workflow 或專用 API 處理圖片辨識
2. **如必須在客戶端** - 使用 Google Cloud Identity Platform 或設定嚴格的 API 限制（如綁定 iOS Bundle ID）
3. 在 Google Cloud Console 設定 API Key 使用配額和 IP 限制

---

### 2. n8n Workflow SQL Injection 風險

**位置**: [remeet-ai-chat.json](file:///Users/luke/Desktop/ReMeet/n8n-workflows/remeet-ai-chat.json#L97)

**問題描述**:  
SQL 查詢使用字串拼接方式處理用戶輸入：

```sql
{{ $json.search_params.name ? "AND cd.full_name ILIKE '%" + $json.search_params.name + "%'" : '' }}
{{ $json.search_params.company ? "AND cd.company_name ILIKE '%" + $json.search_params.company + "%'" : '' }}
```

**風險**:
- SQL Injection 攻擊可能導致資料外洩
- 攻擊者可繞過 RLS 存取其他用戶資料
- 可能執行任意 SQL 命令

**建議**:
1. 使用參數化查詢（Parameterized Queries）
2. 對所有用戶輸入進行輸入驗證和轉義
3. 在 n8n 中使用 PostgreSQL node 的內建參數綁定功能

---

### 3. 帳戶刪除功能繞過 Auth 刪除

**位置**: [SupabaseClient.swift](file:///Users/luke/Desktop/ReMeet/ios/ReMeet/ReMeet/Core/Network/SupabaseClient.swift#L138-L193)

**問題描述**:  
`deleteUserAccount()` 函數刪除用戶資料後只執行 `signOut()`，但並未刪除 `auth.users` 中的帳戶：

```swift
// 5. Delete user record
try await client
    .from("users")
    .delete()
    .eq("id", value: userId.uuidString)
    .execute()

// 6. Sign out (this will trigger auth state change)
try await client.auth.signOut()
```

**風險**:
- 用戶帳戶在 `auth.users` 表中仍然存在
- 用戶可能使用相同 email 嘗試登入，造成混淆
- 不符合 GDPR「被遺忘權」要求

**建議**:
1. 使用 Supabase Admin API（透過後端）刪除 `auth.users` 記錄
2. 或設定 Supabase Edge Function 處理完整帳戶刪除流程
3. 在隱私政策中明確說明資料刪除流程

---

### 4. 文件說明中的 API Key 混淆

**位置**: [AUTHENTICATION_SETUP.md](file:///Users/luke/Desktop/ReMeet/AUTHENTICATION_SETUP.md#L288-L291)

**問題描述**:  
文件中對 Anon Key 和 Service Role Key 的說明完全相反：

```markdown
A:
- **Anon Key**: 繞過 RLS 的所有限制，可以存取所有資料，只能在後端使用
- **Service Role Key**: 受 RLS 保護，只能存取該用戶有權限的資料，可以放在前端
```

**風險**:
- 開發人員可能誤將 Service Role Key 放入 iOS App
- 導致嚴重的資料安全漏洞

**建議**:
修正為正確說明：
- **Anon Key**: 受 RLS 保護，可以放在前端
- **Service Role Key**: 繞過 RLS，只能在後端使用

---

## 🟠 中風險問題

### 5. 密碼強度驗證不完整

**位置**: [AuthViewModel.swift](file:///Users/luke/Desktop/ReMeet/ios/ReMeet/ReMeet/Features/Authentication/ViewModels/AuthViewModel.swift#L41-L49)

**問題描述**:  
目前的密碼驗證只檢查長度、大小寫和數字，未檢查常見弱密碼：

```swift
var isPasswordValid: Bool {
    guard password.count >= 8 else { return false }
    let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
    let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
    return hasUppercase && hasLowercase && hasNumber
}
```

**風險**:
- 用戶可設定如 "Password1" 之類的弱密碼
- 容易被字典攻擊破解

**建議**:
1. 加入常見密碼黑名單檢查
2. 建議要求特殊字元
3. 使用 Supabase Auth 內建的密碼強度設定

---

### 6. 公司資料過度共享

**位置**: [supabase-schema.sql](file:///Users/luke/Desktop/ReMeet/supabase-schema.sql#L294-L312)

**問題描述**:  
`companies` 表的 RLS Policy 允許所有已認證用戶查看、新增和修改公司資料：

```sql
CREATE POLICY "Authenticated users can view companies"
    ON public.companies FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can update companies"
    ON public.companies FOR UPDATE
    TO authenticated
    USING (true);
```

**風險**:
- 任何用戶可查看所有公司資料
- 任何用戶可修改任何公司資料
- 可能導致資料被惡意篡改

**建議**:
1. 考慮限制更新權限為公司建立者
2. 或使用審核機制來驗證公司資料變更
3. 增加 `created_by` 欄位追蹤建立者

---

### 7. Chat API 缺少認證

**位置**: [remeet-ai-chat.json](file:///Users/luke/Desktop/ReMeet/n8n-workflows/remeet-ai-chat.json#L1-L20)

**問題描述**:  
n8n Webhook 沒有設定認證機制，只依賴 `user_id` 參數：

```json
{
  "httpMethod": "POST",
  "path": "api/chat",
  "responseMode": "responseNode"
}
```

**風險**:
- 攻擊者可偽造 `user_id` 查詢其他用戶資料
- 可能被用於枚舉攻擊
- 無法驗證請求來源

**建議**:
1. 在 iOS App 傳送 Supabase JWT Token
2. 在 n8n 中驗證 JWT Token 的有效性
3. 從 Token 中提取 `user_id` 而非信任客戶端傳入的值

---

### 8. 錯誤訊息洩漏資訊

**位置**: 多處

**問題描述**:  
錯誤訊息直接顯示 `error.localizedDescription`，可能洩漏系統內部資訊：

```swift
showError(message: "Login failed: \(error.localizedDescription)")
```

**風險**:
- 可能洩漏資料庫結構、API 端點等資訊
- 有助於攻擊者進行進一步攻擊

**建議**:
1. 對用戶顯示友善的通用錯誤訊息
2. 將詳細錯誤記錄到日誌系統（如 Sentry）
3. 區分開發和生產環境的錯誤處理

---

### 9. Storage Bucket 可能的 Path Traversal

**位置**: [storage-policies.sql](file:///Users/luke/Desktop/ReMeet/storage-policies.sql#L13-L16)

**問題描述**:  
Storage Policy 依賴資料夾名稱來驗證權限：

```sql
WITH CHECK (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

**風險**:
- 如果 `storage.foldername` 函數未正確處理特殊字元
- 可能存在 Path Traversal 風險

**建議**:
1. 確認 Supabase Storage 已正確處理路徑驗證
2. 在應用層也進行路徑驗證
3. 定期測試存取控制

---

### 10. Helper Functions 使用 SECURITY DEFINER

**位置**: [supabase-schema.sql](file:///Users/luke/Desktop/ReMeet/supabase-schema.sql#L410-L510)

**問題描述**:  
所有 Helper Functions 使用 `SECURITY DEFINER`：

```sql
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**風險**:
- 函數以建立者權限執行，可能繞過 RLS
- 如果函數有漏洞，可能影響所有資料

**建議**:
1. 評估是否所有函數都需要 `SECURITY DEFINER`
2. 確保函數內部實作了適當的權限檢查
3. 使用 `SET search_path` 防止 Schema 注入

---

## 🟡 低風險問題

### 11. 缺少 Rate Limiting

**問題描述**:  
App 未實作 Rate Limiting，可能導致暴力破解攻擊。

**建議**:
1. 在 Supabase Auth 設定登入嘗試限制
2. 在 n8n Webhook 加入速率限制

---

### 12. 圖片未加密儲存

**問題描述**:  
商務名片圖片儲存於 Supabase Storage，使用 Public URL。

**建議**:
1. 使用 Signed URLs 取代 Public URLs
2. 設定 URL 過期時間

---

### 13. 缺少 Certificate Pinning

**問題描述**:  
iOS App 未實作 SSL Certificate Pinning。

**建議**:
實作 Certificate Pinning 以防止中間人攻擊。

---

### 14. 缺少安全日誌記錄

**問題描述**:  
專案沒有集中的安全日誌記錄機制。

**建議**:
1. 記錄登入嘗試、權限變更等安全事件
2. 使用 Supabase Edge Functions 記錄異常行為

---

### 15. 隱私政策缺少第三方服務說明

**位置**: [privacy-policy.html](file:///Users/luke/Desktop/ReMeet/docs/privacy-policy.html)

**問題描述**:  
隱私政策未提及使用的第三方服務：
- Google Cloud Vision API
- OpenAI API（透過 n8n）

**建議**:
1. 明確列出所有第三方資料處理者
2. 說明資料如何被這些服務處理

---

## ✅ 做得好的地方

1. **Row Level Security (RLS)** - 大部分表格都正確實作了 RLS
2. **Config.xcconfig 使用** - API Keys 透過 xcconfig 管理，不會進入版控
3. **.gitignore 完整** - 敏感文件已正確排除
4. **密碼基本驗證** - 有基本的密碼強度要求
5. **帳戶刪除功能** - 提供用戶刪除資料的選項（雖然實作不完整）
6. **隱私政策存在** - 有基本的隱私政策文件

---

## 🔧 優先修復建議

### 立即處理（P0）
1. 修正 AUTHENTICATION_SETUP.md 中 API Key 說明的錯誤
2. 修復 n8n 中的 SQL Injection 漏洞
3. 為 Chat API 加入 JWT 認證

### 短期處理（P1）
4. 將 Google Vision API 調用移至後端
5. 完善帳戶刪除流程，包含 auth.users 刪除
6. 修改 companies 表的 RLS Policy

### 中期處理（P2）
7. 實作 Rate Limiting
8. 加入安全日誌記錄
9. 使用 Signed URLs for Storage
10. 更新隱私政策

---

## 📝 後續步驟

1. [ ] 召開安全修復會議討論優先順序
2. [ ] 建立安全修復 Sprint
3. [ ] 進行滲透測試確認修復效果
4. [ ] 建立安全審查定期流程

---

*本報告由產品資安人員撰寫，建議在發布前完成高風險問題的修復。*
