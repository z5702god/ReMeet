# ReMeet AI Chat Workflow - 節點說明

## 工作流程圖

```
[Webhook] → [Extract Input] → [OpenAI Intent] → [Parse Intent] → [Supabase Query] → [Prepare Data] → [OpenAI Response] → [Build Response] → [Respond]
```

---

## 各節點功能說明

### 1. Webhook - Chat API
**類型**: Webhook Trigger
**功能**: 接收 iOS App 的 HTTP POST 請求

**輸入格式**:
```json
{
  "user_id": "用戶的 UUID",
  "message": "用戶的自然語言查詢"
}
```

**端點**: `POST /webhook/api/chat`

---

### 2. Extract Input
**類型**: Set Node
**功能**: 提取並整理輸入資料

**處理內容**:
- 從 request body 提取 `user_id`、`message`
- 新增 `today` 欄位（當天日期，供 AI 計算日期範圍用）

---

### 3. OpenAI - Analyze Intent
**類型**: OpenAI (LangChain)
**模型**: gpt-4o-mini
**功能**: 分析用戶意圖，提取搜尋條件

**AI 會判斷**:
- **Intent 類型**:
  - `search_contact` - 按姓名搜尋
  - `list_recent` - 列出最近聯絡人
  - `search_by_event` - 按活動搜尋
  - `search_by_company` - 按公司搜尋
  - `search_by_location` - 按地點搜尋
  - `search_by_date` - 按日期範圍搜尋
  - `need_followup` - 需要追蹤的聯絡人
  - `general_question` - 一般問題

- **Search Params**:
  - `name` - 姓名關鍵字
  - `company` - 公司名
  - `location` - 地點
  - `event_name` - 活動名稱
  - `date_start` / `date_end` - 日期範圍

- **User Language**: `zh` (中文) 或 `en` (英文)

---

### 4. Parse Intent
**類型**: Code Node (JavaScript)
**功能**: 解析 OpenAI 回應的 JSON 格式

**處理內容**:
- 清理 OpenAI 回應（移除 markdown code blocks）
- 解析 JSON 為結構化資料
- 合併原始輸入資料（user_id, message）
- 錯誤處理：如果解析失敗，使用預設值

---

### 5. Supabase - Query Contacts
**類型**: Postgres Node
**功能**: 根據意圖查詢 Supabase 資料庫

**查詢資料表**:
- `contacts` - 聯絡人基本資料
- `companies` - 公司資料
- `meeting_contexts` - 見面情境資料

**動態條件**:
- 根據 `search_params` 動態加入 WHERE 條件
- 支援 ILIKE 模糊搜尋
- 按見面日期或建立日期排序
- 限制最多 20 筆結果

---

### 6. Prepare Response Data
**類型**: Code Node (JavaScript)
**功能**: 整理查詢結果，準備給 AI 生成回應

**處理內容**:
- 去重複（同一聯絡人可能有多筆 meeting context）
- 合併每位聯絡人的所有見面紀錄
- 統計聯絡人數量
- 整理成 AI 容易理解的格式

---

### 7. OpenAI - Generate Response
**類型**: OpenAI (LangChain)
**模型**: gpt-4o-mini
**功能**: 根據查詢結果生成自然語言回應

**AI 回應規則**:
- 簡潔友善，1-3 句話
- 根據用戶語言（中/英文）回覆
- 摘要聯絡人資訊，不逐一列出
- 沒找到結果時提供建議

---

### 8. Build API Response
**類型**: Code Node (JavaScript)
**功能**: 組裝最終 API 回應格式

**輸出格式**:
```json
{
  "success": true,
  "response_text": "AI 生成的自然語言回應",
  "contacts": [
    {
      "id": "UUID",
      "full_name": "姓名",
      "title": "職稱",
      "email": "email",
      "phone": "電話",
      "company_name": "公司名",
      "is_favorite": false,
      "meeting_context": {
        "date": "見面日期",
        "location": "地點",
        "event": "活動名稱",
        "occasion_type": "場合類型",
        "relationship_type": "關係類型"
      }
    }
  ],
  "contact_count": 5,
  "intent": "search_contact",
  "suggested_actions": ["建議動作1", "建議動作2"]
}
```

---

### 9. Respond to Webhook
**類型**: Respond to Webhook Node
**功能**: 將結果回傳給 iOS App

**設定**:
- HTTP Status: 200
- Content-Type: application/json
- Body: 上一步組裝的 JSON

---

### 10. Error Response (備用)
**類型**: Respond to Webhook Node
**功能**: 錯誤發生時的回應

**輸出格式**:
```json
{
  "success": false,
  "error": "錯誤訊息",
  "response_text": "Sorry, something went wrong.",
  "contacts": [],
  "suggested_actions": ["Try again"]
}
```

---

## 測試指令

```bash
# 測試基本查詢
curl -X POST https://lukelu.zeabur.app/webhook/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"YOUR_USER_UUID","message":"我最近認識了誰？"}'

# 測試按公司搜尋
curl -X POST https://lukelu.zeabur.app/webhook/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"YOUR_USER_UUID","message":"Find contacts from Google"}'

# 測試按地點搜尋
curl -X POST https://lukelu.zeabur.app/webhook/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"YOUR_USER_UUID","message":"上個月在台北認識的人"}'
```

---

## 注意事項

1. **Credentials 設定**:
   - OpenAI API Key 需在兩個 OpenAI 節點都設定
   - Postgres credential 需連接到 Supabase（使用 Transaction Pooler + Ignore SSL）

2. **Always Output Data**:
   - Supabase 節點需開啟此選項，確保沒有查詢結果時 workflow 也能繼續

3. **RLS (Row Level Security)**:
   - 使用 Transaction Pooler 連接，需確保 Supabase 的 RLS 政策允許查詢
