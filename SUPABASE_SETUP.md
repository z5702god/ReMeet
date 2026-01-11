# Re:Meet - Supabase 設定指南

本文件提供完整的 Supabase 設定步驟，包括資料庫、Storage、Authentication 配置。

---

## 📋 目錄

1. [執行 SQL Schema](#1-執行-sql-schema)
2. [設定 Storage](#2-設定-storage)
3. [設定 Authentication](#3-設定-authentication)
4. [取得 API 金鑰](#4-取得-api-金鑰)
5. [測試連線](#5-測試連線)

---

## 1. 執行 SQL Schema

### 步驟 1.1: 開啟 SQL Editor

1. 登入你的 Supabase Dashboard: https://app.supabase.com
2. 選擇你的專案 "Re:Meet"
3. 點擊左側選單的 **SQL Editor**
4. 點擊 **+ New Query**

### 步驟 1.2: 執行 Schema

1. 打開專案中的 `supabase-schema.sql` 檔案
2. 複製所有內容
3. 貼到 SQL Editor 中
4. 點擊 **Run** 或按 `Cmd/Ctrl + Enter`

### 步驟 1.3: 驗證執行結果

執行成功後，你應該會看到：
- ✅ Success 訊息
- 創建了 6 個 tables
- 設定了 Row Level Security
- 創建了多個 indexes 和 triggers

### 步驟 1.4: 檢查 Tables

1. 點擊左側選單的 **Table Editor**
2. 你應該看到以下 tables：
   - `users`
   - `companies`
   - `business_cards`
   - `contacts`
   - `meeting_contexts`
   - `chat_history`

---

## 2. 設定 Storage

### 步驟 2.1: 建立 Storage Bucket

1. 點擊左側選單的 **Storage**
2. 點擊 **New bucket**
3. 設定如下：

**Bucket 1: Business Card Images**
```
Name: business-cards
Public: ❌ (Private)
File size limit: 5 MB
Allowed MIME types: image/jpeg, image/png, image/heic
```

點擊 **Create bucket**

**Bucket 2: User Avatars (Optional)**
```
Name: avatars
Public: ✅ (Public)
File size limit: 2 MB
Allowed MIME types: image/jpeg, image/png
```

### 步驟 2.2: 設定 Storage Policies

#### 為 business-cards bucket 設定 RLS

1. 點擊 `business-cards` bucket
2. 點擊 **Policies** tab
3. 點擊 **New Policy**

**Policy 1: 用戶可以上傳自己的名片**
```sql
-- Policy name: Users can upload own business cards
-- Allowed operation: INSERT
-- Policy definition:

CREATE POLICY "Users can upload own business cards"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

**Policy 2: 用戶可以查看自己的名片**
```sql
-- Policy name: Users can view own business cards
-- Allowed operation: SELECT
-- Policy definition:

CREATE POLICY "Users can view own business cards"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

**Policy 3: 用戶可以刪除自己的名片**
```sql
-- Policy name: Users can delete own business cards
-- Allowed operation: DELETE
-- Policy definition:

CREATE POLICY "Users can delete own business cards"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 步驟 2.3: 檔案路徑結構

上傳的名片圖片應該遵循以下路徑結構：
```
business-cards/
  └── {user_id}/
      ├── {card_id}_front.jpg
      ├── {card_id}_back.jpg
      └── ...
```

範例：
```
business-cards/a1b2c3d4-e5f6-7890-abcd-ef1234567890/550e8400-e29b-41d4-a716-446655440000_front.jpg
```

---

## 3. 設定 Authentication

### 步驟 3.1: 啟用 Email Authentication

1. 點擊左側選單的 **Authentication** → **Providers**
2. 確認 **Email** provider 已啟用（預設啟用）
3. 設定：
   - ✅ Enable Email provider
   - ✅ Confirm email (建議開啟)
   - ✅ Enable email confirmations

### 步驟 3.2: 設定 Apple Sign In (iOS 必要)

1. 在 **Authentication** → **Providers** 頁面
2. 找到 **Apple** provider
3. 點擊 **Enable**

#### Apple Developer 設定（需要 Apple Developer 帳號）

1. 登入 [Apple Developer Console](https://developer.apple.com)
2. 建立 **Services ID**：
   - Identifier: `com.remeet.signin` (範例)
   - Description: Re:Meet Sign In
3. 設定 **Sign In with Apple**：
   - Primary App ID: 選擇你的 iOS app
   - Domains and Subdomains: 添加 Supabase 提供的 callback domain
   - Return URLs: 添加 Supabase callback URL

#### 在 Supabase 填入資訊

回到 Supabase Apple provider 設定：
```
Services ID: com.remeet.signin
Key ID: [從 Apple Developer 取得]
Team ID: [你的 Apple Team ID]
Private Key: [上傳 .p8 檔案]
```

**詳細教學**: https://supabase.com/docs/guides/auth/social-login/auth-apple

### 步驟 3.3: 設定 Auth Redirect URLs

1. 點擊 **Authentication** → **URL Configuration**
2. 在 **Redirect URLs** 添加：
   ```
   remeet://auth-callback
   com.remeet://auth-callback
   ```

### 步驟 3.4: Email Templates (Optional)

自訂驗證信件模板：
1. 點擊 **Authentication** → **Email Templates**
2. 可以自訂以下模板：
   - Confirmation email
   - Magic Link
   - Change Email
   - Reset Password

---

## 4. 取得 API 金鑰

### 步驟 4.1: 專案設定

1. 點擊左側選單的 **Settings** (齒輪圖示)
2. 點擊 **API**

### 步驟 4.2: 複製必要資訊

你需要以下資訊來連接 iOS app：

```
Project URL: https://[your-project-ref].supabase.co
API Key (anon, public): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

⚠️ Service Role Key: 僅用於後端 (n8n)，絕不要放在 iOS app
```

### 步驟 4.3: 儲存到環境變數

建議建立 `.env` 檔案（不要 commit 到 git）：

```bash
# .env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... # 僅用於後端
```

---

## 5. 測試連線

### 步驟 5.1: 使用 Supabase Dashboard 測試

#### 測試 1: 插入測試公司資料

1. 進入 **Table Editor**
2. 選擇 `companies` table
3. 點擊 **Insert row**
4. 填入：
   ```
   name: Test Company
   industry: Technology
   website: https://example.com
   ```
5. 點擊 **Save**

#### 測試 2: 使用 SQL Editor 查詢

```sql
-- 查詢所有公司
SELECT * FROM public.companies;

-- 測試搜尋功能（需要先有用戶資料）
-- SELECT * FROM search_contacts('test', 'your-user-uuid');
```

### 步驟 5.2: 使用 API 測試 (cURL)

#### 測試連線

```bash
curl 'https://your-project-ref.supabase.co/rest/v1/companies' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

應該返回你剛才插入的公司資料。

#### 測試 Storage

```bash
# 列出 buckets
curl 'https://your-project-ref.supabase.co/storage/v1/bucket' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### 步驟 5.3: 檢查 RLS

#### 驗證 RLS 已啟用

在 SQL Editor 執行：

```sql
-- 檢查所有 tables 的 RLS 狀態
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

所有 tables 的 `rowsecurity` 應該是 `true`。

#### 查看所有 Policies

```sql
-- 列出所有 RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## 6. 下一步

完成以上設定後，你已經準備好：

### ✅ 已完成
- [x] 資料庫 Schema 建立
- [x] Storage Buckets 設定
- [x] Authentication 配置
- [x] API 金鑰取得
- [x] 基本測試

### 🚀 接下來
- [ ] iOS App 整合 Supabase SDK
- [ ] 實作用戶註冊/登入流程
- [ ] 實作名片上傳功能
- [ ] 建立 n8n workflows

---

## 🔧 故障排除

### 問題 1: SQL Schema 執行失敗

**錯誤**: `extension "uuid-ossp" does not exist`

**解決**:
```sql
-- 在 SQL Editor 中先執行
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 問題 2: Storage Upload 失敗

**錯誤**: `new row violates row-level security policy`

**檢查**:
1. 確認 Storage policies 已正確設定
2. 確認使用者已登入（有 auth.uid()）
3. 確認檔案路徑包含 user_id

### 問題 3: RLS 阻擋查詢

**錯誤**: `permission denied for table`

**解決**:
- 確認用戶已通過身份驗證
- 確認 RLS policies 正確設定
- 在開發階段可以暫時使用 service_role key（僅後端）

### 問題 4: 無法連線到 Supabase

**檢查**:
1. Project URL 是否正確
2. API Key 是否正確
3. 網路連線是否正常
4. Supabase 服務狀態: https://status.supabase.com

---

## 📚 相關資源

- [Supabase 官方文件](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase-community/supabase-swift)
- [Row Level Security 教學](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage 文件](https://supabase.com/docs/guides/storage)
- [Apple Sign In 設定](https://supabase.com/docs/guides/auth/social-login/auth-apple)

---

## 🆘 需要幫助？

如有任何問題，請參考：
- Supabase Discord: https://discord.supabase.com
- GitHub Issues: https://github.com/supabase/supabase/issues
- 或詢問專案開發者

---

**建立日期**: 2026-01-10
**版本**: 1.0
**專案**: Re:Meet
