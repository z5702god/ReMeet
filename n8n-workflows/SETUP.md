# ReMeet n8n Workflow 設定指南

## 你的環境資訊

- **n8n URL**: https://lukelu.zeabur.app
- **Webhook Endpoint**: `https://lukelu.zeabur.app/webhook/api/chat`

---

## 步驟 1: 匯入 Workflow

1. 打開 https://lukelu.zeabur.app
2. 登入 n8n
3. 點擊左側 **Workflows**
4. 點擊右上角 **⋮** → **Import from File**
5. 選擇 `remeet-ai-chat.json` 檔案
6. 點擊 **Import**

---

## 步驟 2: 設定 OpenAI Credential

1. 在 workflow 中點擊 **OpenAI - Analyze Intent** 節點
2. 點擊 **Credential to connect with** 旁的下拉選單
3. 選擇 **Create New Credential**
4. 填入：
   - **Credential Name**: `OpenAI API`
   - **API Key**: 你的 OpenAI API Key
5. 點擊 **Save**
6. 同樣的 credential 會自動套用到 **OpenAI - Generate Response** 節點

---

## 步驟 3: 設定 Supabase (Postgres) Credential

1. 點擊 **Supabase - Query Contacts** 節點
2. 點擊 **Credential to connect with** 旁的下拉選單
3. 選擇 **Create New Credential** → **Postgres**
4. 填入你的 Supabase 資料庫資訊：

   從 Supabase Dashboard → Project Settings → Database 取得：

   | 欄位 | 值 |
   |------|-----|
   | Host | `db.xxxxxxxxxx.supabase.co` |
   | Port | `5432` |
   | Database | `postgres` |
   | User | `postgres` |
   | Password | 你的資料庫密碼 |
   | SSL | `require` (或 `Allow`) |

5. 點擊 **Test Connection** 確認連線成功
6. 點擊 **Save**

---

## 步驟 4: 啟用 Workflow

1. 點擊右上角 **Save**
2. 點擊 **Inactive** 開關，切換為 **Active**
3. 現在 webhook 已經可以接收請求了！

---

## 步驟 5: 測試 Workflow

用 curl 測試：

```bash
curl -X POST https://lukelu.zeabur.app/webhook/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "YOUR_USER_UUID_HERE",
    "message": "我最近認識了誰？"
  }'
```

預期回應：
```json
{
  "success": true,
  "response_text": "你最近認識了 X 位聯絡人...",
  "contacts": [...],
  "contact_count": 5,
  "suggested_actions": [...]
}
```

---

## 常見問題

### Q: Webhook 回傳 404
A: 確認 workflow 已經 **Activate**

### Q: Postgres 連線失敗
A:
1. 確認 Supabase 的 Database 密碼正確
2. 在 Supabase Dashboard → Database → Connection Pooling 確認有開啟
3. 試試用 `Allow` 而不是 `require` 作為 SSL 選項

### Q: OpenAI 錯誤
A: 確認 API Key 有效且有足夠額度

---

## iOS App 設定

在設定完 n8n 後，需要在 iOS app 加入這個 webhook URL：

```
https://lukelu.zeabur.app/webhook/api/chat
```

詳見 iOS 整合步驟。
