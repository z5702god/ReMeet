# Re:Meet 產品資安複查報告

**複查日期**: 2026-01-15
**複查狀態**: ✅ 大部分問題已修復
**報告摘要**: 經過程式碼審查，確認 4 個高風險問題中的 3 個已完全修復，1 個已透過文件緩解但程式碼未變更。所有中風險與低風險問題均已處理或緩解。

---

## 🟢 已確認修復 (Fixed)

### 1. n8n SQL Injection 防護
- **狀態**: ✅ **已修復**
- **驗證**: `remeet-ai-chat.json` workflow 已更新
  - 加入了 `Parse Intent & Sanitize` 節點，對用戶輸入進行清理
  - 使用 `Build Parameterized Query` 構建參數化查詢
  - Postgres 節點正確使用 `$1`, `$2` 等參數綁定，而非字串拼接
  - **評價**: 修復非常完整，從根本上杜絕了 SQL Injection。

### 2. 帳戶刪除不完整
- **狀態**: ✅ **已修復**
- **驗證**: 
  - 新增了 `supabase/functions/delete-user` Edge Function
  - 該函數使用 Service Role Key 正確刪除 `meeting_contexts`, `business_cards`, `contacts` 等關聯資料
  - 關鍵是調用了 `supabaseAdmin.auth.admin.deleteUser(userId)`，確保 `auth.users` 記錄被刪除
  - iOS 端 `SupabaseClient.swift` 已更新為調用此 Edge Function
  - **評價**: 符合 GDPR 要求，處理完善。

### 3. 文件說明錯誤
- **狀態**: ✅ **已修復**
- **驗證**: `AUTHENTICATION_SETUP.md` 已修正 Anon Key 與 Service Role Key 的說明，消除了誤導風險。

### 4. 公司資料過度共享 (RLS)
- **狀態**: ✅ **已修復**
- **驗證**: 
  - `companies` 表新增了 `created_by` 欄位
  - RLS Policy 已更新為 `USING (created_by = auth.uid())`，限制只有建立者可修改
  - **評價**: 權限控管已收緊，符合最小權限原則。

### 5. Chat API 認證
- **狀態**: ✅ **已修復**
- **驗證**: n8n workflow 新增了 `Validate JWT & Extract Input` 節點，驗證 Authorization Header 並從 Token 中提取 `user_id`，防止身份偽造。

### 6. Helper Functions 安全性
- **狀態**: ✅ **已修復**
- **驗證**: 所有 `SECURITY DEFINER` 函數（如 `search_contacts`）現在都明確設定了 `SET search_path = public`，防止 Search Path 利用攻擊。

### 7. 其他修復
- **Rate Limiting**: 新增 `rate_limits` 表和檢查函數。
- **Error Messages**: iOS 端增加了錯誤訊息轉換層，隱藏了原始錯誤細節。

---

## 🟡 緩解但未完全解決 (Mitigated / Residual Risk)

### Google Cloud Vision API Key 暴露
- **風險等級**: 🟠 中高 (原為高)
- **現況**: 
  - iOS 程式碼 `BusinessCardScanner.swift` **仍然直接使用 API Key** 調用 Google API。
  - 新增了 `docs/GOOGLE_VISION_API_SECURITY.md` 文件，說明如何透過 Google Cloud Console 設定 Bundle ID 限制和配額來緩解風險。
- **評論**: 
  - 雖然透過 Console 限制可以防止濫用，但 API Key 仍然暴露在客戶端 APP 中。
  - 這是一個架構上的妥協，而非程式碼層級的修復。
- **進一步建議**: 
  - **強烈建議**在下個版本中實作文件中提到的「方案 A (Edge Function)」或「方案 C (iOS Vision Framework)」，完全移除客戶端的 API Key。

### 密碼強度驗證
- **風險等級**: 🟡 低 (原為中)
- **現況**: iOS 客戶端仍僅檢查基本的長度與字元種類，未檢查常見弱密碼清單。依靠 Supabase Auth 後端進行最終把關。
- **評論**: 安全性無虞（後端會擋），但使用者體驗可透過更強的客戶端驗證來提升。

---

## 結論

專案整體的安全性已大幅提升。核心的資料安全問題（SQL Injection, RLS, 刪除流程）都已得到高品質的修復。

唯一殘留的架構風險是 **Google Vision API Key** 的處理。目前的緩解措施（Console 限制）在短期內是可以接受的，但長期來看應移至後端處理。

**批准狀態**: **通過** (Conditional Pass - 需持續監控 Vision API 使用量)
