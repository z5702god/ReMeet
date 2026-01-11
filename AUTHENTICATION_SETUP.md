# Re:Meet - Authentication 設定指南

完整的 Apple Sign In 和 Email 認證設定步驟。

---

## 📋 目錄

1. [檢查 Email Authentication](#1-檢查-email-authentication)
2. [設定 Apple Sign In](#2-設定-apple-sign-in)
3. [設定 Redirect URLs](#3-設定-redirect-urls)
4. [取得 API Keys](#4-取得-api-keys)
5. [測試認證](#5-測試認證)

---

## 1. 檢查 Email Authentication

Email 認證在 Supabase 預設是啟用的，我們只需要確認設定。

### 步驟 1.1: 檢查設定

1. 在 Supabase Dashboard，點擊 **Authentication** → **Providers**
2. 找到 **Email** provider
3. 確認以下設定：

```
✅ Enable Email provider
✅ Confirm email (建議開啟 - 用戶需要驗證 email)
✅ Enable email confirmations
✅ Secure email change (建議開啟)
```

### 步驟 1.2: 自訂 Email Templates（選用）

如果你想自訂驗證信件的樣式：

1. 點擊 **Authentication** → **Email Templates**
2. 可以自訂以下模板：
   - **Confirm signup** - 註冊驗證信
   - **Magic Link** - 免密碼登入
   - **Change Email Address** - 更改 email 確認
   - **Reset Password** - 重設密碼

---

## 2. 設定 Apple Sign In

Apple Sign In 對 iOS app 來說是必須的（如果提供第三方登入）。

### 步驟 2.1: 前置準備

你需要：
- ✅ Apple Developer 帳號（需付費 $99/年）
- ✅ 已註冊的 App ID

### 步驟 2.2: 在 Apple Developer Console 建立 Services ID

1. 前往 [Apple Developer Console](https://developer.apple.com/account/resources/identifiers/list/serviceId)
2. 點擊 **+** 建立新的 Identifier
3. 選擇 **Services IDs**，點擊 **Continue**

4. 填寫資訊：
   ```
   Description: Re:Meet Sign In
   Identifier: com.remeet.signin (或你自己的 identifier)
   ```

5. 點擊 **Continue**，然後 **Register**

### 步驟 2.3: 設定 Sign In with Apple

1. 在剛建立的 Services ID 中，勾選 **Sign In with Apple**
2. 點擊 **Configure**

3. 在設定頁面：
   - **Primary App ID**: 選擇你的 iOS App ID
   - **Domains and Subdomains**: 添加你的 Supabase domain
     ```
     [your-project-ref].supabase.co
     ```
   - **Return URLs**: 添加 Supabase callback URL
     ```
     https://[your-project-ref].supabase.co/auth/v1/callback
     ```

4. 點擊 **Save**，然後 **Continue**，最後 **Done**

### 步驟 2.4: 建立 Apple Sign In Key

1. 在左側選單選擇 **Keys**
2. 點擊 **+** 建立新的 Key
3. 填寫：
   ```
   Key Name: Re:Meet Sign In Key
   ✅ 勾選 Sign In with Apple
   ```
4. 點擊 **Configure**，選擇你的 Primary App ID
5. 點擊 **Save**，然後 **Continue**，最後 **Register**

6. **重要**: 下載 `.p8` 私鑰檔案
   - ⚠️ 這個檔案只能下載一次，請妥善保管
   - 記下 **Key ID**（10 位字元）

7. 記下你的 **Team ID**：
   - 在右上角點擊你的帳號
   - 或在 Membership 頁面找到

### 步驟 2.5: 在 Supabase 設定 Apple Provider

1. 回到 Supabase Dashboard
2. 點擊 **Authentication** → **Providers**
3. 找到 **Apple**，點擊啟用

4. 填入從 Apple Developer 取得的資訊：
   ```
   Services ID: com.remeet.signin (你的 Services ID)
   Team ID: ABC123DEF4 (你的 Team ID，10 位字元)
   Key ID: XYZ789ABC1 (你的 Key ID，10 位字元)
   Secret Key: -----BEGIN PRIVATE KEY-----
               [貼上 .p8 檔案的完整內容]
               -----END PRIVATE KEY-----
   ```

5. 點擊 **Save**

---

## 3. 設定 Redirect URLs

為了讓 iOS app 能正確處理認證回調，需要設定 custom URL scheme。

### 步驟 3.1: 設定 Redirect URLs

1. 在 Supabase Dashboard，點擊 **Authentication** → **URL Configuration**
2. 在 **Redirect URLs** 區域，添加以下 URLs：

```
remeet://auth-callback
com.remeet.app://auth-callback
```

> 注意：這些是範例 URL schemes，實際應該使用你的 iOS app 的 bundle identifier

### 步驟 3.2: iOS App 設定（稍後處理）

在 iOS app 中，你需要：
1. 在 `Info.plist` 添加 URL Types
2. 處理 URL scheme callback
3. 整合 Supabase Swift SDK

---

## 4. 取得 API Keys

### 步驟 4.1: 找到 API Settings

1. 點擊左側選單的 **Settings** (齒輪圖示)
2. 點擊 **API**

### 步驟 4.2: 複製必要資訊

你需要以下資訊來連接 iOS app 和 n8n：

```
📍 Project URL:
https://[your-project-ref].supabase.co

🔑 API Key (anon, public):
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
👉 這個可以安全地放在 iOS app 中

🔐 Service Role Key:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
⚠️ 這個只能用在後端（n8n），絕不要放在 iOS app
```

### 步驟 4.3: 儲存到安全的地方

建議建立一個 `.env` 檔案（**不要** commit 到 git）：

```bash
# .env (加到 .gitignore)

# Supabase 設定
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Apple Sign In (iOS app 使用)
APPLE_CLIENT_ID=com.remeet.signin
```

並在 `.gitignore` 添加：
```
.env
.env.local
```

---

## 5. 測試認證

### 測試 5.1: 測試 Email 註冊

1. 在 Supabase Dashboard，點擊 **Authentication** → **Users**
2. 點擊 **Add user** → **Create new user**
3. 填入測試 email 和密碼：
   ```
   Email: test@example.com
   Password: TestPassword123!
   ```
4. 取消勾選 "Send user a confirmation email"（測試用）
5. 點擊 **Create user**

### 測試 5.2: 檢查 Users Table

1. 前往 **SQL Editor**
2. 執行以下查詢：

```sql
-- 檢查 auth.users
SELECT id, email, created_at FROM auth.users;

-- 檢查 public.users（應該自動建立）
SELECT id, email, full_name, created_at FROM public.users;
```

如果看到兩個 tables 都有資料，表示 trigger 正常運作！✅

### 測試 5.3: 測試 RLS

```sql
-- 設定當前用戶上下文（模擬已登入用戶）
SET request.jwt.claims.sub = 'your-test-user-uuid';

-- 嘗試查詢 contacts（應該只看到該用戶的資料）
SELECT * FROM public.contacts;
```

---

## 6. 完成檢查清單

### Supabase 後端設定

- [x] 資料庫 Schema 建立完成
- [x] Storage bucket 設定完成
- [x] Storage policies 設定完成
- [ ] Email Authentication 確認啟用
- [ ] Apple Sign In 設定完成（需要 Apple Developer 帳號）
- [ ] Redirect URLs 設定完成
- [ ] API Keys 已複製並安全儲存
- [ ] 測試用戶建立成功
- [ ] RLS 測試通過

---

## 🎉 下一步

完成以上所有設定後，你的 Supabase 後端就完全準備好了！

接下來可以：

1. **開始開發 iOS App**
   - 整合 Supabase Swift SDK
   - 實作登入/註冊畫面
   - 測試認證流程

2. **或者先建立 n8n Workflows**
   - 設定 n8n 環境
   - 建立 OCR workflow
   - 連接 Supabase

---

## 🆘 常見問題

### Q: Apple Sign In 是必須的嗎？

A: 如果你的 iOS app 提供第三方登入（如 Google、Facebook），Apple 要求你也必須提供 Apple Sign In。如果只用 Email 登入，則不需要。

### Q: 測試階段可以跳過 Apple Sign In 嗎？

A: 可以！在開發初期可以只用 Email 認證，之後再補上 Apple Sign In。

### Q: Service Role Key 和 Anon Key 有什麼區別？

A:
- **Anon Key**: 繞過 RLS 的所有限制，可以存取所有資料，只能在後端使用
- **Service Role Key**: 受 RLS 保護，只能存取該用戶有權限的資料，可以放在前端

### Q: 為什麼我的測試用戶無法登入？

A: 檢查：
1. Email 是否已驗證（測試時可以在 Users table 手動驗證）
2. RLS policies 是否正確
3. API Key 是否正確

---

**最後更新**: 2026-01-10
**專案**: Re:Meet
