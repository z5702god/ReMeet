-- =====================================================
-- Storage Policies for business-cards bucket
-- =====================================================
-- 在 Supabase SQL Editor 中執行這些 SQL

-- =====================================================
-- Policy 1: 用戶可以上傳自己的名片
-- =====================================================

CREATE POLICY "Users can upload own business cards"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- Policy 2: 用戶可以查看自己的名片
-- =====================================================

CREATE POLICY "Users can view own business cards"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- Policy 3: 用戶可以更新自己的名片
-- =====================================================

CREATE POLICY "Users can update own business cards"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- Policy 4: 用戶可以刪除自己的名片
-- =====================================================

CREATE POLICY "Users can delete own business cards"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-cards'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- =====================================================
-- 說明
-- =====================================================
-- 這些 policies 確保：
-- 1. 只有已登入的用戶可以操作
-- 2. 用戶只能存取自己資料夾內的檔案
-- 3. 檔案路徑格式必須是: {user_id}/{filename}
--
-- 範例路徑：
-- business-cards/a1b2c3d4-e5f6-7890-abcd-ef1234567890/card_001.jpg
--                └─────────── user_id ──────────────┘
